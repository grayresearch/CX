// shared.sv: shared modules
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
    initial begin
        ignore(
            check_param_pos("shift_reg", "W", W)
        &&  check_param_nonneg("shift_reg", "N", N));
    end

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
