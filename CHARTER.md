# Composable Extensions ISA (CX-ISA) TG and Software (CX-SW) TG Charters

## Introduction / Problem Statement

RISC-V reserves the custom-\* opcode space, enabling everyone to create
new custom extensions and extension-aware software libraries. But RISC-V
custom extensions are an unmanaged wild west, lacking uniformity,
conventions, standards. This impairs extension reuse. Use of one
extension in a system may preclude use of another, because the two
extensions may have conflicting custom instructions, or may have
incompable means of extension discovery, versioning, computation,
state, error handling, etc. This leads to disjoint solution silos and
fragmentation of the RISC-V ecosystem.

To overcome this custom extensions' reuse problem / standards gap, the
CX-ISA and CX-SW TGs will define interop standards enabling development
and reuse of multiple *composable* custom extensions and their libraries,
together in one system.

## Charters

The Composable Extensions ISA (CX-ISA) Task Group, and concurrently,
the Composable Extensions Software (CX-SW) Task Group, together will
specify a RISC-V ISA standard extension, a runtime library API, and an
ABI, enabling any number of *composable extensions* (CXs) and their
software libraries to harmoniously coexist within one RISC-V system.

Operationally, these standards will enable extension-aware software to
*discover* that a CX is available, to *select* it as the hart's current
CX, and to *issue* its custom instructions. *Stateful* CX instructions
may access the hart's current CX state. Then software may discover a
second CX, separately authored or versioned, is available, select it,
and issue its custom instructions. The various CXs' state contexts are
managed by CX-agnostic software.

The ISA extensions, API, and ABI must fulfil these requirements:
composability, conflict-freedom, decentralization, stable binaries,
uniformity (of scope, naming, discovery, versioning, error signaling,
state management, access control), performance, frugality, security,
and longevity. In particular:

1. *Composability:* The behavior of a CX or CX library does not change
when combined together with other CXs, ordinary *non-composable* custom
extensions (NCXs), or extension library in one system.

2. *Conflict-freedom:* Any CX may use any of the custom-\* opcode
instructions, without conflict with other CXs or NCXs.

3. *Decentralization:* Anyone may define, implement, and/or use a CX
without coordination with others, and without resort to a central naming
or numbering authority.

4. *Stable binaries:* Compiled software that issues CX instructions
safely coexists with other software that use different CXs or NCXs,
without resort to recompilation or relinking.

5. *Uniformity:*
*Scope:* CX instructions may access integer registers, and may be stateless or stateful;
*naming, discovery, versioning:* CX library software employs a common CX identifier,
and common means for software to dynamically discover if a specific CX or
CX version is available in this system;
*error signaling:* with a common means to signal any CX error to software; and
*state management:* with a common means for software to select and manage CX state contexts.

6. *Performance:* A single instruction suffices to select the CX and
CX state context of CX instructions that follow.

7. *Frugality:* To minimize hardware complexity, 
the CX-ISA extension provides only (access controlled) CX multiplexing and error signaling.
All other CX services are provided by a software API specified by CX-SW TG.

8. *Security:* Privileged software may grant or deny unprivileged
software access to a CX or its state. Once again, a single instruction
suffices to select the CX and CX state context without a detour
into privileged software. The use of a CX or its state on one
hart is not visible to other harts (except for instruction latencies).

9. *Longevity:* The TG standards explicitly document how specified
interfaces version over decades, providing best possible forwards and
backwards compatibility to mixes of old and new composable extensions
and their libraries.

## Deliverables, Division of TG responsibilities

1. *CX-ISA TG* defines the Composable Extensions standard extension *-Zicx* implementing access controlled CX multiplexing and error signaling. This comprises:

	a. New CSRs, new instructions, or other new mechanisms to enable, select, and access-control CX and CX state multiplexing; and

	b. New CSRs, new instructions, or other new mechanisms to uniformly signal errors arising during CX instruction execution.

2. *CX-SW TG* defines:

	a. The CX-Runtime API for uniform CX naming, discovery, version management; uniform extension state context management; and uniform access control;

	b. The CX-ABI for disciplined possibly nested CX selection multiplexing; and

	c. Standard custom instructions that stateful CXs implement for uniform per-CX CSRs, per-CX extended error signaling, and per-CX state context management.

## History

In 2019, the RISC-V Foundation FPGA soft processor SIG members, determined
to advance RISC-V as the preeminent ecosystem for FPGA processor and SoC
designs, started to work on their Charter goal to "Propose extensions
... to enable interoperable RISC-V FPGA platforms and applications".

RISC-V provision for custom extensions dovetails with existing practice
of *configurable* FPGA soft processors. But dissatisfied with past
incompatible soft CPU tech stack silos, the members opted to pursue
standards by which various reusable cores that implement various custom
extensions might be reused across various RISC-V soft CPUs.

Members also felt that a vibrant ecosystem of mix-and-match reusable
custom extensions, libraries, and cores, requires new interop interface
standards to achieve routine, robust composition of *multiple* such
extensions within one system.

Through 2019-2022, the effort to define the *minimum viable set* of
standards to enable practical composition of extensions grew to include
CX multiplexing, uniform state context management, access control, etc.,
culminating in the
[Draft Proposed RISC-V Composable Custom Extensions Specification](spec/spec.pdf)
[(PDF)](https://raw.githubusercontent.com/grayresearch/CX/main/spec/spec.pdf),
which we propose as a basis / starting point for the TGs work.

In 2023, the SIG has rebooted, moved to RISC-V International's Tech HC,
and now proposes to undertake the CX-ISA TG and the CX-SW TG.
