// shared.sv: shared modules
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

`include "cfu.svh"

/* verilator lint_off DECLFILENAME */

module shift_reg
    import common_pkg::*;
#(
    parameter int W = 1,
    parameter int N = 1
) (
    input  logic            clk,
    input  logic            rst,
    input  logic            clk_en,
    input  logic [W-1:0]    d,
    output logic [W-1:0]    q
);
    initial ignore(
        check_param_pos("W", W)
    &&  check_param_nonneg("N", N));

    if (N == 0)
        always_comb q = d;
    else begin
        logic [N-1:0][W-1:0] qs;
        always_ff @(posedge clk) begin
            for (int i = 0; i < N; ++i) begin
                if (clk_en)
                    qs[i] <= (i == 0) ? d : qs[i-1];
            end
        end
        always_comb q = qs[N-1];
    end
endmodule


// queue:
//  * with valid-ready handshake on enqueue and dequeue
//  * with items in one register or a dual-port async LUT-RAM
//  * zero latency: item is output immediately following posedge clk that
//    enqueues it in an empty fifo
module queue
    import common_pkg::*;
#(
    parameter int W = 1,
    parameter int N = 1
) (
    input  logic    clk,
    input  logic    rst,
    input  logic    clk_en,
    input  logic    i_valid,
    output logic    i_ready,    // comb (forwards o_ready)
    input  `V(W)    i,
    output logic    o_valid,    // reg
    input  logic    o_ready,
    output `V(W)    o
);
    initial ignore(
        check_param_pos("W", W)
    &&  check_param_pos2exp("N", N));

    if (N == 1) begin : q1      // simple stream register
        always_comb i_ready = !o_valid || o_ready; // forwards o_ready
        always_ff @(posedge clk) begin
            if (rst) begin
                o_valid <= 0;
            end else if (clk_en) begin
                if (i_valid && i_ready) begin
                    o_valid <= 1;
                    o <= i;
                end else if (o_ready) begin
                    o_valid <= 0;
                end
            end
        end
    end else begin : qn         // N entry FIFO
        // state
        typedef `CNT(N) ad_t;
        //      o_valid         // not empty?
        logic   full;           // full?
        ad_t    rd_ad;          // read  pointer
        ad_t    wr_ad;          // write pointer
        `V(W)   items[N];       // circular FIFO
        // # items = full ? N : (rd_ad != wr_ad) ? [1,N-1] : 0

        // comb
        ad_t    rd_ad_inc;      // incr'd read  pointer
        ad_t    wr_ad_inc;      // incr'd write pointer
        logic   enq;            // enqueue item
        logic   deq;            // dequeue item

        always_comb begin
            i_ready = !full || o_ready; // forwards o_ready
            o = items[rd_ad];

            enq = i_valid && i_ready;
            deq = o_valid && o_ready;
            rd_ad_inc = rd_ad + 1'b1;
            wr_ad_inc = wr_ad + 1'b1;
        end
        always_ff @(posedge clk) begin
            if (rst) begin
                // empty
                full  <= 0;
                rd_ad <= '0;
                wr_ad <= '0;
                o_valid <= 0;
            end
            else if (clk_en) begin
                if (enq) begin
                    items[wr_ad] <= i;
                    wr_ad <= wr_ad_inc;
                end
                if (deq)
                    rd_ad <= rd_ad_inc;
                if (enq != deq) begin
                    full    <= enq && (wr_ad_inc == rd_ad);
                    o_valid <= enq || (rd_ad_inc != wr_ad);
                end
            end
        end
    end
endmodule
