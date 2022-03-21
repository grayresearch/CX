// cfu_li.svh: CFU-LI package
//
// Copyright (C) 2019-2022, Gray Research LLC.
// 
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// 
//    http://www.apache.org/licenses/LICENSE-2.0
// 
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

`ifndef CFU_SVH
`define CFU_SVH

`include "common.svh"

package cfu_pkg;

import common_pkg::*;

function bit check_cfu_l0_params(string name, int version, int id_max, int cfu_w, int func_w, int data_w);
    check_cfu_l0_params =
        check_param(name, "CFU_VERSION", version, 100)
    &&  check_param(name, "CFU_CFU_ID_MAX", id_max, 1)
    &&  check_param_range(name, "CFU_CFU_ID_W", cfu_w, 0, 16)
    &&  check_param_range(name, "CFU_FUNC_ID_W", func_w, 0, 10)
    &&  check_param_2(name, "CFU_DATA_ID_W", data_w, 32, 64);
endfunction

function bit check_cfu_l1_params(
    string name, int version, int id_max, int latency, int reset_latency, int cfu_w,
    int state_w, int func_w, int data_w
);
    check_cfu_l1_params =
        check_param(name, "CFU_VERSION", version, 100)
    &&  check_param(name, "CFU_CFU_ID_MAX", id_max, 1)
    //  check_param CFU_STATE_ID_MAX in each CFU
    &&  check_param_nonneg(name, "CFU_LATENCY", latency)
    &&  check_param_nonneg(name, "CFU_RESET_LATENCY", reset_latency)
    &&  check_param_range(name, "CFU_CFU_ID_W", cfu_w, 0, 16)
    &&  check_param_range(name, "CFU_STATE_ID_W", state_w, 0, 16)
    &&  check_param_range(name, "CFU_FUNC_ID_W", func_w, 0, 10)
    &&  check_param_2(name, "CFU_DATA_ID_W", data_w, 32, 64);
endfunction

typedef enum logic [2:0] {
    CFU_OK,                         // OK: no errors
    CFU_ERROR_CFU,                  // error: invalid CFU_ID
    CFU_ERROR_OFF,                  // error: (stateful interface) is off
    CFU_ERROR_STATE,                // error: invalid STATE_ID
    CFU_ERROR_FUNC,                 // error: invalid CF_ID
    CFU_ERROR_OP,                   // error: invalid operation or operands
    CFU_ERROR_CUSTOM                // error: (stateful interface) custom error
} cfu_status_t;                     // CFU response status

typedef enum logic [1:0] {
    CFU_OFF,                        // context off: any use is an error
    CFU_INIT,                       // context on, reset to zero
    CFU_CLEAN,                      // context hasn't changed since last context save
    CFU_DIRTY                       // context has changed
} cfu_cs_e;                         // stateful CFU "CS" context status

typedef logic [1:0] cfu_cs_t;       // mitigate iverilog shortcoming, can't cast to enum (?)

typedef struct packed {
    `V(8)       error;              // custom error status
    `V(12)      reserved;           // reserved, writes ignored, reads as zero
    `V(10)      state_size;         // state context size in words
    cfu_cs_t    cs;                 // context "CS" status
} cfu_csw_t;                        // stateful CFU interface state context status word

typedef enum logic [9:0] {
    cfid_read_status    = 1023,     // read interface state context status word
    cfid_write_status   = 1022,     // write interface state context status word
    cfid_read_state     = 1021,     // read one word of current state context
    cfid_write_state    = 1020      // write one word of current state context
} cfid_t;                           // stateful CFU standard custom function IDs

endpackage : cfu_pkg
`endif
