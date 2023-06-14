// cvt01_cfu.sv: CFU-L0 to CFU-L1 feature level adapter CFU
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
// "A CFU feature level adapter is an intermediary CFU that receives requests and
// sends responses at one CFU-LI feature level and adapts them for and forwards them
// to a subordinate CFU at a lower CFU-LI feature level."
//
// "A Cvt01 adapter CFU implements CFU-L1, including its configuration
// parameters (§3.6.1), adapting L1 requests to and responses from a
// subordinate combinational L0 CFU."
//
// "When CFU_LATENCY=0, the adapter’s request/response channels are directly
// coupled to the subordinate CFU request/response channels. Otherwise,
// these channels I/Os are registered and pipelined, with a total latency
// of CFU_LATENCY cycles."

`include "cfu.svh"

/* verilator lint_off DECLFILENAME */

// cvt01_cfu: CFU-L0 to CFU-L1 feature level adapter CFU
module cvt01_cfu
    import common_pkg::*, cfu_pkg::*;
#(
    `CFU_L1_PARAMS(/*N_CFUS*/1, /*N_STATES*/0, /*LATENCY*/0, /*RESET_LATENCY*/0, /*FUNC_ID_W*/10,
                   /*DATA_W*/32)
) (
    `CFU_CLK_L1_PORTS(input, output, req, resp),
    `CFU_L0_PORTS(output, input, t_req, t_resp)
);
    initial ignore(`CHECK_CFU_L1_PARAMS && check_param("CFU_N_STATES", CFU_N_STATES, 0));
    wire _unused_ok = &{1'b0,req_state,1'b0};
`ifdef CVT01_CFU_VCD
    initial begin $dumpfile("cvt01_cfu.vcd"); $dumpvars(0, cvt01_cfu); end
`endif

    // forward request to target combinational CFU
    always_comb begin
        t_req_valid = req_valid;
        t_req_cfu   = req_cfu;
        t_req_func  = req_func;
        t_req_data0 = req_data0;
        t_req_data1 = req_data1;
    end

    // forward response to initiator, after CFU_LATENCY cycles
    localparam int N = CFU_LATENCY;     // shift_reg #(.N(0)) => combinational pass-through
    shift_reg #(.W(1),            .N(N)) valid (.clk, .rst, .clk_en, .d(req_valid),     .q(resp_valid));
    shift_reg #(.W(CFU_STATUS_W), .N(N)) status(.clk, .rst, .clk_en, .d(t_resp_status), .q(resp_status));
    shift_reg #(.W(CFU_DATA_W),   .N(N)) data  (.clk, .rst, .clk_en, .d(t_resp_data),   .q(resp_data));
endmodule
