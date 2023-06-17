// bnn_cfu.sv: binary neural network dot product combinational (CFU-L0) CFU
//
// Copyright (C) 2019-2023, Gray Research LLC.
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

`include "cfu.svh"

/* verilator lint_off DECLFILENAME */

// bnn_cfu: 32/64-bit binary neural net dot product CFU-L0 combinational CFU
module bnn_cfu
    import common_pkg::*, cfu_pkg::*;
#(
    `CFU_L0_PARAMS(/*N_CFUS*/1, /*FUNC_ID_W*/0, /*DATA_W*/32)
) (
    `CFU_L0_PORTS(input, output, req, resp)
);
    initial ignore(`CHECK_CFU_L0_PARAMS);
    wire _unused_ok = &{1'b0,req_func,req_cfu,req_valid,1'b0};
`ifdef BNN_CFU_VCD
    initial begin $dumpfile("bnn_cfu.vcd"); $dumpvars(0, bnn_cfu); end
`endif

    wire `V(CFU_DATA_W) xnor_ = req_data0 ~^ req_data1;

    popcount_cfu #(.CFU_LI_VERSION(CFU_LI_VERSION), .CFU_N_CFUS(CFU_N_CFUS), .CFU_CFU_ID_W(CFU_CFU_ID_W),
        .CFU_FUNC_ID_W(CFU_FUNC_ID_W), .CFU_DATA_W(CFU_DATA_W))
    count(.req_valid, .req_cfu, .req_func, .req_data0(xnor_),
        .req_data1({CFU_DATA_W{1'b0}}), .resp_status, .resp_data);
endmodule
