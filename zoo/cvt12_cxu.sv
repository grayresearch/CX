// cvt12_cxu.sv: CXU-L1 to CXU-L2 feature level adapter CXU
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
// "A CXU feature level adapter is an intermediary CXU that receives requests and
// sends responses at one CXU-LI feature level and adapts them for and forwards them
// to a subordinate CXU at a lower CXU-LI feature level."
//
// "A Cvt12 adapter CXU implements CXU-L2, including its configuration
// parameters (§3.7.1), plus CXU_LATENCY (§ 3.6.1), adapting L2 requests
// to and responses from a subordinate fixed latency L1 CXU."
// 
// "The CXU_FIFO_SIZE parameter configures the capacity of a response FIFO
// that buffers responses while the requester negates resp_ready.
// This defaults to CXU_LATENCY (but at least 1)."
//
// "When CXU_LATENCY=0, the subordinate CXU response must be registered and
// therefore the adapter’s response latency is at least one cycle."

`include "cxu.svh"

/* verilator lint_off DECLFILENAME */

// cvt12_cxu: CXU-L1 to CXU-L2 feature level adapter CXU
module cvt12_cxu
    import common_pkg::*, cxu_pkg::*;
#(
    `CXU_L1_PARAMS(/*N_CXUS*/1, /*N_STATES*/1, /*LAT*/0, /*RESET*/0, /*FUNC_ID_W*/10, /*DATA_W*/32),
    parameter int CXU_INSN_W = 0,       // CXU-L2
    parameter int CXU_FIFO_SIZE = max(1,2**$clog2(CXU_LATENCY))
) (
    `CXU_CLK_L2_PORTS(input, output, req, resp),
    `CXU_L1_PORTS(output, input, t_req, t_resp)
);
    initial ignore(
        `CHECK_CXU_L2_PARAMS
    &&  `CHECK_CXU_L1_PARAMS
    &&  check_param_pos2exp("CXU_FIFO_SIZE", CXU_FIFO_SIZE)
    &&  check_param_expr("CXU_FIFO_SIZE", CXU_FIFO_SIZE, CXU_FIFO_SIZE >= CXU_LATENCY,
                         "CXU_FIFO_SIZE >= CXU_LATENCY"));

    wire _unused_ok = &{1'b0,req_insn,1'b0};
`ifdef CVT12_CXU_VCD
    initial begin $dumpfile("cvt12_cxu.vcd"); $dumpvars(0, cvt12_cxu); end
`endif

    // suspend new initiator requests (negate req_ready) when pending count reaches CXU_FIFO_SIZE
    typedef `CNT(CXU_FIFO_SIZE+1) count_t;
    count_t count;                      // count of pending requests
    logic req_hs;                       // initiator request handshake
    logic resp_hs;                      // initiator response handshake
    always_comb begin
        req_ready = count != count_t'(CXU_FIFO_SIZE);
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
        t_req_cxu   = req_cxu;
        t_req_func  = req_func;
        t_req_state = req_state;
        t_req_data0 = req_data0;
        t_req_data1 = req_data1;
    end

    // queue as many as CXU_FIFO_SIZE responses
    queue #(.W(CXU_STATUS_W+CXU_DATA_W), .N(CXU_FIFO_SIZE))
    q(.clk, .rst, .clk_en, .i_valid(t_resp_valid), .i_ready(), .i({t_resp_status,t_resp_data}),
      .o_valid(resp_valid), .o_ready(resp_ready), .o({resp_status,resp_data}));
endmodule
