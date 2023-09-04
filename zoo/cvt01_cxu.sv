// cvt01_cxu.sv: CXU-L0 to CXU-L1 feature level adapter CXU
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

// [Draft Proposed RISC-V Composable Custom Extensions Specification %3.9.2:]
// "A CXU feature level adapter is an intermediary CXU that receives requests and
// sends responses at one CXU-LI feature level and adapts them for and forwards them
// to a subordinate CXU at a lower CXU-LI feature level."
//
// "A Cvt01 adapter CXU implements CXU-L1, including its configuration
// parameters (§3.6.1), adapting L1 requests to and responses from a
// subordinate combinational L0 CXU."
//
// "When CXU_LATENCY=0, the adapter’s request/response channels are directly
// coupled to the subordinate CXU request/response channels. Otherwise,
// these channels I/Os are registered and pipelined, with a total latency
// of CXU_LATENCY cycles."

`include "cxu.svh"

/* verilator lint_off DECLFILENAME */

// cvt01_cxu: CXU-L0 to CXU-L1 feature level adapter CXU
module cvt01_cxu
    import common_pkg::*, cxu_pkg::*;
#(
    `CXU_L1_PARAMS(/*N_CXUS*/1, /*N_STATES*/0, /*LATENCY*/0, /*RESET_LATENCY*/0, /*FUNC_ID_W*/10,
                   /*DATA_W*/32)
) (
    `CXU_CLK_L1_PORTS(input, output, req, resp),
    `CXU_L0_PORTS(output, input, t_req, t_resp)
);
    initial ignore(`CHECK_CXU_L1_PARAMS && check_param("CXU_N_STATES", CXU_N_STATES, 0));
    wire _unused_ok = &{1'b0,req_state,1'b0};
`ifdef CVT01_CXU_VCD
    initial begin $dumpfile("cvt01_cxu.vcd"); $dumpvars(0, cvt01_cxu); end
`endif

    // forward request to target combinational CXU
    always_comb begin
        t_req_valid = req_valid;
        t_req_cxu   = req_cxu;
        t_req_func  = req_func;
        t_req_data0 = req_data0;
        t_req_data1 = req_data1;
    end

    // forward response to initiator, after CXU_LATENCY cycles
    localparam int N = CXU_LATENCY;     // shift_reg #(.N(0)) => combinational pass-through
    shift_reg #(.W(1),            .N(N)) valid (.clk, .rst, .clk_en, .d(req_valid),     .q(resp_valid));
    shift_reg #(.W(CXU_STATUS_W), .N(N)) status(.clk, .rst, .clk_en, .d(t_resp_status), .q(resp_status));
    shift_reg #(.W(CXU_DATA_W),   .N(N)) data  (.clk, .rst, .clk_en, .d(t_resp_data),   .q(resp_data));
endmodule
