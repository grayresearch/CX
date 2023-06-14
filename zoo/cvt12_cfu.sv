// cvt12_cfu.sv: CFU-L1 to CFU-L2 feature level adapter CFU
//
// Copyright (C) 2019-2123, Gray Research LLC.
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

// [Draft Proposed RISC-V Composable Custom Extensions Specification %3.9.3:]
// "A CFU feature level adapter is an intermediary CFU that receives requests and
// sends responses at one CFU-LI feature level and adapts them for and forwards them
// to a subordinate CFU at a lower CFU-LI feature level."
//
// "A Cvt12 adapter CFU implements CFU-L2, including its configuration
// parameters (§3.7.1), plus CFU_LATENCY (§ 3.6.1), adapting L2 requests
// to and responses from a subordinate fixed latency L1 CFU."
// 
// "The CFU_QUEUE_SIZE parameter configures the capacity of a response queue
// that buffers responses while the requester negates resp_ready.
// This defaults to CFU_LATENCY (but at least 1)."
//
// "When CFU_LATENCY=0, the subordinate CFU response must be registered and
// therefore the adapter’s response latency is at least one cycle."

`include "cfu.svh"

/* verilator lint_off DECLFILENAME */

// cvt12_cfu: CFU-L1 to CFU-L2 feature level adapter CFU
module cvt12_cfu
    import common_pkg::*, cfu_pkg::*;
#(
    `CFU_L1_PARAMS(/*N_CFUS*/1, /*N_STATES*/1, /*LAT*/0, /*RESET*/0, /*FUNC_ID_W*/10, /*DATA_W*/32),
    parameter int CFU_INSN_W = 0    // CFU-L2
    parameter int CFU_QUEUE_SIZE = max(1,CFU_LATENCY)
) (
    `CFU_ALL_L2_PORTS(input, output, req, resp),
    `CFU_L1_PORTS(output, input, t_req, t_resp)
);
    initial ignore(
        `CHECK_CFU_L2_PARAMS
    &&  `CHECK_CFU_L1_PARAMS
    &&  check_param_pos("CFU_QUEUE_SIZE", CFU_QUEUE_SIZE));

    wire _unused_ok = &{1'b0,req_insn,1'b0};
`ifdef CVT12_CFU_VCD
    initial begin $dumpfile("cvt12_cfu.vcd"); $dumpvars(0, cvt12_cfu); end
`endif

    // suspend new initiator requests (negate req_ready) when pending count reaches CFU_QUEUE_SIZE
    `CNT(CFU_QUEUE_SIZE+1) count;       // count of pending requests
    logic req_hs;                       // initiator request handshake
    logic resp_hs;                      // initiator response handshake
    always_comb begin
        req_ready = count != CFU_QUEUE_SIZE;
        req_hs  = req_valid  && req_ready;
        resp_hs = resp_valid && resp_ready;
    end
    always_ff @(posedge clk) begin
        if (rst)
            count <= '0;
        else if (clk_en && req_hs != resp_hs)
            count <= req_hs ? (count + 1'b1) : (count - 1'b1);
    end

    // forward initiator requests to target
    always_comb begin
        t_req_valid = req_hs;
        t_req_cfu   = req_cfu;
        t_req_func  = req_func;
        t_req_state = req_state;
        t_req_data0 = req_data0;
        t_req_data1 = req_data1;
    end

    // queue as many as CFU_QUEUE_SIZE responses
    queue #(.W(CFU_STATUS_W+CFU_DATA_W), .N(CFU_QUEUE_SIZE))
    q(.clk, .rst, .clk_en, .i_v(t_resp_valid), .i_rdy(), .i({t_resp_status,t_resp_data}),
      .o_v(resp_valid), .o_rdy(resp_ready), .o({resp_status,resp_ready}));
endmodule
