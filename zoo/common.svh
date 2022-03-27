// common.svh: Common package
//
// Copyright (C) 2019-2022, Gray Research LLC.
// 
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// 
//    http://www.apache.org/licenses/LICENSE-2.0
// 
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

//////////////////////////////////////////////////////////////////////////////
// Naming conventions:
// AB_CD    // parameter, localparam, enum
// Ab_cd    // preferred parameter, localparam, enum
//  N       // no. of instances, ports, ...
//  x_w     // x width, in bits
//  x_sz    // x size, in bytes
//  x_dly   // x delay (fixed latency), in cycles
// ab_cd    // package, module definition, module instance, field, signal
//  x_      // module instance with main output x
//  x_pkg   // package
//  x_e     // enum type name
//  x_t     // type name
//  x_id    // index or identifier of x, when there is also an x value
//  x_rdy   // ready for x
//  x_v     // x is valid
//  x_hs    // x handshake (x_rdy && x_v)
//  x_nxt   // x is valid in next cycle

`ifndef COMMON_SVH
`define COMMON_SVH

`resetall
`timescale 1ns/1ps
`default_nettype none

`define vp /* verilator public */

`define V(W)    logic [msb(W):0]            /* parameteric width bit vector constructor */
`define NV(N,W) logic [(N)-1:0][msb(W):0]   /* parameteric width packed vector of bit vector constructor */

/* verilator lint_off DECLFILENAME */

package common_pkg;

function int min(int a, int b);
    min = (a <= b) ? a : b;
endfunction

function int max(int a, int b);
    max = (a >= b) ? a : b;
endfunction

// Return the non-negative index of the most significant bit of a bus.
// In particular, [msb(0):0] => [0:0].
function int msb(int width);
    msb = max(width-1, 0);
endfunction

// parameter checking help

function bit check_param(string name, string param_name, int actual, int required);
    check_param = (actual == required);
    if (!check_param)
        $error("%s: parameter %s=%1d, must be %1d", name, param_name, actual, required);
endfunction

function bit check_param_range( string name, string param_name, int actual, int low, int high);
    check_param_range = (low <= actual && actual <= high);
    if (!check_param_range)
        $error("%s: parameter %s=%1d, must be in [%1d,%1d]", name, param_name, actual, low, high);
endfunction

function bit check_param_2(string name, string param_name, int actual, int req0, int req1);
    check_param_2 = (actual == req0 || actual == req1);
    if (!check_param_2)
        $error("%s: parameter %s=%1d, must be %1d or %1d", name, param_name, actual, req0, req1);
endfunction

function bit check_param_expr(string name, string param_name, int actual, bit expr, string required);
    check_param_expr = expr;
    if (!check_param_expr)
        $error("%s: parameter %s=%1d, %s", name, param_name, actual, required);
endfunction

function bit check_param_pos(string name, string param_name, int actual);
    check_param_pos = actual > 0;
    if (!check_param_pos)
        $error("%s: parameter %s=%1d, must be positive", name, param_name, actual);
endfunction

function bit check_param_pos2exp(string name, string param_name, int actual);
    check_param_pos2exp = (actual > 0) && (2**$clog2(actual) == actual);
    if (!check_param_pos2exp)
        $error("%s: parameter %s=%1d, must be positive power of two", name, param_name, actual);
endfunction

function bit check_param_nonneg(string name, string param_name, int actual);
    check_param_nonneg = actual >= 0;
    if (!check_param_nonneg)
        $error("%s: parameter %s=%1d, must be nonnegative", name, param_name, actual);
endfunction

task ignore(bit _);
endtask

endpackage

`endif // !COMMON_SVH
