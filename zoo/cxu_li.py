## cxu_li.py: CXU-LI test bench support

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

# see Draft Proposed Composable Custom Extensions Specification, ../spec/spec.pdf

from enum import IntEnum

class Level(IntEnum):
    l0_comb         = 0
    l1_pipe         = 1
    l2_stream       = 2
    l3_ooo          = 3

class Status(IntEnum):
    CXU_OK          = 0
    CXU_ERROR_CXU   = 1
    CXU_ERROR_STATE = 2
    CXU_ERROR_OFF   = 3
    CXU_ERROR_FUNC  = 4
    CXU_ERROR_OP    = 5
    CXU_ERROR_CUSTOM= 6

class CS(IntEnum):
    off             = 0
    init            = 1
    clean           = 2
    dirty           = 3

class IStateContext(IntEnum):
    write_state     = 1020
    read_state      = 1021
    write_status    = 1022
    read_status     = 1023

# return a dictionary of the dut's request payload signals at some CXU-LI level
def req(dut, level):
    req = { 'cxu':dut.req_cxu, 'func':dut.req_func, 'data0':dut.req_data0, 'data1':dut.req_data1 }
    if level > Level.l0_comb:
        req['state'] = dut.req_state
    if level == Level.l3_ooo:
        req['id'] = dut.req_id
    return req

# return a dictionary of the dut's response payload signals at some CXU-LI level
def resp(dut, level):
    resp = { 'status':dut.resp_status, 'data':dut.resp_data }
    if level == Level.l3_ooo:
        resp['id'] = dut.resp_id
    return resp
