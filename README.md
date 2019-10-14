Custom Function Unit Specification - Logic Interface Specification
==================================================================
Draft 0.1
WORK IN PROGRESS

Introduction
------------

In the coming winter of Moore's Law, computer system designers will
introduce various types of application-specific custom hardware
accelerators into their systems to boost performance / reduce energy.

A custom function unit (CFU) core is a type of accelerator hardware that
may be tightly coupled into the pipeline of a CPU core, to add new custom
function instructions that complement the CPU's standard functions (such
as arithmetic/logic operations).

The present Custom Function Unit (CFU) Specification is designed to
enable robust composition of independently authored, independently
versioned CPU cores and CFU cores.  This will enable a rich ecosystem
of interoperable, app-optimized CFU cores and their software libraries,
and straightforward development of app-optimized SoCs.

The present CFU Logic Interface (CFU-LI) spec defines the logic interface
between a CPU core and a CFU core.

Scope
-----

The initial CFU Spec focuses upon, and restricts its scope to, those
function units that plug into the integer pipeline of a conventional
microprocessor CPU, just like the traditional two-operand, one-result
arithmetic/logic unit (ALU).

For the purposes and scope of this Spec, a Custom Function Unit is
defined as a hardware core that
* accepts requests and produces responses, wherein:
* requests may comprise a custom function ID and 0-3 request data words;
* responses may comprise a success/error code and 0-2 response data
words or an error ID;
* may be stateless, such that all function invocations are pure functions
and are side-effect free, or
* may be stateful, with private internal state only, such that all
function invocations are side-effect free, except for possibly changing
the CFU's private internal state (only).

Therefore function units that directly access or update system memory,
or architectural state of the CPU, including the CPU's command/status
registers (CSRs), are out of the scope of this specification.

Concepts: Custom Function and Custom Interfaces
-----------------------------------------------

A CFU implements one or more Custom Functions (CFs).

A Custom Function is a function from zero or more request data to zero
or more response data.

A CFU may have state. A CF need not be a pure function. For example,
invoking the same CF multiple times, with the same request data, may
produce different response data.

CFs are bundled into Custom Interfaces (CIs). Custom Interfaces are
inspired by the Interface concept of the Microsoft Component Object
Model (COM), a proven regime for robust arms-length composition of
independently authored, independently versioned software components,
at scale, over time.

CIs are identified by a unique integer CIID. Namespace management of
CIIDs is TBD. (COM uses 128-bit GUIDs.)

CIs provide a namespace for CFs. A CF is identified by a (dense) integer
CFID within a CI.

A Custom Interface is an immutable contract defining a set of CFs, the
behavior of the CFs, and (if applicable) the necessary sequence of custom
function invocations required for correct behavior of the interface.

Any organization may define a CI.

CIs are immutable. To change any aspect of the behavior of a CI, define
a new CI. Implementers and clients of the original CI are not impacted.

Multiple CFUs may implement the same CI.

Compiling a Custom System
-------------------------

In the fullness of time, anticipating decades of customization by
thousands of organizations, over thousands of applications,
it may not be possible to carve up the finite opcode space of
a target ISA into fixed opcode assignments.

A Custom Function Unit Package comprises a CFU Core that implements the
CFU-LI, packaged with CFU Metadata and its CFU Software (source code
and/or binary library archive).

A system composition tool, TBD, compiles the application and libraries,
the CPU and its CFUs, together into an SoC SW + HW design.

The CFU Software and Metadata identify which Custom Functions of which
Custom Interfaces are used by the software. The tool uses this information
to determine the (app-specific) custom target instruction set mapping
required for the application to invoke the CFs.

Each CI specifies some number of CFs: CI.NCF.  The tool maps each CI's
continuous range of CFs into a global CF index (GCFID) appropriate for
the target ISA.

For example, if the app comprises two libraries, the first library uses
functions 0 and 2 of CI-123 (with its CFs 0-4), and the second library
uses functions 1,3 of CI-456 (with its CFs 0-3) the tool might establish
the mapping ```
GCFID  CIID    CFID
0      CI-123  0
1      CI-123  1
2      CI-123  2
3      CI-123  3
4      CI-123  4
5      CI-456  0
6      CI-456  1
7      CI-456  2
8      CI-456  3
```(or some another mapping such as: ```
GCFID  CIID    CFID
 0     CI-123  0
 1     CI-123  1
 2     CI-123  2
 3     CI-123  3
 4     CI-123  4
 8     CI-456  0
 9     CI-456  1
10     CI-456  2
11     CI-456  3
```).

The tool maps custom function invocations in the software to GCFID
invocations in the compiled object code.

At execution time, a hardware CPU-CFU shim will map the GCFID invocation
into an invocation of some CFU with some CI-scoped CFID.

For example, here if CFU Software uses CI-456.1, the tool maps this into
invocation of GCFID 6 in the compiled object code. Then at execution time,
a hardware CPU-CFU shim maps GCFID 6 into an invocation of the CFU that
implements CI-456, with CFID=1.

(IDEA: Rather than do this, supply CIID and CFID values as additional
request data. That is, there is one "invoke custom instruction" opcode
and the rest are 16b or 32b CIIDs and 16b CFIDs)


CFU Logic Interface Service Levels
----

