// mux2_macs_cxu.sv: composition of two stateful mulacc CXU-L2 streaming CXUs
// using a 2-1 mux2_cxu
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

// mux2_macs_cxu composes a mux2_cxu, cvt12_cxu, mulacc_cxu, cvt12_cxu, mulacc_cxu.
module mux2_macs_cxu
    import common_pkg::*, cxu_pkg::*;
#(
    `CXU_L2_PARAMS(/*N_CXUS*/2, /*N_STATES*/1, /*FUNC_ID_W*/$bits(cfid_t), /*INSN_W*/0, /*DATA_W*/32),
    parameter int MAC0_LATENCY = 1,
    parameter int MAC1_LATENCY = 5
) (
    `CXU_CLK_L2_PORTS(input, output, req, resp)
);
    initial ignore(`CHECK_CXU_L2_PARAMS);
`ifdef MUX2_MACS_CXU_VCD
    initial begin $dumpfile("mux2_macs_cxu.vcd"); $dumpvars(0, mux2_macs_cxu); end
`endif

    `CXU_L2_NETS(t0_req, t0_resp);
    `CXU_L2_NETS(t1_req, t1_resp);

    mux2_cxu #(`CXU_L2_PARAMS_MAP)
        mux(`CXU_CLK_L2_PORT_MAP(req,req, resp,resp),
            `CXU_L2_PORT_MAP(t0_req,t0_req, t0_resp,t0_resp),
            `CXU_L2_PORT_MAP(t1_req,t1_req, t1_resp,t1_resp));

    mulacc_l2_cxu #(`CXU_L2_PARAMS_MAP, .CXU_LATENCY(MAC0_LATENCY))
        mac0(`CXU_CLK_L2_PORT_MAP(req,t0_req, resp,t0_resp));

    mulacc_l2_cxu #(`CXU_L2_PARAMS_MAP, .CXU_LATENCY(MAC1_LATENCY))
        mac1(`CXU_CLK_L2_PORT_MAP(req,t1_req, resp,t1_resp));
endmodule
