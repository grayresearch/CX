## popcount_cxu_test.py: popcount_cxu (CXU-L0) testbench

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
from cxu_li import *
from tb import TB

# testbench
@cocotb.test()
async def popcount_cxu_tb(dut):
    tb = TB(dut, Level.l0_comb)
    await tb.start()
    await sweep(tb)
    await tb.stop()

async def sweep(tb):
    for case in cases(tb.n_bits):
        await tb.test(0, 0, case, 0, bin(case).count('1'))

# generate test cases
def cases(n_bits):
    mask = (1<<n_bits) - 1

    # first nonneg integers and complements
    for i in range(256):
        yield i
        yield ~i & mask

    # 1,2,3-bit patterns and complements
    for i in range(n_bits):
        for j in range(i, n_bits):
            for k in range(j, n_bits):
                t = (1<<i) | (1<<j) | (1<<k)
                yield t
                yield ~t & mask

    # random
    for _ in range(1000):
        yield random.randrange(1<<n_bits)

# cocotb-test, thanks @forencich

import os
import pytest
from cocotb_test.simulator import run

@pytest.mark.parametrize("width", [32, 64])
@pytest.mark.parametrize("adder_tree", [0, 1])

def test_popcount(request, width, adder_tree):
    dut = "popcount_cxu"
    module = os.path.splitext(os.path.basename(__file__))[0]
    parameters = {}
    parameters['CXU_DATA_W'] = width
    parameters['ADDER_TREE'] = adder_tree
    sim_build = os.path.join(".", "sim_build",
        request.node.name.replace('[', '-').replace(']', ''))

    run(
        includes=["."],
        verilog_sources=["common.svh", "cxu.svh", f"{dut}.sv"],
        toplevel=dut,
        module=module,
        parameters=parameters,
        defines=['POPCOUNT_CXU_VCD'],
        extra_env={ 'CXU_DATA_W':str(width) },
        sim_build=sim_build
    )
