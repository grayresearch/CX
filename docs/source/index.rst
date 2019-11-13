.. cfu-spec documentation master file, created by
   sphinx-quickstart on Fri Nov  1 08:53:46 2019.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.

*********************************************
Composable Custom Function Unit Specification
*********************************************

Draft 0.1 - WORK IN PROGRESS

Introduction
============

In the coming winter of Moore's Law, computer system designers will employ
application-specific custom hardware accelerators to boost performance
and reduce energy.

A custom function unit (CFU) core is accelerator hardware that is
tightly coupled into the pipeline of a CPU core, to add new custom
function instructions that complement the CPU's standard functions
(such as arithmetic/logic operations).

The present Composable Custom Function Unit (CFU) Specification aims
to enable robust composition of independently authored, independently
versioned CPU cores and CFU cores, and also of the application software
libraries that use the CFU's new instructions.  This enables a rich
ecosystem of interoperable, app-optimized CFU cores and libraries,
and straightforward development of app-optimized SoCs.

The specification comprises the software and hardware interfaces and
formats needed for automatic composition of components into systems.
From bottom up, these comprise:
* The CFU Logic Interface (CFU-LI) that defines the logic
interface between a CPU core and a CFU core.
* The CFU Metadata Format (CFU-MD) that identifies the fixed
and configurable properties and behaviors of CFUs and CPUs,
enabling automated hardware and software composition tooling.
* The miscellaneous CFU Tools changes necessary for composition tooling.


Scope
=====

This specification has been developed under the auspices of the RISC-V
FPGA Soft Processor Working Group but most of the CFU specification is
ISA-neutral and may be applied to other configurable processors.

The initial CFU Spec focuses upon, and restricts its scope to, those
function units that plug into the integer pipeline of a conventional
microprocessor CPU, much like a two-operand, one-result fixed point
arithmetic/logic unit (ALU).

For the purposes and scope of this Spec, a Custom Function Unit is
defined as a hardware core that
* accepts requests and produces responses, wherein:
* requests may comprise a custom function ID and 0-3 integer request
data words;
* responses may comprise a success/error code and 0-2 integer response
data words or an error ID;
* may be stateless, such that all function invocations are pure functions
and are side-effect free, or may be stateful, with private internal
state only. (See below.)

  Function units that directly access or update system memory, or
  architectural state of the CPU, including the CPU's command/status
  registers (CSRs), are out of scope.


Concepts: Custom Function and Custom Interfaces
===============================================

A CFU implements one or more Custom Functions (CFs).

A Custom Function is a function from zero or more request data to zero
or more response data.

A CFU may have state. A CF need not be a pure function. For example,
invoking the same CF multiple times, with the same request data, may
produce different response data.

CFU state, if any, must be private internal state. CFs must not read or
write shared state.

  This rule afford simpler composition of CFUs.

CFs are bundled into Custom Interfaces (CIs).

CIs are identified by a unique integer CIID. Namespace management of
CIIDs is TBD. (COM uses 128-bit GUIDs.)

CIs provide a namespace for CFs. A CF is identified by a (dense) integer
CFID within a CI.

A Custom Interface is an immutable contract defining a set of CFs, the
behavior of the CFs, and (if applicable) the necessary sequence of custom
function invocations required for correct behavior of the interface.

Any organization may define a CI.

CIs are immutable. To change any aspect of the behavior of a CI, define
a new CI.

  Implementers and clients of the original CI are not impacted.

Multiple CFUs may implement the same CI.

A CFU may implement multiple CIs.

  Custom Interfaces are modeled upon the Interface system of the Microsoft
  Component Object Model (COM), a proven regime for robust arms-length
  composition of independently authored, independently versioned software
  components, at scale, over decades.


Concepts: Composing and Compiling a Custom System
=================================================

In the fullness of time, anticipating decades of customization by
thousands of organizations, over thousands of applications, comprising
tens of thousands of CFs, it may not be possible to carve up the
limited opcode space of any target ISA into globally unique, fixed
opcode assignments.

A Custom Function Unit Package comprises a CFU Core that implements the
CFU-LI, packaged with CFU Metadata and its CFU Software (source code
and/or binary library archive).

A system composition tool, TBD, compiles the application and libraries,
the CPU and its CFUs, together into an SoC SW + HW design.

The CFU Software and Metadata identify which Custom Functions of which
Custom Interfaces are used by the software. The tool uses this information
to determine the (app-specific) custom target instruction set mapping
required for the application to invoke the CFs.

The tool also generates the hardware shims necessary to interface the
CPU(s) to the specific CFU(s), and to configure and CFUs (e.g. for
operand width, or specific subset of CFs required) and perhaps the CPUs
(operand latencies).

Each CI specifies some number of CFs: CI.NCF.  The tool maps each CI's
continuous range of CFs into a System CF index (SCFID) appropriate for
that system and for the target ISA.

For example, if the app comprises two libraries, the first library uses
functions 0,2,4 of CI-123 (with its CFs 0-4), and the second library
uses functions 0,1,3 of CI-456 (with its CFs 0-3) the tool might establish
the mapping

  =====  ======  ====
  SCFID    CIID  CFID
  =====  ======  ====
      0  CI-123     0
      2  CI-123     2
      4  CI-123     4
      5  CI-456     0
      6  CI-456     1
      8  CI-456     3
  =====  ======  ====
  
or

  =====  ======  ====
  SCFID    CIID  CFID
  =====  ======  ====
      0  CI-123     0
      2  CI-123     2
      4  CI-123     4
      8  CI-456     0
      9  CI-456     1
     11  CI-456     3
  =====  ======  ====

or

  =====  ======  ====
  SCFID    CIID  CFID
  =====  ======  ====
      0  CI-123     0
      1  CI-123     2
      2  CI-123     4
      3  CI-456     0
      4  CI-456     1
      5  CI-456     3
  =====  ======  ====

or other encodings TBD.

The tool maps custom function invocations in the software to SCFID
invocations in the compiled object code.

The resulting compiled and linked binary is hard-wired to this assignment
of SCFIDs and therefore can only be run on the specific custom SoC.

  Yes, this is a significant shortcoming of this approach.

In one model, the CI-aware software is distributed in source and recompiled
after the CFID to SCFID mapping is determined.

In another model, the CI-aware software may also be a compiled binary with
relocations (fixups) to CI.CFID symbols. At link time the CI.CFID relocations
are resolved to SCFIDs written to the correct fields of the CIs.

At execution time, a hardware CPU-CFU shim will map the SCFID invocation
into an invocation of some CFU with some CI-scoped CFID.

For example, here if CFU Software uses CI-456.CF-1, the tool maps this into
invocation of SCFID 6 in the compiled object code. Then at execution time,
a hardware CPU-CFU shim maps SCFID 6 into an invocation of the CFU that
implements CI-456, with CFID=1.

  As an alternative to the composition and opcode assignment system
  described above, it may be possible to define a single *custom
  instruction* instruction whose operands include not only the data
  operands but also a globally unique CIID.


.. toctree::
   :maxdepth: 2
   :caption: Contents:

   logic-itf
