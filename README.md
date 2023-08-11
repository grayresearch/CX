Composable Custom Extensions Project
====================================

This project aims to enable unlimited, independent, efficient, and
robust composition of diverse RISC-V composable extensions,
hardware composable extension units (CXUs), and software libraries.

Eventually the work will include specifications, hardware packages,
and software libraries. Presently the repo includes only the 
[Draft Proposed RISC-V Composable Custom Extensions Specification](spec/spec.pdf)
[(PDF)](https://raw.githubusercontent.com/grayresearch/CX/main/spec/spec.pdf),
with hardware CXU core packages, software libraries, tests, and other
collateral to come.

It is a work in progress. We request your feedback.

At present this is not a work product of a RISC-V International SIG, Task
Group, or subcommittee.  Rather we share this work in the hope that it
may motivate and inform two hypothetical RISC-V International Task Groups:
1) ISA: CX-ISA TG: Composable Extensions (-Zicx); and
2) non-ISA: CXU-LI TG: Composable Extension Unit Logic Interface.

This work summarizes years of ongoing discussions and prototyping by
(alphabetical order): Tim Ansell, Tim Callahan, Jan Gray, Karol Gugala,
Olof Kingdren, Maciej Kurc, Guy Lemieux, Charles Papon, Zdenek Prikryl, Tim Vogt.

* * *

Build the specification
-----------------------
The spec is built using the RISC-V International asciidoc docker tools image
`riscvintl/rv-docs`.  
_Linux_: install docker.
_Windows_: install a WSL2 Linux distro, plus docker or Docker Desktop.  
Run:
```
cd spec
./docker-make.sh
```

* * *

Copyright (C) 2019-2022, Gray Research LLC <jan@fpga.org>.

Licensed under the Apache License, Version 2.0 (the "License"); you may
not use this file except in compliance with the License.  You may obtain
a copy of the License at
https://www.apache.org/licenses/LICENSE-2.0.html.

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
License for the specific language governing permissions and limitations
under the License.

The [specification subdirectory](spec/) incorporates design elements from
the RISC-V documentation template https://github.com/riscv/docs-dev-guide
which uses a Creative Commons Attribution 4.0 International ("CC BY
4.0") license.

RISC-V is a registered trade mark of RISC-V International.

