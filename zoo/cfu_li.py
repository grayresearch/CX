## cfu_li.py: CFU-LI test bench support

'''
Copyright (C) 2019-2022, Gray Research LLC.

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

class Status(IntEnum):
    CFU_OK          = 0
    CFU_ERROR_CFU   = 1
    CFU_ERROR_STATE = 2
    CFU_ERROR_OFF   = 3
    CFU_ERROR_FUNC  = 4
    CFU_ERROR_OP    = 5
    CFU_ERROR_CUSTOM= 6

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

# return a dictionary of the dut's request payload signals at some CFU-LI level
def req(dut, level):
    req = { "cfu":dut.req_cfu, "func":dut.req_func, "data0":dut.req_data0, "data1":dut.req_data1 }
    if level > 0:
        req["state"] = dut.req_state
    if level == 4:
        req["id"] = dut.req_id
    return req

# return a dictionary of the dut's response payload signals at some CFU-LI level
def resp(dut, level):
    resp = { "status":dut.resp_status, "data":dut.resp_data }
    if level == 4:
        resp["id"] = dut.resp_id
    return resp
