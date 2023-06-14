// popcount_cfu.sv: 32/64-bit population count CFU-L0 combinational CFU
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

// IPopcount custom functions:
//     *:   popcount

`include "cfu.svh"

/* verilator lint_off DECLFILENAME */

// popcount_cfu: 32/64-bit population count CFU-L0 combinational CFU
module popcount_cfu
    import common_pkg::*, cfu_pkg::*;
#(
    `CFU_L0_PARAMS(/*N_CFUS*/1, /*FUNC_ID_W*/0, /*DATA_W*/32),
    parameter int ADDER_TREE = 0
) (
    `CFU_L0_PORTS(input, output, req, resp)
);
    initial ignore(`CHECK_CFU_L0_PARAMS);
    wire _unused_ok = &{1'b0,req_data1,req_func,req_cfu,req_valid,1'b0};
`ifdef POPCOUNT_CFU_VCD
    initial begin $dumpfile("popcount_cfu.vcd"); $dumpvars(0, popcount_cfu); end
`endif

    if (ADDER_TREE != 0)
        adder_tree #(.W(CFU_DATA_W)) adders(.in(req_data0), .count(resp_data));
    else
        compressors #(.W(CFU_DATA_W)) comps(.in(req_data0), .count(resp_data));
    always_comb resp_status = CFU_OK;
endmodule


// 32/64-bit population count using adder tree
module adder_tree #(
    parameter int W = 32
) (
    input  logic [W-1:0]    in,
    output logic [W-1:0]    count
);
    import common_pkg::*;
    initial ignore(check_param_2("W", W, 32, 64));
    typedef logic [W-1:0] data_t;

    logic [W/ 2-1:0][1:0]  c2;
    logic [W/ 4-1:0][2:0]  c4;
    logic [W/ 8-1:0][3:0]  c8;
    logic [W/16-1:0][4:0] c16;
    logic [W/32-1:0][5:0] c32;
    logic           [6:0] c64;
    int i;

    always_comb begin
        for (i = 0; i < W/2;  ++i)  c2[i] =  in[2*i] +  in[2*i+1];
        for (i = 0; i < W/4;  ++i)  c4[i] =  c2[2*i] +  c2[2*i+1];
        for (i = 0; i < W/8;  ++i)  c8[i] =  c4[2*i] +  c4[2*i+1];
        for (i = 0; i < W/16; ++i) c16[i] =  c8[2*i] +  c8[2*i+1];
        for (i = 0; i < W/32; ++i) c32[i] = c16[2*i] + c16[2*i+1];
        c64 = 0;
        for (i = 0; i < W/32; ++i) c64 += c32[i];
        count = data_t'(c64);
    end
endmodule


// 32/64-bit population count using 6-LUT-friendly 6:3 compressors
//
// Per the blog post "Quick FPGA Hacks: Population count"
// [http://fpga.org/2014/09/05/quick-fpga-hacks-population-count/]
module compressors #(
    parameter int W = 32
) (
    input  logic [W-1:0]    in,
    output logic [W-1:0]    count
);
    import common_pkg::*;
    initial ignore(check_param_2("W", W, 32, 64));

    // 72b popcount regularizes the code for 32b or 64b inputs.
    // Logic optimization trims any constant-0 partial count LUTs.
    typedef logic [W-1:0]   data_t;
    typedef logic [71:0]    _72b;
    typedef logic [6:0]     _7b;
    wire _72b zext = _72b'(in);

    // partial counts
    logic [2:0] a[12];      // 12 3b counts of 6-bit segments of the input
    logic [2:0] b[3][2];    // 3 pairs of bit-position-biased 3-bit counts

    // compress 72b to 12 3b counts
    for (genvar i = 0; i < 72; i=i+6) begin : x
        C63 c(.in(zext[i+5:i]), .count(a[i/6]));
    end

    // sum the 12 bits of the [0], [1], and [2] bit positions separately into
    // 3 pairs of 3-bit counts
    for (genvar i = 0; i < 12; i=i+6) begin : y
        for (genvar j = 0; j < 3; ++j) begin : z
            C63 c(.in({a[i][j],a[i+1][j],a[i+2][j],a[i+3][j],a[i+4][j],a[i+5][j]}),
                  .count(b[j][i/6]));
        end
    end

    // sum the 3 pairs of bit-position-biased counts
    always_comb begin
        count = data_t'(_7b'(
                {3'b0,b[0][0]}      + {3'b0,b[0][1]}
              + {2'b0,b[1][0],1'b0} + {2'b0,b[1][1],1'b0}
              + {1'b0,b[2][0],2'b0} + {1'b0,b[2][1],2'b0}));
    end
endmodule


//////////////////////////////////////////////////////////////////////////////
// 6:3 compressor as a 64x3b ROM -- three 6-LUTs
//
module C63(
    input  logic [5:0] in,
    output logic [2:0] count);    // # of 1's in i

    always_comb begin
        case (in)
        6'h00: count = 0; 6'h01: count = 1; 6'h02: count = 1; 6'h03: count = 2;
        6'h04: count = 1; 6'h05: count = 2; 6'h06: count = 2; 6'h07: count = 3;
        6'h08: count = 1; 6'h09: count = 2; 6'h0A: count = 2; 6'h0B: count = 3;
        6'h0C: count = 2; 6'h0D: count = 3; 6'h0E: count = 3; 6'h0F: count = 4;
        6'h10: count = 1; 6'h11: count = 2; 6'h12: count = 2; 6'h13: count = 3;
        6'h14: count = 2; 6'h15: count = 3; 6'h16: count = 3; 6'h17: count = 4;
        6'h18: count = 2; 6'h19: count = 3; 6'h1A: count = 3; 6'h1B: count = 4;
        6'h1C: count = 3; 6'h1D: count = 4; 6'h1E: count = 4; 6'h1F: count = 5;
        6'h20: count = 1; 6'h21: count = 2; 6'h22: count = 2; 6'h23: count = 3;
        6'h24: count = 2; 6'h25: count = 3; 6'h26: count = 3; 6'h27: count = 4;
        6'h28: count = 2; 6'h29: count = 3; 6'h2A: count = 3; 6'h2B: count = 4;
        6'h2C: count = 3; 6'h2D: count = 4; 6'h2E: count = 4; 6'h2F: count = 5;
        6'h30: count = 2; 6'h31: count = 3; 6'h32: count = 3; 6'h33: count = 4;
        6'h34: count = 3; 6'h35: count = 4; 6'h36: count = 4; 6'h37: count = 5;
        6'h38: count = 3; 6'h39: count = 4; 6'h3A: count = 4; 6'h3B: count = 5;
        6'h3C: count = 4; 6'h3D: count = 5; 6'h3E: count = 5; 6'h3F: count = 6;
        endcase
    end
endmodule
