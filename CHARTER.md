# Composable Extensions (CX) Task Group Charter

## Executive Summary

This Charter governs the TG for a Composable Extensions (CX) framework
enabling robust composition of multiple independently authored composable
custom extensions, alongside legacy custom extensions, assembled in a
conflict-free way in one RISC-V system. By multiplexing the custom opcode
space, and adopting common software and hardware interop interfaces,
CX enables *uniform* extension naming, discovery, and versioning, error
handling, state context management, extension hardware module reuse,
and stable software binaries that do not require recompilation for each
target system -- all without a central management authority.

## Introduction - the custom extensions reuse problem

RISC-V reserves the custom-\* opcode space, enabling anyone to create new
custom extensions and extension-aware software libraries. But RISC-V
custom extensions are unmanaged, lacking uniformity, conventions,
or standards. This impairs extension reuse. Use of one extension in
a system may preclude use of another, because the two extensions may
have conflicting custom instructions, or may have incompatible means of
extension discovery, versioning, computation, state, error handling,
etc. This leads to disjoint solution silos and fragmentation of the
RISC-V ecosystem.

## Objectives

The Composable Extensions (CX) Task Group(s) will specify an ISA
extension, and specify standard software (API, ABI) and hardware
(logic interface, metadata) interfaces enabling independent creation
of extensible processors, composable extensions, extension libraries,
and extension hardware, that compose readily and coexist harmoniously.

Operationally, the interfaces enable software to *discover* that a CX
is available, to *select* it as the hart's current CX, to *select* the
hart's current CX *state context*, to *issue* its custom instructions,
and to *signal* errors; and then discover that a second CX is available,
select it, and issue its custom instructions. And so forth.

CX instructions may access a hart's current CX's current state context.
CX instructions are the only means to access CX state, providing CX
isolation, providing composition invariance. A CX state context may
include *CX-scoped* CSRs. There may be any number of state contexts,
per CX, per system, with an arbitary, dynamic, software managed
hart-to-CX-context mapping. Uniform means of CX state context access
enables a CX-aware operating system to manage/save/restore any CX state
context, unmodified.

The optional hardware interfaces provide reuse of composable extension
unit (CXU) *implementations* (which may be RTL modules). They support
automated composition of a DAG of CPUs and CXUs into one system. Each
CXU implements one or more CXs. In response to a CX instruction, a CPU
delegates the instruction to the hart's currently selected CXU.

The extension and interfaces must fulfil these requirements:
composability, conflict-freedom, decentralization, stable binaries,
composable hardware, uniformity (of scope, naming, discovery, versioning,
error signaling, state management, access control), frugality, security,
performance, and longevity. In particular:

1. *Composability:* The behavior of a CX or CX library does not change
when combined together with other CXs or ordinary *non-composable* custom
extensions (NCXs), or their libraries, in one system.

2. *Conflict-freedom:* Any CX may use any of (possibly a *CX subset*
of) the custom-\* opcode instructions, without conflict with other CXs
or NCXs.

3. *Decentralization:* Anyone may define, implement, and/or use a CX
without coordination with others, and without resort to a central naming
or numbering authority.

4. *Stable binaries:* CX library *binaries* compose without rewriting,
recompilation or relinking.

5. *Composable hardware:* An extension may be implemented by a reusable
CX hardware unit (CXU). Adding a CXU to a system does not require
modification of other CPUs or CXUs. A CXU *may be* implemented in a
nonproprietary HDL such as Verilog.

6. *Uniformity:* of *scope:* at least: instructions may access integer
registers and may be stateful; of *naming, discovery, versioning:*
CX software has a uniform means to discover if specific CX or CX version
is available.

7. *Frugality:* To reduce processor hardware complexity, the ISA extension
supports CX multiplexing and error signaling, while other CX services may
be provided by a software API, or by a small standard set of CX state
context instructions.

8. *Security:* The specifications include a vulnerability assessment,
and they do not facilitate new side channel attacks. Privileged software
may grant or deny unprivileged software access to a CX or its state.

9. *Performance:* Selection of a hart's current CX and CX state context
is very fast, ideally one instruction, even if subject to CX access
control.

10. *Longevity:* The specifications define how the specified interfaces
are versioned over decades, providing best possible forwards and backwards
compatibility to mixes of old and new composable extensions, libraries,
and CXUs.

### Deliverables, separation of TG responsibilities

1. *CX-ISA sub-TG* defines the Composable Extensions standard extension
*-Zicx* implementing access controlled CX multiplexing and error
signaling. This comprises:

    a. New CSRs, instructions, or other mechanisms to enable, select,
    and access-control CX and CX state multiplexing; and

    b. New CSRs, instructions, or other mechanisms to uniformly
    signal errors during CX instruction execution.

2. *CX-SW sub-TG* defines:

    a. CX-RT: The CX Runtime API for uniform CX naming, discovery,
    version management, uniform extension state context management,
    and uniform access control;

    b. CX-ABI: The application binary interface governing disciplined
    use of -Zicx CX multiplexing.

    c. Standard CX behaviors (e.g., state isolation) and instructions
    (e.g., for uniform access to state contexts) so that CXs and CX
    software are truly composable.

3. *CX-HW sub-TG* defines:

    a. CXU-LI: the composable extension unit logic interface, a
    HW-HW interface specification to exchange uniform CXU requests
    and responses, and

    b. CXU-MD: the system manifest and CPU/CXU core metadata format,
    specifying system and cores' CXU-LI constraints and parameters.

    Together CXU-LI and CXU-MD enable automated composition of
    configurable CPU and CXU cores into processor complexes.

The interrelationship of these three subgroups' abstraction
layers is illustrated in this hardware-software stack diagram.

<img src="/spec/images/composition-layers.png" width="500">

The three sub-specifications may be applied separately, or together. For
example, an implementation might implement the -Zicx extension and
the CX Runtime API, hosting CX libraries obeying the CX-ABI, but *not*
adopt CXU-LI or CXU-MD, employing other means to implement the various
composable extensions in hardware.

### Acceptance criteria

Each deliverable must be implemented and proven in nontrivial interop
scenarios. Therefore, a prerequisite for ratification of any CX TG spec
is a plug-fest demonstration of 3+ different soft processors, each with
3+ CXs, 2+ stateful, running a multithreaded Linux workload, each such
thread using all of the composable extensions' libraries.

## Exclusions

The -Zicx extension will specify what *kinds* of custom instructions
are valid within a *composable* extension. In particular, not every
arbitrary custom extension can be a composable extension.

The present TG(s) focus on *enabling* composition of extensions and
software. Later, additional TG standards work may be helpful, e.g.,
tools support including debugging and profiling, formal specification
of CXs' interface contracts, CX library metadata, and automatic system
composition and composition tools.

## Collaborations

A ratified CX framework should enable most unpriv computational extension
TGs to prototype, perfect, prove value, and ratify their extension as a
composable extension, and to provide a reference Composable Extension Unit
(CXU) implementation. For example, the entirely of the bitmanip extension
might have been a composable extension and its reference CXU, immediately
available (opt-in plug-in) across all CX compliant RISC-V systems.

Since each composable extension may use the entirety of the CX custom
opcode space, conflict free, each such TG may work without interference
from or to others. Uniform CX discovery and versioning enables a TG
to undertake to produce a series of extension versions with a known,
uniform forward compatibility strategy.

Since composable extensions consume no opcode space and introduce no
new (conventional) CSRs, each such extension comes at negligible cost
to the enduring complexity of the core RISC-V ISA specs, or to the many
dozens of extant RISC-V processor core instruction decoders and CSR
datapaths, while also extending the useful life and reach of the 32b
RISC-V ISA without resort to 48b or 64b encodings.

### Overlaps (probably many, more TBD)

* CX discovery API may overlap uniform discovery TG;

* the CX scoped CSR feature may overlap with CSR indirection.

## History

In 2019, the RISC-V Foundation FPGA soft processor SIG members, determined
to advance RISC-V as the preeminent ecosystem for FPGA processor and SoC
designs, started to work on their Charter goal to "Propose extensions
... to enable interoperable RISC-V FPGA platforms and applications".

The RISC-V provision for introducing custom instruction extensions
dovetails with existing practice of *configurable* FPGA soft
processors. But dissatisfied with past incompatible soft CPU tech stack
silos, the members opted to pursue standards by which various reusable
cores that implement various custom extensions might be reused across
various RISC-V soft CPUs.

Members also felt that a vibrant ecosystem of mix-and-match reusable
custom extensions, libraries, and cores, requires new interop interface
standards to achieve routine, robust composition of *multiple* such
extensions within one system.

Through 2019-2022, the effort to define the *minimum viable set* of
standards to enable practical composition of extensions grew to include
CX multiplexing, uniform state context management, access control, etc.,
culminating in the
[Draft Proposed RISC-V Composable Custom Extensions Specification](https://raw.githubusercontent.com/grayresearch/CX/main/spec/spec.pdf),
proposed as a basis / starting point for the TGs work. In 2023,
[the SIG moved to RISC-V International's Technology Horizontal Committee](https://lists.riscv.org/g/tech-announce/message/277),
and now proposes to undertake to standardize the work as one or more
RVI TGs.
