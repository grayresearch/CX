// cxu_li.svh: CXU-LI package
//
// Copyright (C) 2019-2023, Gray Research LLC.
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

`ifndef CXU_SVH
`define CXU_SVH

`include "common.svh"

// Macros to abstract CXU-LI parameters, param checks, ports, port maps

`define CXU_L0_PARAMS(n_cxus,func_id_w,data_w)              \
    parameter int CXU_LI_VERSION    = 'h01_00_00,           \
    parameter int CXU_N_CXUS        = n_cxus,               \
    parameter int CXU_CXU_ID_W      = $clog2(CXU_N_CXUS),   \
    parameter int CXU_FUNC_ID_W     = func_id_w,            \
    parameter int CXU_DATA_W        = data_w

`define CXU_L1_PARAMS(n_cxus,n_states,latency,reset_latency,func_id_w,data_w) \
    parameter int CXU_LI_VERSION    = 'h01_00_00,           \
    parameter int CXU_N_CXUS        = n_cxus,               \
    parameter int CXU_N_STATES      = n_states,             \
    parameter int CXU_LATENCY       = latency,              \
    parameter int CXU_RESET_LATENCY = reset_latency,        \
    parameter int CXU_CXU_ID_W      = $clog2(CXU_N_CXUS),   \
    parameter int CXU_STATE_ID_W    = $clog2(CXU_N_STATES), \
    parameter int CXU_FUNC_ID_W     = func_id_w,            \
    parameter int CXU_DATA_W        = data_w

`define CXU_L2_PARAMS(n_cxus,n_states,func_id_w,insn_w,data_w) \
    parameter int CXU_LI_VERSION    = 'h01_00_00,           \
    parameter int CXU_N_CXUS        = n_cxus,               \
    parameter int CXU_N_STATES      = n_states,             \
    parameter int CXU_CXU_ID_W      = $clog2(CXU_N_CXUS),   \
    parameter int CXU_STATE_ID_W    = $clog2(CXU_N_STATES), \
    parameter int CXU_FUNC_ID_W     = func_id_w,            \
    parameter int CXU_INSN_W        = insn_w,               \
    parameter int CXU_DATA_W        = data_w

`define CXU_L3_PARAMS(n_cxus,n_states,req_id_w,func_id_w,insn_w,data_w) \
    parameter int CXU_LI_VERSION    = 'h01_00_00,           \
    parameter int CXU_N_CXUS        = n_cxus,               \
    parameter int CXU_N_STATES      = n_states,             \
    parameter int CXU_REQ_ID_W      = req_id_w,             \
    parameter int CXU_CXU_ID_W      = $clog2(CXU_N_CXUS),   \
    parameter int CXU_STATE_ID_W    = $clog2(CXU_N_STATES), \
    parameter int CXU_FUNC_ID_W     = func_id_w,            \
    parameter int CXU_INSN_W        = insn_w,               \
    parameter int CXU_DATA_W        = data_w

`define CHECK_CXU_L0_PARAMS \
    check_cxu_l0_params(CXU_LI_VERSION, CXU_N_CXUS, CXU_CXU_ID_W, CXU_FUNC_ID_W, CXU_DATA_W)

`define CHECK_CXU_L1_PARAMS \
    check_cxu_l1_params(CXU_LI_VERSION, CXU_N_CXUS, CXU_LATENCY, CXU_RESET_LATENCY, \
        CXU_CXU_ID_W, CXU_STATE_ID_W, CXU_FUNC_ID_W, CXU_DATA_W)

`define CHECK_CXU_L2_PARAMS \
    check_cxu_l2_params(CXU_LI_VERSION, CXU_N_CXUS, CXU_CXU_ID_W, CXU_STATE_ID_W, \
        CXU_FUNC_ID_W, CXU_INSN_W, CXU_DATA_W)

`define CXU_L0_PARAMS_MAP               \
    .CXU_LI_VERSION(CXU_LI_VERSION),    \
    .CXU_N_CXUS(CXU_N_CXUS),            \
    .CXU_CXU_ID_W(CXU_CXU_ID_W),        \
    .CXU_FUNC_ID_W(CXU_FUNC_ID_W),      \
    .CXU_DATA_W(CXU_DATA_W)

`define CXU_L1_PARAMS_MAP               \
    .CXU_LI_VERSION(CXU_LI_VERSION),    \
    .CXU_N_CXUS(CXU_N_CXUS),            \
    .CXU_N_STATES(CXU_N_STATES),        \
    .CXU_CXU_ID_W(CXU_CXU_ID_W),        \
    .CXU_STATE_ID_W(CXU_STATE_ID_W),    \
    .CXU_FUNC_ID_W(CXU_FUNC_ID_W),      \
    .CXU_DATA_W(CXU_DATA_W)

`define CXU_L2_PARAMS_MAP               \
    .CXU_LI_VERSION(CXU_LI_VERSION),    \
    .CXU_N_CXUS(CXU_N_CXUS),            \
    .CXU_N_STATES(CXU_N_STATES),        \
    .CXU_CXU_ID_W(CXU_CXU_ID_W),        \
    .CXU_STATE_ID_W(CXU_STATE_ID_W),    \
    .CXU_FUNC_ID_W(CXU_FUNC_ID_W),      \
    .CXU_INSN_W(CXU_INSN_W),            \
    .CXU_DATA_W(CXU_DATA_W)

`define CXU_CLOCK_PORTS                         \
    input  logic                clk,            \
    input  logic                rst,            \
    input  logic                clk_en

`define CXU_L0_PORTS(input,output,req,resp)     \
    input  logic                req``_valid,    \
    input  `V(CXU_CXU_ID_W)     req``_cxu,      \
    input  `V(CXU_FUNC_ID_W)    req``_func,     \
    input  `V(CXU_DATA_W)       req``_data0,    \
    input  `V(CXU_DATA_W)       req``_data1,    \
    output cxu_status_t         resp``_status,  \
    output `V(CXU_DATA_W)       resp``_data

`define CXU_L1_PORTS(input,output,req,resp)     \
    input  logic                req``_valid,    \
    input  `V(CXU_CXU_ID_W)     req``_cxu,      \
    input  `V(CXU_STATE_ID_W)   req``_state,    \
    input  `V(CXU_FUNC_ID_W)    req``_func,     \
    input  `V(CXU_DATA_W)       req``_data0,    \
    input  `V(CXU_DATA_W)       req``_data1,    \
    output logic                resp``_valid,   \
    output cxu_status_t         resp``_status,  \
    output `V(CXU_DATA_W)       resp``_data

`define CXU_L2_PORTS(input,output,req,resp)     \
    input  logic                req``_valid,    \
    output logic                req``_ready,    \
    input  `V(CXU_CXU_ID_W)     req``_cxu,      \
    input  `V(CXU_STATE_ID_W)   req``_state,    \
    input  `V(CXU_FUNC_ID_W)    req``_func,     \
    input  `V(CXU_INSN_W)       req``_insn,     \
    input  `V(CXU_DATA_W)       req``_data0,    \
    input  `V(CXU_DATA_W)       req``_data1,    \
    output logic                resp``_valid,   \
    input  logic                resp``_ready,   \
    output cxu_status_t         resp``_status,  \
    output `V(CXU_DATA_W)       resp``_data

`define CXU_L3_PORTS(input,output,req,resp)     \
    input  logic                req``_valid,    \
    output logic                req``_ready,    \
    input  `V(CXU_REQ_ID_W)     req``_id,       \
    input  `V(CXU_CXU_ID_W)     req``_cxu,      \
    input  `V(CXU_STATE_ID_W)   req``_state,    \
    input  `V(CXU_FUNC_ID_W)    req``_func,     \
    input  `V(CXU_INSN_W)       req``_insn,     \
    input  `V(CXU_DATA_W)       req``_data0,    \
    input  `V(CXU_DATA_W)       req``_data1,    \
    output logic                resp``_valid,   \
    input  logic                resp``_ready,   \
    output `V(CXU_REQ_ID_W)     resp``_id,      \
    output cxu_status_t         resp``_status,  \
    output `V(CXU_DATA_W)       resp``_data

`define CXU_CLK_L1_PORTS(input,output,req,resp) \
    `CXU_CLOCK_PORTS,                           \
    `CXU_L1_PORTS(input,output,req,resp)

`define CXU_CLK_L2_PORTS(input,output,req,resp) \
    `CXU_CLOCK_PORTS,                           \
    `CXU_L2_PORTS(input,output,req,resp)

`define CXU_CLK_L3_PORTS(input,output,req,resp) \
    `CXU_CLOCK_PORTS,                           \
    `CXU_L3_PORTS(input,output,req,resp)

`define CXU_CLK_PORT_MAP \
    .clk(clk), .rst(rst), .clk_en(clk_en)

`define CXU_L0_PORT_MAP(to_req,from_req, to_resp,from_resp) \
    .to_req``_valid  (from_req``_valid),    \
    .to_req``_cxu    (from_req``_cxu),      \
    .to_req``_func   (from_req``_func),     \
    .to_req``_data0  (from_req``_data0),    \
    .to_req``_data1  (from_req``_data1),    \
    .to_resp``_status(from_resp``_status),  \
    .to_resp``_data  (from_resp``_data)
 
`define CXU_L1_PORT_MAP(to_req,from_req, to_resp,from_resp) \
    .to_req``_valid  (from_req``_valid),    \
    .to_req``_cxu    (from_req``_cxu),      \
    .to_req``_state  (from_req``_state),    \
    .to_req``_func   (from_req``_func),     \
    .to_req``_data0  (from_req``_data0),    \
    .to_req``_data1  (from_req``_data1),    \
    .to_resp``_valid (from_resp``_valid),   \
    .to_resp``_status(from_resp``_status),  \
    .to_resp``_data  (from_resp``_data)
 
`define CXU_L2_PORT_MAP(to_req,from_req, to_resp,from_resp) \
    .to_req``_valid  (from_req``_valid),    \
    .to_req``_ready  (from_req``_ready),    \
    .to_req``_cxu    (from_req``_cxu),      \
    .to_req``_state  (from_req``_state),    \
    .to_req``_func   (from_req``_func),     \
    .to_req``_insn   (from_req``_insn),     \
    .to_req``_data0  (from_req``_data0),    \
    .to_req``_data1  (from_req``_data1),    \
    .to_resp``_valid (from_resp``_valid),   \
    .to_resp``_ready (from_resp``_ready),   \
    .to_resp``_status(from_resp``_status),  \
    .to_resp``_data  (from_resp``_data)

`define CXU_CLK_L1_PORT_MAP(to_req,from_req, to_resp,from_resp) \
    `CXU_CLK_PORT_MAP, `CXU_L1_PORT_MAP(to_req,from_req, to_resp,from_resp)

`define CXU_CLK_L2_PORT_MAP(to_req,from_req, to_resp,from_resp) \
    `CXU_CLK_PORT_MAP, `CXU_L2_PORT_MAP(to_req,from_req, to_resp,from_resp)

`define CXU_L0_NETS(req,resp)               \
    logic                req``_valid;       \
    `V(CXU_CXU_ID_W)     req``_cxu;         \
    `V(CXU_FUNC_ID_W)    req``_func;        \
    `V(CXU_DATA_W)       req``_data0;       \
    `V(CXU_DATA_W)       req``_data1;       \
    cxu_status_t         resp``_status;     \
    `V(CXU_DATA_W)       resp``_data

`define CXU_L1_NETS(req,resp)               \
    `CXU_L0_NETS(req,resp);                 \
    `V(CXU_STATE_ID_W)  req``_state;        \
    logic               resp``_valid

`define CXU_L2_NETS(req,resp)               \
    `CXU_L1_NETS(req,resp);                 \
    logic               req``_ready;        \
    `V(CXU_INSN_W)      req``_insn;         \
    logic               resp``_ready

package cxu_pkg;

import common_pkg::*;

function bit check_cxu_l0_params(int version, int n_cxus, int cxu_w, int func_w, int data_w);
    return check_param("CXU_LI_VERSION", version, 'h01_00_00)
        && check_param_pos("CXU_N_CXUS", n_cxus)
        && check_param_range("CXU_CXU_ID_W", cxu_w, 0, 16)
        && check_param_range("CXU_FUNC_ID_W", func_w, 0, 10)
        && check_param_2("CXU_DATA_ID_W", data_w, 32, 64);
endfunction

function bit check_cxu_l1_params(
    int version, int n_cxus, int latency, int reset_latency, int cxu_w,
    int state_w, int func_w, int data_w
);
    return check_param("CXU_LI_VERSION", version, 'h01_00_00)
        && check_param_pos("CXU_N_CXUS", n_cxus)
        // check_param CXU_N_STATES in each CXU
        && check_param_nonneg("CXU_LATENCY", latency)
        && check_param_nonneg("CXU_RESET_LATENCY", reset_latency)
        && check_param_range("CXU_CXU_ID_W", cxu_w, 0, 16)
        && check_param_range("CXU_STATE_ID_W", state_w, 0, 16)
        && check_param_range("CXU_FUNC_ID_W", func_w, 0, 10)
        && check_param_2("CXU_DATA_ID_W", data_w, 32, 64);
endfunction

function bit check_cxu_l2_params(int version, int n_cxus, int cxu_w, int state_w, int func_w, int insn_w, int data_w);
    return check_param("CXU_LI_VERSION", version, 'h01_00_00)
        && check_param_pos("CXU_N_CXUS", n_cxus)
        // check_param CXU_N_STATES in each CXU
        && check_param_range("CXU_CXU_ID_W", cxu_w, 0, 16)
        && check_param_range("CXU_STATE_ID_W", state_w, 0, 16)
        && check_param_range("CXU_FUNC_ID_W", func_w, 0, 10)
        && check_param_2("CXU_INSN_W", insn_w, 0, 32)
        && check_param_2("CXU_DATA_ID_W", data_w, 32, 64);
endfunction

function bit check_cxu_l3_params(int version, int n_cxus, int cxu_w, int state_w, int func_w, int insn_w, int data_w);
    return check_cxu_l2_params(version, n_cxus, cxu_w, state_w, func_w, insn_w, data_w);
endfunction


parameter int CXU_STATUS_W  = 3;

typedef enum logic [CXU_STATUS_W-1:0] {
    CXU_OK,                         // OK: no errors
    CXU_ERROR_CXU,                  // error: invalid CXU_ID
    CXU_ERROR_OFF,                  // error: (stateful interface) is off
    CXU_ERROR_STATE,                // error: invalid STATE_ID
    CXU_ERROR_FUNC,                 // error: invalid CF_ID
    CXU_ERROR_OP,                   // error: invalid operation or operands
    CXU_ERROR_CUSTOM                // error: (stateful interface) custom error
} cxu_status_t;                     // CXU response status

typedef enum logic [1:0] {
    CXU_OFF,                        // context off: any use is an error
    CXU_INIT,                       // context on, reset to zero
    CXU_CLEAN,                      // context hasn't changed since last context save
    CXU_DIRTY                       // context has changed
} cxu_cs_e;                         // stateful CXU "CS" context status

typedef logic [1:0] cxu_cs_t;       // mitigate iverilog shortcoming, can't cast to enum (?)

typedef struct packed {
    `V(8)       error;              // custom error status
    `V(12)      reserved;           // reserved, writes ignored, reads as zero
    `V(10)      state_size;         // state context size in words
    cxu_cs_t    cs;                 // context "CS" status
} cxu_csw_t;                        // stateful CXU interface state context status word

typedef enum logic [9:0] {
    cfid_read_status    = 1023,     // read interface state context status word
    cfid_write_status   = 1022,     // write interface state context status word
    cfid_read_state     = 1021,     // read one word of current state context
    cfid_write_state    = 1020      // write one word of current state context
} cfid_t;                           // stateful CXU standard custom function IDs

endpackage : cxu_pkg
`endif
