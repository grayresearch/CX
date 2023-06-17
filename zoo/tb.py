## tb.py: CFU testbench class

'''
Copyright (C) 2019-2023, Gray Research LLC.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
'''

import cocotb
from cocotb.clock import Clock
from cocotb.handle import SimHandleBase
from cocotb.queue import Queue
from cocotb.triggers import FallingEdge, RisingEdge, Timer
import os
import random

from cfu_li import *
from monitors import Monitor

# CFU testbench for CFU -L0, -L1 (so far)
class TB:
    def __init__(self, dut, level):
        self.dut      = dut
        self.level    = level
        self.n_bits   = int(os.environ.get("CFU_DATA_W")) 
        self.latency  = int(os.environ.get("CFU_LATENCY"))  if level == Level.l1_pipe else 0
        self.n_states = int(os.environ.get("CFU_N_STATES")) if level >  Level.l0_comb else 0
        self.resp_ready_frac = 1.0

        # for combinational CFUs (CFU-L0) tests issue at 1 ns timesteps;
        # for synchronous CFUs (>L0), requests and responses are monitored on posedge(clk)
        if level >= Level.l1_pipe:
            cocotb.start_soon(Clock(dut.clk, 1, units="ns").start())
            req_ready  = dut.req_ready  if level >= Level.l2_stream else None
            resp_ready = dut.resp_ready if level >= Level.l2_stream else None
            self.req_mon  = Monitor(clk=dut.clk, valid=dut.req_valid,  ready=req_ready,  datas=req(dut, level))
            self.resp_mon = Monitor(clk=dut.clk, valid=dut.resp_valid, ready=resp_ready, datas=resp(dut, level))
            self.models = Queue[(int,int)]()
            cocotb.start_soon(self.check())


    async def start(self):
        random.seed(0) # repeatable random numbers

        # setup some default request signals
        self.dut.req_valid.value = 0
        self.dut.req_cfu.value = 0
        if self.level >= Level.l1_pipe:
            self.dut.req_state.value = 0
        self.dut.req_func.value = 0
        if self.level >= Level.l2_stream:
            self.dut.req_insn.value = 0
        self.dut.req_data0.value = 0
        self.dut.req_data1.value = 0

        if self.level > Level.l0_comb:
            # reset dut, start monitoring requests/responses
            await self.reset()
            self.req_mon.start()
            self.resp_mon.start()

            if self.level >= Level.l2_stream:
                cocotb.start_soon(self.resp_flow_control())

        self.dut.req_valid.value = 1

    async def reset(self):
        self.dut.clk_en.value = 1
        self.dut.rst.value = 1
        for _ in range(2):
            await RisingEdge(self.dut.clk)
        self.dut.rst.value = 0

    async def stop(self):
        if self.level > Level.l0_comb:
            await self.idle();

    async def idle(self):
        self.dut.req_valid.value = 0
        while not self.models.empty():
            await RisingEdge(self.dut.clk)

    # issue one test case; response should match model
    async def test(self, state, func, data0, data1, model):
        self.dut.req_func.value = func
        self.dut.req_data0.value = data0
        self.dut.req_data1.value = data1

        if self.level == Level.l0_comb:
            # check answer immediately
            await Timer(1, units="ns")
            assert (self.dut.resp_status == Status.CFU_OK and self.dut.resp_data == model), \
                "test({0:1d},{1:08x},{2:08x}) => {3:08x} != {4:08x}".format( \
                    func, data0, data1, self.dut.resp_data.integer, model)
        else:
            # monitoring captures request and response, later checked in self.check()
            self.dut.req_state.value = state
            self.models.put_nowait((0, model))

            # CFU-L2+: await req_ready (sampled on negedge clk)
            if self.level >= Level.l2_stream:
                while True:
                    await FallingEdge(self.dut.clk)
                    if self.dut.req_ready == 1:
                        break

            await RisingEdge(self.dut.clk)

    # check actual requests/responses match model responses
    async def check(self):
        while True:
            req = await self.req_mon.values.get()
            resp = await self.resp_mon.values.get()
            state = req['state'].integer if self.level > Level.l0_comb else 0
            (status,data) = await self.models.get()

            assert (resp['status'] == status and resp['data'] == data), \
                "test({0},{1:2d},{2:08x},{3:08x}) => {4:1d}:{5:08x} != {6:1d}:{6:08x}".format( \
                    state, req['func'].integer, req['data0'].integer, req['data1'].integer, \
                    resp['status'].integer, resp['data'].integer, status, data)

    # CFU-L2+: initiator performs response flow control, randomly adjusting self.dut.resp_ready,
    # per self.resp_ready_frac
    async def resp_flow_control(self):
        while True:
            self.dut.resp_ready.value = int(random.random() < self.resp_ready_frac)
            await RisingEdge(self.dut.clk)
