_Draft Proposed_ Composable Custom Extensions Specification
===========================================================

This document comprises draft proposed specifications for
hardware-software and hardware-hardware interfaces, formats, and metadata,
enabling independent, efficient, and robust composition of diverse
custom instruction set extensions, hardware custom function units,
and software libraries.

It is a work in progress. We request your feedback.

At present this is not a work product of a RISC-V International Working
Group, Technical Committee, or subcommittee.  Rather we share this work
in the hope that it may motivate and inform a hypothetical _Composable
Custom Extensions_ RISC-V Extension Working Group.

(Pending standardization, implementers might elect to implement the
present specifications as their own _custom extension_.)

This work summarizes years of ongoing discussions and prototyping by
(alphabetical order): Tim Ansell, Tim Callahan, Jan Gray, Karol Gugala,
Maciej Kurc, Guy Lemieux, Charles Pappon, Zdenek Prikryl, Tim Vogt.


* * *

Copyright (C) 2019-2022, Jan Gray <jan@fpga.org> +
Copyright (C) 2019-2022, Tim Vogt

Licensed under the Apache License, Version 2.0 (the "License"); you may
not use this file except in compliance with the License.  You may obtain
a copy of the License at
https://www.apache.org/licenses/LICENSE-2.0.html.

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
License for the specific language governing permissions and limitations
under the License.

This work incorporates design elements from the RISC-V documentation
template https://github.com/riscv/docs-dev-guide which uses a Creative
Commons Attribution 4.0 International ("CC BY 4.0") license. It is
built using the asciidoc docker tools image `riscvintl/rv-docs`.

RISC-V is a registered trade mark of RISC-V International.

