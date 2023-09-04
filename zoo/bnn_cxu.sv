// bnn_cxu.sv: binary neural network dot product combinational (CXU-L0) CXU
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

`include "cxu.svh"

/* verilator lint_off DECLFILENAME */

// bnn_cxu: 32/64-bit binary neural net dot product CXU-L0 combinational CXU
module bnn_cxu
    import common_pkg::*, cxu_pkg::*;
#(
    `CXU_L0_PARAMS(/*N_CXUS*/1, /*FUNC_ID_W*/0, /*DATA_W*/32)
) (
    `CXU_L0_PORTS(input, output, req, resp)
);
    initial ignore(`CHECK_CXU_L0_PARAMS);
    wire _unused_ok = &{1'b0,req_func,req_cxu,req_valid,1'b0};
`ifdef BNN_CXU_VCD
    initial begin $dumpfile("bnn_cxu.vcd"); $dumpvars(0, bnn_cxu); end
`endif

    wire `V(CXU_DATA_W) xnor_ = req_data0 ~^ req_data1;

    popcount_cxu #(.CXU_LI_VERSION(CXU_LI_VERSION), .CXU_N_CXUS(CXU_N_CXUS), .CXU_CXU_ID_W(CXU_CXU_ID_W),
        .CXU_FUNC_ID_W(CXU_FUNC_ID_W), .CXU_DATA_W(CXU_DATA_W))
    count(.req_valid, .req_cxu, .req_func, .req_data0(xnor_),
        .req_data1({CXU_DATA_W{1'b0}}), .resp_status, .resp_data);
endmodule
