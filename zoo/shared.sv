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
                if (rst)
                    qs[i] <= '0;
                else if (clk_en)
                    qs[i] <= (i == 0) ? d : qs[i-1];
            end
        end
        always_comb q = qs[N-1];
    end
endmodule


// queue:
//  * with valid-ready handshake on enqueue and dequeue
//  * with items in dual-port async LUT-RAM
//  * outputs current queue head value -- this LUT-RAM output is not registered
//  * zero latency: item is output immediately following posedge clk that enqueues it into
//    an empty queue
module queue
    import common_pkg::*;
#(
    parameter int W = 1,
    parameter int N = 1
) (
    input  logic            clk,
    input  logic            rst,
    input  logic            clk_en,
    input  logic            i_v,
    output logic            i_rdy,
    input  logic [W-1:0]    i,
    output logic            o_v,
    input  logic            o_rdy,
    output logic [W-1:0]    o
);
    initial ignore(
        check_param_pos("W", W)
    &&  check_param_pos2exp("N", N));

    typedef logic [$clog2(N)-1:0] ad_t;
    typedef logic [$clog2(N)-1:0] data_t;

    // state
    (* ram_style="distributed" *)
    data_t  ram[N];
    ad_t     rd_ad;         // read from here
    ad_t     wr_ad;         // write to here

    // comb
    ad_t     wr_ad_inc;     // wrap(wr_ad + 1)

    always_comb begin
        wr_ad_inc = wr_ad + 1'b1;
        i_rdy = !(wr_ad_inc == rd_ad);  // queue is not full (full ::= inc(wr_ad) == rd_ad)
        o_v = !(wr_ad == rd_ad);        // queue is not empty (empty ::= wr_ad == rd_ad)
        o = ram[rd_ad];
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            rd_ad <= 0;
            wr_ad <= 0;
        end
        else if (clk_en) begin
            if (i_v && i_rdy) begin
                ram[wr_ad] <= i;
                wr_ad <= wr_ad_inc;
            end
            if (o_v && o_rdy)
                rd_ad <= rd_ad + 1'b1;
        end
    end
endmodule
