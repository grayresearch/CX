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

This new [talk video](https://www.youtube.com/watch?v=7daY_E2itpo)
accompanies the spec, presenting the *Design and Rationale* of the Specification
([slides PDF](https://raw.githubusercontent.com/grayresearch/CFU/main/collateral/design-rationale-CX-CXU-spec.pdf))
which explains why RISC-V needs standards-based composable extensions
to bring order and reuse to the custom extensions Wild West. The talk
details the design of the various interop interface standards proposed
in the spec, and importantly, it
[explains why they are they way they are](https://www.youtube.com/watch?v=7daY_E2itpo&t=415s).

As of fall 2023, we are working to submit this work as a basis of a
proposed RISC-V Composable Extensions Task Group. Please review the draft
[Composable Extensions (CX) Task Group Charter](https://github.com/riscv-admin/sig-soft-cpu/blob/main/TG/CX/CHARTER.md).

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

