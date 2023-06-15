## bnn_l1_cfu_test.py: bnn_l1_cfu (CFU-L1) testbench

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
import random
from tb import TB

# testbench
@cocotb.test()
async def bnn_cfu_tb(dut):
    tb = TB(dut, 1)
    await tb.start()
    await sweep(tb)
    await tb.stop()

async def sweep(tb):
    mask = (1 << tb.n_bits) - 1
    for (i,j) in cases(tb.n_bits):
        model = bin(~(i^j) & mask).count('1')
        await tb.test(0, 0, i, j, model)

# generate test cases
def cases(n_bits):
    mask = (1<<n_bits) - 1

    for i in range(1024):
        yield (i,0)
        yield (mask,i)
        yield (i,i)
        yield (i,~i & mask)

    for i in range(n_bits):
        for j in range(n_bits):
            yield(1<<i,1<<j)
            yield(1<<i,~(1<<j) & mask)

    # fibonnaci
    (i,j) = (1,1)
    for _ in range(1000):
        yield (i,j)
        (i,j) = (j,(i+j)&mask)

    # random
    for _ in range(1000):
        yield (random.randrange(1<<n_bits),random.randrange(1<<n_bits))

# cocotb-test, thanks @forencich

import os
import pytest
from cocotb_test.simulator import run

@pytest.mark.parametrize("latency", [0,1])
@pytest.mark.parametrize("width", [32,64])

def test_bnn_l1(request, latency, width):
    dut = "bnn_l1_cfu"
    module = os.path.splitext(os.path.basename(__file__))[0]
    parameters = {}
    parameters['CFU_LATENCY'] = latency
    parameters['CFU_N_STATES'] = 0
    parameters['CFU_DATA_W'] = width
    sim_build = os.path.join(".", "sim_build",
        request.node.name.replace('[', '-').replace(']', ''))

    run(
        includes=["."],
        verilog_sources=["common.svh", "cfu.svh", f"{dut}.sv", "cvt01_cfu.sv", "shared.sv", "bnn_cfu.sv", "popcount_cfu.sv"],
        toplevel=dut,
        module=module,
        parameters=parameters,
        defines=['BNN_CFU_VCD'],
        extra_env={ 'CFU_N_STATES':str(0), 'CFU_LATENCY':str(latency), 'CFU_DATA_W':str(width) },
        sim_build=sim_build
    )
