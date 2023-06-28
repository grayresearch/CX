// mux3_macs_cfu.sv: composition of two stateful mulacc CFU-L2 streaming CFUs
// using a 3-1 mux3_cfu
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

// mux3_macs_cfu composes a mux3_cfu, 3 {cvt12_cfu, mulacc_cfu }
module mux3_macs_cfu
    import common_pkg::*, cfu_pkg::*;
#(
    `CFU_L2_PARAMS(/*N_CFUS*/3, /*N_STATES*/1, /*FUNC_ID_W*/$bits(cfid_t), /*INSN_W*/0, /*DATA_W*/32),
    parameter int MAC0_LATENCY = 1,
    parameter int MAC1_LATENCY = 3,
    parameter int MAC2_LATENCY = 5
) (
    `CFU_CLK_L2_PORTS(input, output, req, resp)
);
    initial ignore(`CHECK_CFU_L2_PARAMS);
`ifdef MUX3_MACS_CFU_VCD
    initial begin $dumpfile("mux3_macs_cfu.vcd"); $dumpvars(0, mux3_macs_cfu); end
`endif

    `CFU_L2_NETS(t0_req, t0_resp);
    `CFU_L2_NETS(t1_req, t1_resp);
    `CFU_L2_NETS(t2_req, t2_resp);

    mux3_cfu #(`CFU_L2_PARAMS_MAP)
        mux(`CFU_CLK_L2_PORT_MAP(req,req, resp,resp),
            `CFU_L2_PORT_MAP(t0_req,t0_req, t0_resp,t0_resp),
            `CFU_L2_PORT_MAP(t1_req,t1_req, t1_resp,t1_resp),
            `CFU_L2_PORT_MAP(t2_req,t2_req, t2_resp,t2_resp));

    mulacc_l2_cfu #(`CFU_L2_PARAMS_MAP, .CFU_LATENCY(MAC0_LATENCY))
        mac0(`CFU_CLK_L2_PORT_MAP(req,t0_req, resp,t0_resp));

    mulacc_l2_cfu #(`CFU_L2_PARAMS_MAP, .CFU_LATENCY(MAC1_LATENCY))
        mac1(`CFU_CLK_L2_PORT_MAP(req,t1_req, resp,t1_resp));

    mulacc_l2_cfu #(`CFU_L2_PARAMS_MAP, .CFU_LATENCY(MAC1_LATENCY))
        mac2(`CFU_CLK_L2_PORT_MAP(req,t2_req, resp,t2_resp));
endmodule
