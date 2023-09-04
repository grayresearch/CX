// mulacc_l2_cfu.sv: 32/64-bit multiply-accumulate stateful CFU-L2 streaming CFU
// via composing a cvt12_cfu with a CFU-L1 mulacc_cfu
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

// mulacc_l2_cfu: 32/64-bit multiply-accumulate stateful CFU-L2 streaming CFU,
// via composing a cvt12_cfu with a CFU-L1 mulacc_cfu.
module mulacc_l2_cfu
    import common_pkg::*, cfu_pkg::*;
#(
    `CFU_L2_PARAMS(/*N_CFUS*/1, /*N_STATES*/1, /*FUNC_ID_W*/10, /*INSN_W*/0, /*DATA_W*/32),
    parameter int CFU_LATENCY = 0,
    parameter int CFU_FIFO_SIZE = 2**$clog2(1+CFU_LATENCY)
) (
    `CFU_CLK_L2_PORTS(input, output, req, resp)
);
    initial ignore(`CHECK_CFU_L2_PARAMS && check_param_pos("CFU_N_STATES", CFU_N_STATES));
`ifdef MULACC_L2_CFU_VCD
    initial begin $dumpfile("mulacc_l2_cfu.vcd"); $dumpvars(0, mulacc_l2_cfu); end
`endif

    `CFU_L1_NETS(t_req, t_resp);
    cvt12_cfu #(`CFU_L2_PARAMS_MAP, .CFU_LATENCY(CFU_LATENCY), .CFU_FIFO_SIZE(CFU_FIFO_SIZE))
        cvt12(`CFU_CLK_L2_PORT_MAP(req,req, resp,resp),
              `CFU_L1_PORT_MAP(t_req,t_req, t_resp,t_resp));
    mulacc_cfu #(`CFU_L1_PARAMS_MAP) mulacc(`CFU_CLK_L1_PORT_MAP(req,t_req, resp,t_resp)); 
endmodule
