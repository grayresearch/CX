# Composable Extensions (CX) Task Group Charter

## Executive Summary

This Charter governs the TG for a Composable Extensions (CX) framework
enabling robust composition of multiple independently authored composable
custom extensions, alongside legacy custom extensions, conflict-free in
one RISC-V system.

By multiplexing the custom opcode space, and adopting common software
and hardware interop interfaces, CX enables *uniform* extension naming,
discovery, and versioning, error handling, state context management,
extension hardware module reuse, and stable software binaries for each
target system -- all without a central management authority.

## Introduction - the custom extensions reuse problem

RISC-V reserves the custom-\* opcode space, enabling anyone to create
new custom extensions and their software libraries. But RISC-V custom
extensions are unmanaged, lacking standards or uniformity. This impairs
extension reuse. Use of one extension in a system may preclude use
of another, because they may have conflicting custom instructions, or
incompatible means of extension discovery, versioning, state management,
etc. This leads to disjoint solution silos and fragmentation of the
RISC-V ecosystem.

## Objectives

The Composable Extensions (CX) Task Group(s) will specify ISA extensions
and software (API, ABI) and hardware (logic interface, metadata)
interfaces enabling independent creation of extensible processors,
composable extensions, extension libraries, and extension hardware,
that compose readily and harmoniously.

*CX Multiplexing:* Operationally, a *CX Mux* extension, and CX API and
ABI, enable software to *discover* that a CX is available, to *select*
it and to *select* its current CX *state context*, to *issue* its custom
*CX instructions*, and to *signal* errors; and then discover that another
CX is available, select it, and issue its instructions. And so forth.

*CX State Contexts:* CX instructions may access the current CX's
current state context. CX instructions are the only means to access
CX state. A CX state context also has *CX-scoped* CSRs *(CXRs)*,
accessed by uniform CXR instructions. There may be any number of
state contexts, per CX, per system, with an arbitrary, dynamic, software
managed hart-to-CX-context mapping. All stateful CXs implement the *CX
Context CXRs* enabling uniform OS CX context management. There is a
privileged access control mechanism to efficiently grant/deny access to
CX contexts by less privileged software.

*Modular Hardware:* The *CX Unit (CXU) logic interface (CXU-LI)* allows
reuse of modular hardware implementations. It provides automated
composition of a DAG of CPUs and CXUs into one system. Each CXU implements
one or more CXs. In response to a CX instruction, a CPU delegates the
instruction to the hart's currently selected CXU.

*Tenets:* The extension and interfaces must fulfil these requirements:
composability, conflict-freedom, decentralization, stable binaries,
composable hardware, uniformity (of scope, naming, discovery, versioning,
error signaling, state management, access control), frugality, security,
and longevity. In particular:

1. *Composability:* The behavior of a CX or CX library does not change
when used with other CXs.

2. *Conflict-freedom:* Any CX may use the *CX subset* of the custom-\*
opcode instructions, without conflict with other CXs or ordinary non-CX
custom extensions.

3. *Decentralization:* Anyone may define or use a CX without coordination
with others, and without resort to a central authority.

4. *Stable binaries:* CX library *binaries* compose without rewriting,
recompilation or relinking.

5. *Composable hardware:* Adding a CXU to a system does not require
modification of other CPUs or CXUs. A CXU *may be* implemented in a
nonproprietary HDL such as Verilog.

6. *Uniformity:* of *scope:* at least: instructions may access integer
registers and may be stateful; of *naming, discovery, versioning:*
CX software has a uniform means to discover if specific CX or CX version
is available.

7. *Frugality:* Prefer simpler induced hardware and shorter code paths.

8. *Security:* The specifications include a vulnerability assessment
and do not facilitate new side channel attacks.

9. *Longevity:* The specifications define how each interface may be
versioned over decades, and incorporate mechanisms to improve forwards
compatibility.

### Deliverables

1. *CX-Mux-ISA* defines new ISA specs for: a. CX multiplexing and error
signaling (unpriv); b. CX access control (priv).

2. *CX-State-ISA* defines new (per each CX) ISA specs for: a. CXR
instructions (unpriv); b. CX State Context CXRs (priv).

3. *CX-SW* defines: a. CX-API: CX Runtime API for uniform software access
to CXs. b. CX-ABI: application binary interface governing disciplined
use of CX-\*-ISA.

4. *CX-HW* defines *optional* specs for: a. CXU-LI: reusable CX unit
logic interface; b. CXU-MD: metadata format describing systems, CPUs,
and CXUs, enabling automatic composition of CPU + CXU complexes.

### Acceptance criteria

Each deliverable must be implemented and proven in nontrivial interop
plugfest scenarios involving multiple processors x extensions x extension
libraries x OSs.

## Exclusions

Not every arbitrary custom extension can be a composable extension.

The CX TG is focused on the minimum viable standards *enabling*
practical composition of extensions and software. Further standards
for infrastructure and tooling e.g. for CX packages, debug, profile,
formal specification of CX interface contracts, CX library metadata,
and tools, are _out of scope_.

## Collaborations

The CX framework will enable many unpriv computational extension TGs to
provide their extension as a composable extension, with a modular
CXU implementation that enables that extension in any CXU-LI-compliant
CPU cores. CX multiplexing reduces the opcode and CSR impact of such
extensions to zero, extending the life of the 32b encodings. CX discovery
and versioning provides such extensions a uniform forwards compatible
versioning story.

### Overlaps (probably many, more TBD)

* CX discovery API may overlap uniform discovery TG;

* the CX scoped CSR feature may overlap with CSR indirection.

## History

In 2019, the RISC-V Foundation FPGA soft processor SIG members, determined
to advance RISC-V as the preeminent ecosystem for FPGA SoCs, committed to
"Propose extensions ... to enable interoperable RISC-V FPGA platforms
and applications". SIG members set out to define standards by which
FPGAs' extensible RISC-V cores might enable a marketplace of reusable
and composable custom extensions and libraries. Through 2019-2022,
members met to define the *minimum viable set* of interop interfaces
culminating in the
[Draft Proposed RISC-V Composable Custom Extensions Specification](https://raw.githubusercontent.com/grayresearch/CX/main/spec/spec.pdf),
now proposed as a starting point for RVI CX TG work.
