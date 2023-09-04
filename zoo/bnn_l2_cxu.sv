// bnn_l2_cxu.sv: 32/64-bit binary neural net dot product CXU-L2 streaming CXU
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

// bnn_l2_cxu: 32/64-bit population count CXU-L2 streaming CXU,
// via composing a cvt02_cxu with a CXU-L0 bnn_cxu
module bnn_l2_cxu
    import common_pkg::*, cxu_pkg::*;
#(
    `CXU_L2_PARAMS(/*N_CXUS*/1, /*N_STATES*/0, /*FUNC_ID_W*/0, /*INSN_W*/0, /*DATA_W*/32)
) (
    `CXU_CLK_L2_PORTS(input, output, req, resp)
);
    initial ignore(`CHECK_CXU_L2_PARAMS && check_param("CXU_N_STATES", CXU_N_STATES, 0));
`ifdef BNN_L2_CXU_VCD
    initial begin $dumpfile("bnn_l2_cxu.vcd"); $dumpvars(0, bnn_l2_cxu); end
`endif

    `CXU_L0_NETS(t_req, t_resp);
    cvt02_cxu #(`CXU_L2_PARAMS_MAP)
        cvt(`CXU_CLK_L2_PORT_MAP(req,req, resp,resp), `CXU_L0_PORT_MAP(t_req,t_req, t_resp,t_resp));
    bnn_cxu #(`CXU_L0_PARAMS_MAP)
        bnn(`CXU_L0_PORT_MAP(req,t_req, resp,t_resp)); 
endmodule
