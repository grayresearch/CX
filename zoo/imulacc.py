## imulacc.py: shared testcases

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

from cxu_li import *
from tb import TB

class IMulAcc(IntEnum): # extends IStateContext
    mul = 0
    mulacc = 1

# For each state context, test IStateContext standard custom functions
# {read,write}_{status,state}() and operation of state context status states
# { off, init, clean, dirty }.
async def IStateContext_tests(tb, cxu = 0):
    # test IStateContext functions, interleaving amongst the n_states' contexts
    await IStateContext_state_tests(tb, cxu, 0, tb.n_states)

    # test IStateContext functions again, not interleaved, i.e. one state at a time
    for state in range(tb.n_states):
        await IStateContext_state_tests(tb, cxu, state, state + 1)

# for each state context in [start,stop-1], test IStateContext standard custom functions
async def IStateContext_state_tests(tb, cxu, start, stop):
    for state in range(start, stop):
        await tb.test_cxu(cxu, state, IStateContext.read_status, 0, 0, csw(CS.init))

    # each state's accum should be 0
    for state in range(start, stop):
        await tb.test_cxu(cxu, state, IStateContext.read_state, 0, 0, 0)

    # dirty each state context
    for state in range(start, stop):
        await tb.test_cxu(cxu, state, IMulAcc.mul, state, 1, state)

    # each state context should be dirty
    for state in range(start, stop):
        await tb.test_cxu(cxu, state, IStateContext.read_status, 0, 0, csw(CS.dirty))

    # each state's accum should be different
    for state in range(start, stop):
        await tb.test_cxu(cxu, state, IStateContext.read_state, 0, 0, state)

    # clean each state context
    for state in range(start, stop):
        await tb.test_cxu(cxu, state, IStateContext.write_status, CS.clean, 0, csw(CS.dirty))

    # check each is clean
    for state in range(start, stop):
        await tb.test_cxu(cxu, state, IStateContext.read_status, 0, 0, csw(CS.clean))

    # but accums unchanged, not reinitialized
    for state in range(start, stop):
        await tb.test_cxu(cxu, state, IStateContext.read_state, 0, 0, state)

    # write different accum to each state context
    for state in range(start, stop):
        await tb.test_cxu(cxu, state, IStateContext.write_state, state*2, 0, state*2)

    # each state context should be dirty
    for state in range(start, stop):
        await tb.test_cxu(cxu, state, IStateContext.read_status, 0, 0, csw(CS.dirty))

    # further change each accum
    for state in range(start, stop):
        await tb.test_cxu(cxu, state, IMulAcc.mulacc, state, 1, state*3)

    # init each state context
    for state in range(start, stop):
        await tb.test_cxu(cxu, state, IStateContext.write_status, CS.init, 0, csw(CS.dirty))

    # each state's accum should be 0
    for state in range(start, stop):
        await tb.test_cxu(cxu, state, IStateContext.read_state, 0, 0, 0)

    # dirty each state context
    for state in range(start, stop):
        await tb.test_cxu(cxu, state, IStateContext.write_status, CS.dirty, 0, csw(CS.init))

    # each state's accum should be 0
    for state in range(start, stop):
        await tb.test_cxu(cxu, state, IStateContext.read_state, 0, 0, 0)

    # check another way
    for state in range(start, stop):
        await tb.test_cxu(cxu, state, IMulAcc.mulacc, 0, 0, 0)

    # turn off each state
    for state in range(start, stop):
        await tb.test_cxu(cxu, state, IStateContext.write_status, CS.off, 0, csw(CS.dirty))

    # turn on each state, to init state
    for state in range(start, stop):
        await tb.test_cxu(cxu, state, IStateContext.write_status, CS.init, 0, csw(CS.off))

# IStateContext's context status word, from context status indicator cs
def csw(cs):
    return (1<<2) | cs   # (IMulAcc:) always 1 word of state, no custom error

# test IMulAcc custom functions .mul() and .mulacc(), interleaved across random state contexts
async def IMulAcc_tests(tb, cxu = 0):
    mask = (1 << tb.n_bits) - 1
    model = [0] * tb.n_states
    for (zero,state,a,b) in cases(tb.n_states, tb.n_bits):
        model[state] = ((a*b) + (0 if zero else model[state])) & mask
        await tb.test_cxu(cxu, state, IMulAcc.mul if zero else IMulAcc.mulacc, a, b, model[state])

# generate test cases; yields (zero,a,b)
def cases(n_states, n_bits):
    # mul-acc all the subcases, no reset
    for (a,b) in subcases(n_bits):
        state = random.randrange(n_states)
        yield (0,state,a,b)

    # mul-acc all the subcases again, with some random acc resets
    for state in range(n_states):
        yield (1,state,0,0)                 # reset state
    for (a,b) in subcases(n_bits):
        zero = random.randrange(10) == 0
        state = random.randrange(n_states)
        yield (zero,state,a,b)

# generate subcases; yields (a,b)
def subcases(n_bits):
    mask = (1<<n_bits) - 1

    for i in range(256):
        yield (i,0)
        yield (mask,i)
        yield (i,i)
        yield (i,~i & mask)

    for i in range(n_bits):
        for j in range(0,n_bits,3):
            yield (1<<i,1<<j)
            yield (1<<i,~(1<<j)&mask)
            yield (~(1<<i)&mask, 1<<j)
            yield (~(1<<i)&mask, ~(1<<j)&mask)

    # fibonacci
    (i,j) = (1,1)
    for _ in range(1000):
        yield (i,j)
        (i,j) = (j,(i+j)&mask)

    # random
    for _ in range(1000):
        yield (random.randrange(1<<n_bits),random.randrange(1<<n_bits))
