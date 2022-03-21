// bnn_cfu.sv: binary neural network dot prodct combinational (CFU-L0) CFU
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

// IBNN custom functions:
//  *: int bnn(int a, int b);

`include "common.svh"
`include "cfu.svh"

/* verilator lint_off DECLFILENAME */

// bnn_cfu: 32/64-bit binary neural net dot product CFU-L0 combinational CFU
module bnn_cfu
    import common_pkg::*;
    import cfu_pkg::*;
#(
    parameter int CFU_VERSION       = 100,
    parameter int CFU_CFU_ID_MAX    = 1,
    parameter int CFU_CFU_ID_W      = 0,
    parameter int CFU_FUNC_ID_W     = 0,
    parameter int CFU_DATA_W        = 32
) (
    input  logic                req_valid,
    input  `V(CFU_CFU_ID_W)     req_cfu,
    input  `V(CFU_FUNC_ID_W)    req_func,
    input  `V(CFU_DATA_W)       req_data0,
    input  `V(CFU_DATA_W)       req_data1,
    output cfu_status_t         resp_status,
    output `V(CFU_DATA_W)       resp_data
);
    initial ignore(check_cfu_l0_params("bnn_cfu", CFU_VERSION, CFU_CFU_ID_MAX, CFU_CFU_ID_W,
        CFU_FUNC_ID_W, CFU_DATA_W));
    wire _unused_ok = &{1'b0,req_func,req_cfu,req_valid,1'b0};
`ifdef BNN_CFU_VCD
    initial begin $dumpfile("bnn_cfu.vcd"); $dumpvars(0, bnn_cfu); end
`endif

    wire `V(CFU_DATA_W) xnor_ = req_data0 ~^ req_data1;

    popcount_cfu #(.CFU_VERSION(CFU_VERSION),
        .CFU_CFU_ID_MAX(CFU_CFU_ID_MAX), .CFU_CFU_ID_W(CFU_CFU_ID_W),
        .CFU_FUNC_ID_W(CFU_FUNC_ID_W), .CFU_DATA_W(CFU_DATA_W))
    count(.req_valid, .req_cfu, .req_func, .req_data0(xnor_),
        .req_data1('0), .resp_status, .resp_data);
endmodule
