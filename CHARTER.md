# Composable Extensions (CX) Task Group Charter

Reuse of multiple custom extensions is rare, in part because extensions
may conflict in use of custom instructions and CSRs, and because there
is no common programming model or API for discovering, using, and
managing such extensions. This leads to disjoint solution silos and
ecosystem fragmentation. This TG will fix this.

The TG will specify an ISA extension (CX ISA) plus interop interface
standards (CX API, CX ABI, and CX Unit logic interface (CXU-LI)) that
enable practical reuse, within a system, of multiple, independently
authored composable custom extensions (CXs), CX libraries, and CX unit
cores, remaining backwards compatible with legacy custom extensions.

* *CX ISA* extension provides CX multiplexing (muxing), CX access control,
  and CX state context management.

  * *CX muxing* enables multiple CXs to coexist within a system, conflict free;
    software selects the hart’s CX and CX state context, prior to issuing
    that CX’s custom instructions and accessing its custom CSRs.
  
  * *CX access control* enables priv code to grant/deny unpriv code access
    to specific CXs / state contexts.
  
  * *CX state context management* enables an OS to virtualize and multiprogram
    any CX / state context.

* *CX API* provides CX libraries with a uniform CX programming model,
  including CX naming, discovery, versioning, state management, and
  error handling.

* *CX ABI* ensures correct nested library composition via disciplined
  save/restore of the CX mux selection.

* *CXU logic interface* is an optional interop interface standard enabling
  reuse of modular CXU hardware via automated composition of a DAG of
  CPUs and CXUs into one system. With CXU-LI, each CXU implements one
  or more CXs, and, in response to a CX instruction, muxing delegates
  it to the selected CX/CXU.

The TG specifications should aim to balance these design tenets:

1. *Composability:* The behavior of a CX or CX library does not change
when used alongside other CXs.

2. *Decentralization:* Anyone may define or use a CX without coordination
with others, and without resort to a central authority.

3. *Stable binaries:* CX library *binaries* compose without rewriting,
recompilation or relinking.

4. *Composable hardware:* Adding a CXU to a system does not require
modification of other CPUs or CXUs.

5. *Frugality:* Prefer simpler induced hardware and shorter code paths.

6. *Security:* The specifications include a vulnerability assessment
and do not facilitate new side channel attacks.

7. *Longevity:* The specifications define how each interface may be
versioned over decades, and incorporate mechanisms to improve forwards
compatibility.

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
provide their extension as a composable extension, with a modular CXU
implementation for use with CXU-LI-compliant CPU cores. CX multiplexing
reduces the opcode and CSR impact of such extensions to zero, extending
the life of the 32b encodings. CX discovery and versioning provides such
extensions a uniform forwards compatible versioning story.

### Overlaps (incomplete!)

* CX discovery API may overlap uniform discovery TG

## History

In 2019, the RISC-V Foundation FPGA soft processor SIG members, working
to advance RISC-V as the preeminent ecosystem for FPGA SoCs, committed to
"Propose extensions ... to enable interoperable RISC-V FPGA platforms and
applications". Members set out to define standards by which FPGAs'
extensible RISC-V cores might enable a marketplace of reusable custom
extensions and libraries. In 2019-2022, members met to define a
*minimum viable set* of interop interfaces, now the
[Draft Proposed RISC-V Composable Custom Extensions Specification](https://raw.githubusercontent.com/grayresearch/CX/main/spec/spec.pdf),
proposed as a starting point for CX TG.
