CXU Zoo
=======

This work-in-progress directory will provide various example CXUs, standard mux and adapter CXUs,
CXU-LI compatible CPUs, and composed systems.

The various testbenches require `cocotb` `cocotb-test` `pytest-xdist` `iverilog`
and `verilator-4.106` or `verilator-5.006+`.
Planning to automate setup and execution using `tox`.

Until then, any testbench may be run with
`
[SIM=[icarus|verilator]] pytest -n auto <cxu>_test.py
`
RTL code may only use the subset of System Verilog that is implemented by Icarus Verilog and
Verilator, and must be free of warnings, esp. Verilator lint warnings.

Current CXU examples:

| CXU             | level | stateful | serializ. | comments                           |
|-----------------|-------|----------|-----------|------------------------------------|
| popcount_cxu    | L0    | -        | -         | -                                  |
| bnn_cxu         | L0    | -        | -         | reuses popcount_cxu                |
| mulacc_cxu      | L1    | yes      | yes       | -                                  |
| dotprod_cxu     | L1    | yes      | yes       | -                                  |
| cvt01_cxu       | L1    | -        | -         | CXU-L0 to -L1 adapter              |
| cvt02_cxu       | L2    | -        | -         | CXU-L0 to -L2 adapter              |
| cvt12_cxu       | L2    | *        | *         | CXU-L1 to -L2 adapter              |
| mux2_cxu        | L2    | *        | *         | CXU-L2 2-1 multiplexer adapter     |
| bnn_l1_cxu      | L1    | -        | -         | bnn_cxu + cvt01_cxu                |
| bnn_l2_cxu      | L2    | -        | -         | bnn_cxu + cvt02_cxu                |
| bnn_l1_l2_cxu   | L2    | -        | -         | bnn_cxu + cvt01_cxu + cvt12_cxu    |
| mulacc_l2_cxu   | L2    | yes      | yes       | cvt12_cxu + mulacc_cxu             |
| mux_macs_cxu    | L2    | yes      | yes       | mux-n + n mulacc_l2_cxu            |

* = an adapter CXU which is stateful and/or serializable if its target CXU(s) are

* * *

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
