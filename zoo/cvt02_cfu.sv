// cvt02_cfu.sv: CFU-L0 to CFU-L2 feature level adapter CFU
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
// "A Cvt02 adapter CFU implements CFU-L2, including its configuration parameters,
// adapting L2 requests to and responses from a subordinate combinational L0 CFU.
// The adapter has a fixed latency of one cycle — a response is sent one cycle after
// a request is received."

`include "cfu.svh"

/* verilator lint_off DECLFILENAME */

// cvt02_cfu: CFU-L0 to CFU-L2 feature level adapter CFU
module cvt02_cfu
    import common_pkg::*, cfu_pkg::*;
#(
    `CFU_L2_PARAMS(/*N_CFUS*/1, /*N_STATES*/0, /*FUNC_ID_W*/0, /*INSN_W*/0, /*DATA_W*/32)
) (
    `CFU_ALL_L2_PORTS(input, output, req, resp),
    `CFU_L0_PORTS(output, input, t_req, t_resp)
);
    initial ignore(`CHECK_CFU_L2_PARAMS && check_param("CFU_N_STATES", CFU_N_STATES, 0));

    wire _unused_ok = &{1'b0,req_state,req_insn,1'b0};
`ifdef CVT02_CFU_VCD
    initial begin $dumpfile("cvt02_cfu.vcd"); $dumpvars(0, cvt02_cfu); end
`endif

    always_comb begin
        // "To avoid arbitrary CFU response queuing, yet keep signaling simple
        // and frugal, the Cvt02 adapter negates req_ready on any cycle that it
        // has a valid response waiting (asserting resp_valid) and the requester
        // negates resp_ready."
        req_ready = !(resp_valid && !resp_ready);

        // forward request to (combinational) target CFU
        t_req_valid = req_valid;
        t_req_cfu   = req_cfu;
        t_req_func  = req_func;
        t_req_data0 = req_data0;
        t_req_data1 = req_data1;
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            resp_valid  <= 0;
            resp_status <= CFU_OK;
            resp_data   <= '0;
        end else if (clk_en) begin
            if (req_valid && req_ready) begin
                // handshaken request => send response
                resp_valid  <= 1;
                resp_status <= t_resp_status;
                resp_data   <= t_resp_data;
            end else if (resp_ready) begin
                // previous response accepted sans new response
                resp_valid <= 0;
            end
        end
    end
endmodule
