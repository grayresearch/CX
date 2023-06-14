## dotprod_cfu_l1_test.py: dotprod_cfu_l1 (stateful serializable L1 CFU) testbench

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

from enum import IntEnum
import random
import math

from cfu_li import *
from tb import TB

class IDotProd(IntEnum): # extends IDotProd
    dotprod = 0
    dotprodacc = 1

class DotProdTB(TB):
    def __init__(self, dut, level):
        super().__init__(dut, level)
        self.elem_w = int(os.environ.get("ELEM_W"))

# testbench
@cocotb.test()
async def dotprod_cfu_tb(dut):
    tb = DotProdTB(dut, 1)
    await tb.start()
    await IStateContext_tests(tb)
    await IDotProd_tests(tb)
    await tb.idle()

# For each state context, test IDotProd standard custom functions
# {read,write}_{status,state}() and operation of state context status states
# { off, init, clean, dirty }.
async def IStateContext_tests(tb):
    # test IStateContext functions, interleaving amongst the n_states' contexts
    await IStateContext_state_tests(tb, 0, tb.n_states)

    # test IStateContext functions again, not interleaved, i.e. one state at a time
    for state in range(tb.n_states):
        await IStateContext_state_tests(tb, state, state + 1)

# for each state context in [start,stop-1], test IDotProd standard custom functions
async def IStateContext_state_tests(tb, start, stop):
    for state in range(start, stop):
        await tb.test(state, IStateContext.read_status, 0, 0, csw(CS.init))

    # each state's accum should be 0
    for state in range(start, stop):
        await tb.test(state, IStateContext.read_state, 0, 0, 0)

    # dirty each state context
    for state in range(start, stop):
        await tb.test(state, IDotProd.dotprod, state, 1, state)

    # each state context should be dirty
    for state in range(start, stop):
        await tb.test(state, IStateContext.read_status, 0, 0, csw(CS.dirty))

    # each state's accum should be different
    for state in range(start, stop):
        await tb.test(state, IStateContext.read_state, 0, 0, state)

    # clean each state context
    for state in range(start, stop):
        await tb.test(state, IStateContext.write_status, CS.clean, 0, csw(CS.dirty))

    # check each is clean
    for state in range(start, stop):
        await tb.test(state, IStateContext.read_status, 0, 0, csw(CS.clean))

    # but accums unchanged, not reinitialized
    for state in range(start, stop):
        await tb.test(state, IStateContext.read_state, 0, 0, state)

    # write different accum to each state context
    for state in range(start, stop):
        await tb.test(state, IStateContext.write_state, state*2, 0, state*2)

    # each state context should be dirty
    for state in range(start, stop):
        await tb.test(state, IStateContext.read_status, 0, 0, csw(CS.dirty))

    # further change each accum
    for state in range(start, stop):
        await tb.test(state, IDotProd.dotprodacc, state, 1, state*3)

    # init each state context
    for state in range(start, stop):
        await tb.test(state, IStateContext.write_status, CS.init, 0, csw(CS.dirty))

    # each state's accum should be 0
    for state in range(start, stop):
        await tb.test(state, IStateContext.read_state, 0, 0, 0)

    # dirty each state context
    for state in range(start, stop):
        await tb.test(state, IStateContext.write_status, CS.dirty, 0, csw(CS.init))

    # each state's accum should be 0
    for state in range(start, stop):
        await tb.test(state, IStateContext.read_state, 0, 0, 0)

    # check another way
    for state in range(start, stop):
        await tb.test(state, IDotProd.dotprodacc, 0, 0, 0)

    # turn off each state
    for state in range(start, stop):
        await tb.test(state, IStateContext.write_status, CS.off, 0, csw(CS.dirty))

    # turn on each state, to init state
    for state in range(start, stop):
        await tb.test(state, IStateContext.write_status, CS.init, 0, csw(CS.off))

# IDotProd's context status word, from context status indicator cs
def csw(cs):
    return (1<<2) | cs   # (IDotProd:) always 1 word of state, no custom error

# test IDotProd custom functions .dotprod() and .dotprodacc(), interleaved across random state contexts
async def IDotProd_tests(tb):
    mask = (1 << tb.n_bits) - 1
    elem_mask = (1 << tb.elem_w) - 1
    model = [0] * tb.n_states
    for (zero,state,a,b) in cases(tb.n_states, tb.n_bits, tb.elem_w):
        dotp = 0
        for i in range(tb.n_bits//tb.elem_w):
            dotp += ((a>>(tb.elem_w*i)) & elem_mask) * ((b>>(tb.elem_w*i)) & elem_mask)
        model[state] = (dotp + (0 if zero else model[state])) & mask
        await tb.test(state, IDotProd.dotprod if zero else IDotProd.dotprodacc, a, b, model[state])

# generate test cases; yields (zero,a,b)
def cases(n_states, n_bits, elem_w):
    # dotprod-acc all the subcases, no reset
    for (a,b) in subcases(n_bits, elem_w):
        state = random.randrange(n_states)
        yield (0,state,a,b)

    # dotprod-acc all the subcases again, with some random acc resets
    for state in range(n_states):
        yield (1,state,0,0)                 # reset state
    for (a,b) in subcases(n_bits, elem_w):
        zero = random.randrange(10) == 0
        state = random.randrange(n_states)
        yield (zero,state,a,b)


# generate subcases; yields (a,b)
def subcases(n_bits, elem_w):
    n_elems = n_bits // elem_w
    mask = (1<<n_bits) - 1
    elem_mask = (1<<elem_w) - 1

    def e(x,i):
        return ((x&elem_mask) << (i*elem_w)) & mask

    for i in range(n_elems):
        for x in range(min(1024,1<<elem_w)):
            yield (e(x,i),0)
            yield (mask,e(x,i))
            yield (e(x,i),e(x,i))
            yield (e(x,i),e(~x,i))

    for i in range(n_elems):
        for j in range(elem_w):
            for k in range(elem_w):
                yield (e(1<<j,i),e(1<<k,i))
                yield (e(1<<j,i),e(~(1<<k),i))
                yield (e(~(1<<j),i),e(1<<k,i))
                yield (e(~(1<<j),i),e(~(1<<j),i))

    # fibonacci
    (i,j) = (1,1)
    for _ in range(1000):
        yield (i,j)
        (i,j) = (j,(i+j)&mask)

    # random
    for _ in range(1000):
        yield (random.randrange(1<<n_bits),random.randrange(1<<n_bits))


# cocotb-test, follows Alex Forencich's helpful examples to sweep over dut module parameters

import os
import pytest
from cocotb_test.simulator import run

@pytest.mark.parametrize("latency", [0,1,2])
@pytest.mark.parametrize("states", [1,3])
@pytest.mark.parametrize("width", [32,64])
@pytest.mark.parametrize("elem_w", [4,8,16,32])

def test_dotprod(request, latency, states, width, elem_w):
    dut = "dotprod_cfu"
    module = os.path.splitext(os.path.basename(__file__))[0]
    parameters = {}
    parameters['CFU_LATENCY'] = latency
    parameters['CFU_N_STATES'] = states
    parameters['CFU_STATE_ID_W'] = (states-1).bit_length()
    parameters['CFU_DATA_W'] = width
    parameters['ELEM_W'] = elem_w
    sim_build = os.path.join(".", "sim_build",
        request.node.name.replace('[', '-').replace(']', ''))

    run(
        includes=["."],
        verilog_sources=["common.svh", "cfu.svh", f"{dut}.sv", "shared.sv"],
        toplevel=dut,
        module=module,
        parameters=parameters,
        defines=['DOTPROD_CFU_VCD'],
        extra_env={ 'CFU_N_STATES':str(states), 'CFU_LATENCY':str(latency), 'CFU_DATA_W':str(width), 'ELEM_W':str(elem_w) },
        sim_build=sim_build
    )
