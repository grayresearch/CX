// switch_cfu_core.sv: connect initiators to target CFUs (CFU-L2)
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

`include "common.svh"
`include "cfu.svh"

/* verilator lint_off DECLFILENAME */

// switch_cfu_core: connect initiators to target CFUs (CFU-L2),
// wherein each port is a vector of the corresponding initiator or target CFU port signals
module switch_cfu_core
    import common_pkg::*;
    import cfu_pkg::*;
#(
    `CFU_L2_PARAMS(/*N_CFUS*/1, /*N_STATES*/1, /*FUNC_ID_W*/10, /*INSN_W*/0, /*DATA_W*/32),
    parameter int N_INIS    = 1,            // no. of initiators
    parameter int N_TGTS    = CFU_N_CFUS,   // no. of targets
    parameter int N_REQS    = 16            // max no. of in-flight requests per initiator or target
) (
    input  logic                        clk,
    input  logic                        rst,
    input  logic                        clk_en,

    input  `V(N_INIS)                   i_req_valids,
    output `V(N_INIS)                   i_req_readys,
    input  `NV(N_INIS, CFU_CFU_ID_W)    i_req_cfus,
    input  `NV(N_INIS, CFU_STATE_ID_W)  i_req_states,
    input  `NV(N_INIS, CFU_FUNC_ID_W)   i_req_funcs,
    input  `NV(N_INIS, CFU_INSN_W)      i_req_insns,
    input  `NV(N_INIS, CFU_DATA_W)      i_req_data0s,
    input  `NV(N_INIS, CFU_DATA_W)      i_req_data1s,
    output `V(N_INIS)                   i_resp_valids,
    input  `V(N_INIS)                   i_resp_readys,
    output `NV(N_INIS, CFU_STATUS_W)    i_resp_statuss,
    output `NV(N_INIS, CFU_DATA_W)      i_resp_datas,

    output `V(N_TGTS)                   t_req_valids,
    input  `V(N_TGTS)                   t_req_readys,
    output `NV(N_TGTS, CFU_CFU_ID_W)    t_req_cfus,
    output `NV(N_TGTS, CFU_STATE_ID_W)  t_req_states,
    output `NV(N_TGTS, CFU_FUNC_ID_W)   t_req_funcs,
    output `NV(N_TGTS, CFU_INSN_W)      t_req_insns,
    output `NV(N_TGTS, CFU_DATA_W)      t_req_data0s,
    output `NV(N_TGTS, CFU_DATA_W)      t_req_data1s,
    input  `V(N_TGTS)                   t_resp_valids,
    output `V(N_TGTS)                   t_resp_readys,
    input  `NV(N_TGTS, CFU_STATUS_W)    t_resp_statuss,
    input  `NV(N_TGTS, CFU_DATA_W)      t_resp_datas
);
    initial ignore(
        check_cfu_l2_params("switch_cfu_core", CFU_LI_VERSION, CFU_N_CFUS,
            CFU_CFU_ID_W, CFU_STATE_ID_W, CFU_FUNC_ID_W, CFU_INSN_W, CFU_DATA_W)
    &&  check_param("switch_cfu_core", "CFU_FUNC_ID_W", CFU_FUNC_ID_W, $bits(cfid_t))
    &&  check_param_pos("switch_cfu_core", "N_INIS", N_INIS)
    &&  check_param_pos("switch_cfu_core", "N_TGTS", N_TGTS));
`ifdef SWITCH_CFU_CORE_VCD
    initial begin $dumpfile("switch_cfu_core.vcd"); $dumpvars(0, switch_cfu_core); end
`endif

    localparam int INI_W        = $clog2(N_INIS);
    localparam int TGT_W        = $clog2(N_TGTS);
    localparam int N_REQS_W     = $clog2(N_REQS);
    typedef `V(CFU_CFU_ID_W)    cfu_id_t;
    typedef `V(N_INIS)          ini_mask_t;
    typedef `V(INI_W)           ini_t;
    typedef `V(TGT_W)           tgt_t;
    typedef `V(N_REQS_W)        n_req_t;

    // Initiator -> target state, and new initiator request eligibility:
    // To ensure initiator responses are sent in order of initiator requests,
    // * despite initiators interleaving requests to diverse targets, and
    // * despite targets receiving interleaved requests from diverse initiators, and
    // * despite targets having diverse and variable latencies, define eligiblity as:
    // a valid initiator request is _eligible_ to transfer to a target request port if the
    // initiator has no pending (awaiting response) request upon any *other* target, and it
    // has not already issued "too many" pending requests upon the target.

    // state
    `NV(N_INIS, N_REQS_W)   i_n_reqs;   // initators' #s of requests in flight
    `NV(N_INIS, TGT_W)      i_tgts;     // initiators' latest targets
    `NV(N_TGTS, INI_W)      t_inis;     // targets' latest initiators

    function bit i_eligible(input int i, input int t);
        return (i_n_reqs[i] == n_req_t'(0)) || ((i_n_reqs[i] != n_req_t'(N_REQS-1)) && (i_tgts[i] == tgt_t'(t)));
    endfunction

    // comb
    `V(N_TGTS)          t_xfers;        // targets' request transfer enables
    `V(N_INIS)          i_xfers;        // initiators' response transfer enables
    `NV(N_TGTS, INI_W)  t_inis_nxt;     // targets' next initiators
    `NV(N_INIS, TGT_W)  i_tgts_nxt;     // initiators' next targets

    // valid-ready handshakes
    `V(N_INIS)          i_req_hss;      // initiators' request  handshakes
    `V(N_INIS)          i_resp_hss;     // initiators' response handshakes
    `V(N_TGTS)          t_req_hss;      // targets'    request  handshakes
    `V(N_TGTS)          t_resp_hss;     // targets'    response handshakes
    `V(N_INIS)          i_resp_avails;  // initiators' response availables
    `V(N_TGTS)          t_req_avails;   // targets'    request  availables
    always_comb begin
        i_req_hss     =  i_req_valids  & i_req_readys;
        i_resp_hss    =  i_resp_valids & i_resp_readys;
        t_req_hss     =  t_req_valids  & t_req_readys;
        t_resp_hss    =  t_resp_valids & t_resp_readys;
        i_resp_avails = ~i_resp_valids | i_resp_readys;
        t_req_avails  = ~t_req_valids  | t_req_readys;
    end

    // maintain initiator -> (target, #-reqs) state
    always_ff @(posedge clk) begin
        if (rst) begin
            i_n_reqs <= '0;
            i_tgts   <= '0;
        end
        else if (clk_en) begin
            for (int i = 0; i < N_INIS; ++i) begin
                if (i_req_hss[i] != i_resp_hss[i])
                    i_n_reqs[i] <= i_req_hss[i] ? (i_n_reqs[i] + 1'b1) : (i_n_reqs[i] - 1'b1);
                if (i_req_hss[i])
                    i_tgts[i] <= i_tgts_nxt[i];
            end
        end
    end

    // when multiple initiators may interleave requests to the same target, a per-target
    // initiatiator ID queue maps target responses back to their corresponding initiators
    `V(N_TGTS)              t_readys;   // which targets' queues have room for new requests?
    `V(N_INIS)              i_matchs;   // which initiators' targets's response is for that initiator?
    if (N_INIS > 1) begin : plural
        `V(N_TGTS)          valids;
        `NV(N_TGTS, INI_W)  heads;

        for (genvar t = 0; t < N_TGTS; ++t) begin : qs
            queue #(.W(INI_W), .N(N_REQS))
            q(.clk, .rst, .clk_en, .i_v(t_req_hss[t]), .i_rdy(t_readys[t]), .i(t_inis[t]),
              .o_v(valids[t]), .o_rdy(t_resp_hss[t]), .o(heads[t]));
        end
        always_comb begin
            for (int i = 0; i < N_INIS; ++i)
                i_matchs[i] = valids[i_tgts[i]] && heads[i_tgts[i]] == i;
        end
    end
    else begin
        assign t_readys = '1;
        assign i_matchs = '1;
    end

    // round robin priority encode first set bit in {vector[last+1..W-1],vector[0..last]}
    function ini_t i_pri_enc(input ini_mask_t vector, input ini_t last);
        for (int pass = 0; pass < 2; ++pass)
            for (int i = 0; i < N_INIS; ++i)
                if (((i > last) || pass == 1) && vector[i])
                    return ini_t'(i);
        return ini_t'(0);
    endfunction

    // downstream: arbitrate initiator requests for target request ports
    always_comb begin
        i_req_readys = '0;
        t_xfers      = '0;
        t_inis_nxt   = '0;
        i_tgts_nxt   = '0;

        // for each available target request port, use fair (round-robin) arbitration to
        // select a valid eligible initiator request destined for that port
        for (int t = 0; t < N_TGTS; ++t) begin
            ini_mask_t  i_req_mask;
            ini_t       ini;

            i_req_mask = '0;
            // determine which valid eligible initiators want to send a request to this target
            for (int i = 0; i < N_INIS; ++i)
                if (i_req_valids[i] && i_req_cfus[i] == cfu_id_t'(t) && i_eligible(i, t))
                    i_req_mask[i] = 1;
            ini = i_pri_enc(i_req_mask, t_inis[t]);
            if (i_req_mask != 0 && t_req_avails[t] && t_readys[t]) begin
                t_xfers[t] = 1;
                i_req_readys[ini] = 1;
                t_inis_nxt[t] = ini;
                i_tgts_nxt[ini] = tgt_t'(t);
            end
        end
    end
    // downstream: send arbitrated initiator requests to target request ports
    always_ff @(posedge clk) begin
        if (rst) begin
            t_inis       <= '0;
            t_req_valids <= '0;         // necessary
            t_req_cfus   <= '0;         // rest optional
            t_req_states <= '0;
            t_req_funcs  <= '0;
            t_req_insns  <= '0;
            t_req_data0s <= '0;
            t_req_data1s <= '0;
        end
        else if (clk_en) begin
            for (int t = 0; t < N_TGTS; ++t) begin
                if (t_xfers[t]) begin
                    // transfer initiator request to target output port
                    t_inis[t]       <= ini_t'(t_inis_nxt[t]);
                    t_req_valids[t] <= 1;
                    t_req_cfus[t]   <= '0; // remap to singleton leaf CFU (FIXME)
                    t_req_states[t] <= i_req_states[t_inis_nxt[t]];
                    t_req_funcs[t]  <= i_req_funcs [t_inis_nxt[t]];
                    t_req_insns[t]  <= i_req_insns [t_inis_nxt[t]];
                    t_req_data0s[t] <= i_req_data0s[t_inis_nxt[t]];
                    t_req_data1s[t] <= i_req_data1s[t_inis_nxt[t]];
                end
                else if (t_req_readys[t]) begin
                    t_req_valids[t] <= 0;
                end
            end
        end
    end

    // upstream: send ready target responses to available initiator response ports
    always_comb begin
        i_xfers = '0;
        t_resp_readys = '0;
        for (int i = 0; i < N_INIS; ++i) begin
            // accept valid target response if initiator is available and the current
            // response is for this initiator
            if (i_resp_avails[i] && i_matchs[i] && t_resp_valids[i_tgts[i]]) begin
                i_xfers[i] = 1;
                t_resp_readys[i_tgts[i]] = 1;
            end
        end
    end
    always_ff @(posedge clk) begin
        if (rst) begin
            i_resp_valids  <= '0;       // necessary
            i_resp_statuss <= '0;       // rest optional
            i_resp_datas   <= '0;
        end
        else if (clk_en) begin
            for (int i = 0; i < N_INIS; ++i) begin
                if (i_xfers[i]) begin
                    i_resp_valids[i]  <= 1;
                    i_resp_statuss[i] <= t_resp_statuss[i_tgts[i]];
                    i_resp_datas[i]   <= t_resp_datas[i_tgts[i]];
                end
                else if (i_resp_readys[i])
                    i_resp_valids[i] <= 0;
            end
        end
    end
endmodule
