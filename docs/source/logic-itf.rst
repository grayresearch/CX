.. cfu-spec documentation master file, created by
   sphinx-quickstart on Fri Nov  1 08:53:46 2019.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.

*********************************
CFU Logic Interface Specification
*********************************


CFU Logic Interface (CFU-LI) Feature Levels
===========================================

The CFU-LI is stratified into four nested, increasingly flexible,
increasingly complex feature levels.  In each case, a CPU submits a CFU
request and eventually receives a CFU respose.  For each request there
is exactly one response.

**LI0**: zero-latency combinational function unit: a CFU which accepts
a request (CFID, request data) and produces a corresponding response
(err/OK, response data) in the same cycle.  Example: combinational
bitcount (population count) unit.

**LI1**: fixed-latency, pipelined, in-order function unit: a CFU
which accepts a request (CFID, request data, request ID) and produces a
corresponding response (err/OK, response data, response ID) in a fixed
number of cycles (may be zero).  The request ID from the CPU is returned
as the response ID from the CFU, and is used by the CPU to correlate the
response to some prior request. Example: pipelined multiplier unit.

**LI2**: arbitrary-latency, possibly pipelined, in-order function unit,
with request/response handshakes: a CFU which accepts a request (CFID,
request data, request ID) and produces a corresponding response (err/OK,
response data, response ID) in zero or more cycles.  The request
signaling has valid/ready handshake so that a CFU may signal it is
unable to accept a request this cycle, and response signaling has a
valid/ready handshake to that a CPU may signal it is unable to accept a
response this cycle. Example: one request-at-a-time, multi-cycle divide
unit with early-out and response handshaking.

**LI3**: arbitrary-latency, possibly pipelined, possibly out-of-order
function unit, with request/response handshakes: a CFU which accepts
a request (CFID, request data, request ID, reorder ID) and produces a
corresponding response (err/OK, response data, response ID) in zero or
more cycles.  The CFU may return responses to requests in a different
order than the requests themselves were received. Example: a combined
pipelined multiply and divide unit, wherein multiply requests are
pipelined and require three cycles and divide requests are one-at-a-time
and require 33 cycles, such that after accepting a divide request and
then a multiply request, it provides the multiply response before the
divide response.

To recap, each feature level introduces new parameters and ports
to the CFU-LI, in particular:

* LI0: adds request (CFID, request data) and response (err/OK, response data).

* LI1: adds request ID/response ID correlation.

* LI2: adds valid/ready request and response handshakes.

* LI3: adds request reorder ID constraint, affording in-/out-of-order response control.

Rationale and use cases
-----------------------

This feature stratification keeps simple things simple and makes
complex things possible. It anticipates and accomodates a diversity
of CPUs that may be composed with CFUs. For example:

* a simple, one instruction at a time, CPU;

* a pipelined CPU;

* an in-order issue, concurrent execution pipelines, out-of-order
  completion CPU;

* a speculating, out-of-order issue CPU;

* a speculating, superscalar, out-of-order CPU;

* a hardware-multithreaded CPU that issues requests and receives
  responses for various interleaved threads; and

* a CPU cluster, of a multiple of the above types of CPU, that share a
  common CFU.

In general, a CPU that implements LI[k] can directly use CFUs that
support LI[k], and can use CFUs for LI[i], i<k, by means of a CFU
shim. For example,

* an LI1(LI0) shim implements LI[1] and encapsulates a LI[0] CFU by
  forwarding the CF request ID as the response ID.

* an LI2(LI1) shim implements LI[2] and encapsulates an LI[1] CFU by
  using pipeline clock enables and/or FIFOs to implement request and
  response handshaking.  the response ID.

The use of request ID/response ID correlation also simplifies CFU sharing
among multiple CPU masters. A CFU multiplexer shim may add additional
source/destination routing data to a request ID so that subsequent
response IDs directly indicate the specific CPU master destination.

TODO
----

TODO: discuss/decide if the above stratification is sufficient. For example,
is it acceptable to bundle request handshake + response handshake into
one feature level, or do we need a **lattice** "no handshake -> req handshake |
resp handshake -> req + resp handshake"?

TODO: Is CIID always a metadata parameter, or in higher CFU-LI
feature levels may it be provided dynamically on a port as part of the
request port signal bundle?  For example, suppose an LI[>=2] CFU core
may implement >1 CI, but when the core is composed into a given SW + HW
system by the system composition tool, it may be (must be?) configured
and specialized to implement one fixed CI.

TODO: For CFUs with internal state (extra arguments, extra results,
accumulators, etc.)  define a standard name and behavior for state reset,
state save/restore, interrogate state elements.

TODO: Decide how to name Custom Interfaces: VLNV, UUID, ...?

TODO: How much of the CFU-LI specification may be specified in IP XACT?

TODO: for LI>=2, is latency bounded? If so is max latency of the CFU
(or individual CFID) provided to the CFU client at system composition
time? Perhaps CFU metadata?
