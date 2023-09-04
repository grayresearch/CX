#!/usr/bin/env python3
"""
generate an m-initiator n-target switch_cfu

Copyright (C) 2019-2023, Gray Research LLC.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

Derived from @alexforencich's
  http://github.com/corundum/verilog-axis/blob/master/rtl/axis_switch_wrap.py
which is Copyright (c) 2014-2018 Alex Forencich (MIT license); see
  https://github.com/corundum/verilog-axis/blob/master/COPYING
"""

import argparse
from jinja2 import Template

def main():
    parser = argparse.ArgumentParser(description=__doc__.strip())
    parser.add_argument('-p', '--ports',  type=int, default=[2], nargs='+', help="no. of ports")
    args = parser.parse_args()

    try:
        generate(**args.__dict__)
    except IOError as ex:
        print(ex)
        exit(1)

def generate(ports = 2):
    if type(ports) is int:
        m = n = ports
    elif len(ports) == 1:
        m = n = ports[0]
    else:
        m, n = ports

    name = "switch{0}x{1}_cfu".format(m, n)
    output = f"{name}.sv"

    t = Template(
"""// {{name}}.sv: connect {{m}} initiator(s) to {{n}} target CFUs (CFU-L2)
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

// {{name}}: connect {{m}} initiator(s) to {{n}} target CFUs (CFU-L2)
module {{name}}
    import common_pkg::*, cfu_pkg::*;
#(
    `CFU_L2_PARAMS(/*N_CFUS*/1, /*N_STATES*/1, /*FUNC_ID_W*/$bits(cfid_t), /*INSN_W*/0, /*DATA_W*/32),
    parameter int N_REQS    = 16    // max no. of in-flight requests per initiator and per target
) (
    `CFU_CLOCK_PORTS,
{%- for p in range(m) %}
    `CFU_L2_PORTS(input, output, i{{'%01d'%p}}_req, i{{'%01d'%p}}_resp), {% endfor %}
{%- for p in range(n) %}
    `CFU_L2_PORTS(output, input, t{{'%01d'%p}}_req, t{{'%01d'%p}}_resp){% if not loop.last %},{% endif %} {% endfor %}
);
    initial ignore(
        `CHECK_CFU_L2_PARAMS
    &&  check_param("CFU_FUNC_ID_W", CFU_FUNC_ID_W, $bits(cfid_t)));
`ifdef SWITCH_CFU_VCD
    initial begin $dumpfile("{{name}}.vcd"); $dumpvars(0, {{name}}); end
`endif

    switch_cfu_core #(`CFU_L2_PARAMS_MAP, .N_INIS(N_INIS), .N_TGTS(N_TGTS), .N_REQS(N_REQS))
    core(
        .clk, .rst, .clk_en,
        // initiators
        .i_req_valids({ {% for p in range(m-1,-1,-1) %}i{{'%1d'%p}}_req_valid{% if not loop.last %}, {% endif %}{% endfor %} }),
        .i_req_readys({ {% for p in range(m-1,-1,-1) %}i{{'%1d'%p}}_req_ready{% if not loop.last %}, {% endif %}{% endfor %} }),
        .i_req_cfus({ {% for p in range(m-1,-1,-1) %}i{{'%1d'%p}}_req_cfu{% if not loop.last %}, {% endif %}{% endfor %} }),
        .i_req_states({ {% for p in range(m-1,-1,-1) %}i{{'%1d'%p}}_req_state{% if not loop.last %}, {% endif %}{% endfor %} }),
        .i_req_funcs({ {% for p in range(m-1,-1,-1) %}i{{'%1d'%p}}_req_func{% if not loop.last %}, {% endif %}{% endfor %} }),
        .i_req_insns({ {% for p in range(m-1,-1,-1) %}i{{'%1d'%p}}_req_insn{% if not loop.last %}, {% endif %}{% endfor %} }),
        .i_req_data0s({ {% for p in range(m-1,-1,-1) %}i{{'%1d'%p}}_req_data0{% if not loop.last %}, {% endif %}{% endfor %} }),
        .i_req_data1s({ {% for p in range(m-1,-1,-1) %}i{{'%1d'%p}}_req_data1{% if not loop.last %}, {% endif %}{% endfor %} }),
        .i_resp_valids({ {% for p in range(m-1,-1,-1) %}i{{'%1d'%p}}_resp_valid{% if not loop.last %}, {% endif %}{% endfor %} }),
        .i_resp_readys({ {% for p in range(m-1,-1,-1) %}i{{'%1d'%p}}_resp_ready{% if not loop.last %}, {% endif %}{% endfor %} }),
        .i_resp_statuss({ {% for p in range(m-1,-1,-1) %}i{{'%1d'%p}}_resp_status{% if not loop.last %}, {% endif %}{% endfor %} }),
        .i_resp_datas({ {% for p in range(m-1,-1,-1) %}i{{'%1d'%p}}_resp_data{% if not loop.last %}, {% endif %}{% endfor %} }),
        // targets
        .t_req_valids({ {% for p in range(n-1,-1,-1) %}t{{'%1d'%p}}_req_valid{% if not loop.last %}, {% endif %}{% endfor %} }),
        .t_req_readys({ {% for p in range(n-1,-1,-1) %}t{{'%1d'%p}}_req_ready{% if not loop.last %}, {% endif %}{% endfor %} }),
        .t_req_cfus({ {% for p in range(n-1,-1,-1) %}t{{'%1d'%p}}_req_cfu{% if not loop.last %}, {% endif %}{% endfor %} }),
        .t_req_states({ {% for p in range(n-1,-1,-1) %}t{{'%1d'%p}}_req_state{% if not loop.last %}, {% endif %}{% endfor %} }),
        .t_req_funcs({ {% for p in range(n-1,-1,-1) %}t{{'%1d'%p}}_req_func{% if not loop.last %}, {% endif %}{% endfor %} }),
        .t_req_insns({ {% for p in range(n-1,-1,-1) %}t{{'%1d'%p}}_req_insn{% if not loop.last %}, {% endif %}{% endfor %} }),
        .t_req_data0s({ {% for p in range(n-1,-1,-1) %}t{{'%1d'%p}}_req_data0{% if not loop.last %}, {% endif %}{% endfor %} }),
        .t_req_data1s({ {% for p in range(n-1,-1,-1) %}t{{'%1d'%p}}_req_data1{% if not loop.last %}, {% endif %}{% endfor %} }),
        .t_resp_valids({ {% for p in range(n-1,-1,-1) %}t{{'%1d'%p}}_resp_vaid{% if not loop.last %}, {% endif %}{% endfor %} }),
        .t_resp_readys({ {% for p in range(n-1,-1,-1) %}t{{'%1d'%p}}_resp_ready{% if not loop.last %}, {% endif %}{% endfor %} }),
        .t_resp_statuss({ {% for p in range(n-1,-1,-1) %}t{{'%1d'%p}}_resp_status{% if not loop.last %}, {% endif %}{% endfor %} }),
        .t_resp_datas({ {% for p in range(n-1,-1,-1) %}t{{'%1d'%p}}_resp_data{% if not loop.last %}, {% endif %}{% endfor %} })
    );
endmodule
""")

    with open(output, 'w') as f:
        f.write(t.render(m=m, n=n, name=name))
        f.flush()

if __name__ == "__main__":
    main()
