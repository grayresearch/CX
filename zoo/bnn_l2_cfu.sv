// bnn_l2_cfu.sv: 32/64-bit binary neural net dot product CFU-L2 streaming CFU
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

// bnn_l2_cfu: 32/64-bit population count CFU-L2 streaming CFU,
// via composing a cvt02_cfu with a CFU-L0 bnn_cfu
module bnn_l2_cfu
    import common_pkg::*, cfu_pkg::*;
#(
    `CFU_L2_PARAMS(/*N_CFUS*/1, /*N_STATES*/0, /*FUNC_ID_W*/0, /*INSN_W*/0, /*DATA_W*/32)
) (
    `CFU_CLK_L2_PORTS(input, output, req, resp)
);
    initial ignore(`CHECK_CFU_L2_PARAMS && check_param("CFU_N_STATES", CFU_N_STATES, 0));
`ifdef BNN_L2_CFU_VCD
    initial begin $dumpfile("bnn_l2_cfu.vcd"); $dumpvars(0, bnn_l2_cfu); end
`endif

    `DECLARE_CFU_L0_NETS(t_req, t_resp);
    cvt02_cfu #(`CFU_L2_PARAMS_MAP)
        cvt(`CFU_CLK_L2_PORT_MAP(req,req, resp,resp), `CFU_L0_PORT_MAP(t_req,t_req, t_resp,t_resp));
    bnn_cfu #(`CFU_L0_PARAMS_MAP)
        bnn(`CFU_L0_PORT_MAP(req,t_req, resp,t_resp)); 
endmodule
