CFU Zoo
=======

This work-in-progress directory will provide various example CFUs, standard mux and adapter CFUs,
CFU-LI compatible CPUs, and composed systems.

The various testbenches require `cocotb` `cocotb-test` `pytest-xdist` `iverilog` `verilator-4.106`.
Planning to automate setup and execution using `tox`.

Until then, any testbench may be run with
`
[SIM=[icarus|verilator]] pytest -n auto <cfu>_test.py
`
RTL code may only use the subset of System Verilog that is implemented by Icarus Verilog and
Verilator, and must be free of warnings, esp. Verilator lint warnings.

Current CFU examples:

| CFU          | level | stateful | serializ. | comments            |
|--------------|-------|----------|-----------|---------------------|
| popcount_cfu | L0    | -        | -         | -                   |
| bnn_cfu      | L0    | -        | -         | reuses popcount_cfu |
| mulacc_cfu   | L1    | yes      | yes       | -                   |
| dotprod_cfu  | L1    | yes      | yes       | -                   |

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
