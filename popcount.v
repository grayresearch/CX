// Copyright (C) 2019, Gray Research LLC
//

//////////////////////////////////////////////////////////////////////////////
// Popcount CFU

/* verilator lint_off DECLFILENAME */

`include "cfu.vh"

module PopcountTB #(
    parameter CFU_REQ_DATA_W = 32,
    parameter CFU_RESP_DATA_W = CFU_REQ_DATA_W
) (
    input clock,
    input [15:0] cycle);

    reg [0:0] `CFU_REQ_DATA req_data `vp = 0;
    reg [0:0] `CFU_RESP_DATA resp_data `vp = 0;

    int i;
    reg `CFU_RESP_DATA answer `vp = 0;
    always @* begin
        case (cycle)
        default: req_data[0] = 0;
         1: req_data[0] = 32'h1;
         2: req_data[0] = 32'h3;
         3: req_data[0] = 32'h7;
         4: req_data[0] = 32'hF;
         5: req_data[0] = 32'h1F;
         6: req_data[0] = 32'h3F;
         7: req_data[0] = 32'h7F;
         8: req_data[0] = 32'hFF;

         9: req_data[0] = 32'h10000000;
        10: req_data[0] = 32'h30000000;
        11: req_data[0] = 32'h70000000;
        12: req_data[0] = 32'hF0000000;
        13: req_data[0] = 32'h1F000000;
        14: req_data[0] = 32'h3F000000;
        15: req_data[0] = 32'h7F000000;
        16: req_data[0] = 32'hFF000000;

        17: req_data[0] = 32'hFFF;
        18: req_data[0] = 32'hFFFF;
        19: req_data[0] = 32'hFFFFF;
        20: req_data[0] = 32'hFFFFFF;
        21: req_data[0] = 32'hFFFFFFF;
        22: req_data[0] = 32'hFFFFFFFF;
        23: req_data[0] = 32'hF0F0F0F0;
        24: req_data[0] = 32'hC0C0C0C0;
        25: req_data[0] = 32'h80808080;
        endcase

        answer = 0;
        for (i = 0; i < CFU_REQ_DATA_W; i = i + 1) begin
            if (req_data[0][i])
                answer = answer + 1;
        end
    end

    Popcount32_CombCFU #(
        .CFU_FUNCTION_ID_W(1),
        .CFU_REQ_INPUTS(1), .CFU_REQ_DATA_W(CFU_REQ_DATA_W),
        .CFU_RESP_OUTPUTS(1), .CFU_RESP_DATA_W(CFU_RESP_DATA_W))
      pc(.req_function_id(1'b0), .req_data(req_data), .resp_data(resp_data));

    always @(posedge clock) begin
        if (resp_data[0] != answer)
            $display("fail: popcount(%08x): resp_data[0]=%1d != %1d", req_data[0], resp_data[0], answer);
    end
endmodule


// Level-0 (Combinational) 32b popcount CFU
//
// Metadata
//  IID=IID_Popcount32
//  Functions={Popcount32}
//  Inputs=1x32b
//  Outputs=1x32b
// 
module Popcount32_CombCFU #(
    `CFU_L0_PARAMETERS(1,32)
) (
    input `CFU_FUNCTION_ID req_function_id,
    input [0:0]`CFU_REQ_DATA req_data,
    output [0:0]`CFU_RESP_DATA resp_data
);
    wire [5:0] popcount;
    Popcount32 popcount_(.i(req_data[0]), .popcount);
    assign resp_data[0] = {26'b0,popcount};

    // assert(req_function_id == IID_Popcount32.Popcount32)
    wire _unused_ok = &{1'b0,req_function_id,1'b0};
endmodule


//////////////////////////////////////////////////////////////////////////////
// 32-bit population count
//
// Per the blog post "Quick FPGA Hacks: Population count"
// [http://fpga.org/2014/09/05/quick-fpga-hacks-population-count/]
//
module Popcount32(
    input [31:0] i,
    output [5:0] popcount);  // # of 1's in i

    wire [2:0] c0500, c1106, c1712, c2318, c2924, c3130, c0, c1, c2;

    // add six bundles of six bits
    C63 c0500_(.i(i[ 5: 0]), .o(c0500));
    C63 c1106_(.i(i[11: 6]), .o(c1106));
    C63 c1712_(.i(i[17:12]), .o(c1712));
    C63 c2318_(.i(i[23:18]), .o(c2318));
    C63 c2924_(.i(i[29:24]), .o(c2924));
    C63 c3130_(.i({4'b0,i[31:30]}), .o(c3130));

    // sum the bits set in the [0], [1], and [2] bit positions separately
    C63 c0_(.i({c0500[0],c1106[0],c1712[0],c2318[0],c2924[0],c3130[0]}), .o(c0));
    C63 c1_(.i({c0500[1],c1106[1],c1712[1],c2318[1],c2924[1],c3130[1]}), .o(c1));
    C63 c2_(.i({c0500[2],c1106[2],c1712[2],c2318[2],c2924[2],c3130[2]}), .o(c2));

    assign popcount = {2'b0,c0} + {1'b0,c1,1'b0} + {c2,2'b0};
endmodule


//////////////////////////////////////////////////////////////////////////////
// 6:3 compressor as a 64x3b ROM -- three 6-LUTs
//
module C63(
    input [5:0] i,
    output reg [2:0] o);    // # of 1's in i

    always @* begin
        case (i)
        6'h00: o = 0; 6'h01: o = 1; 6'h02: o = 1; 6'h03: o = 2;
        6'h04: o = 1; 6'h05: o = 2; 6'h06: o = 2; 6'h07: o = 3;
        6'h08: o = 1; 6'h09: o = 2; 6'h0A: o = 2; 6'h0B: o = 3;
        6'h0C: o = 2; 6'h0D: o = 3; 6'h0E: o = 3; 6'h0F: o = 4;
        6'h10: o = 1; 6'h11: o = 2; 6'h12: o = 2; 6'h13: o = 3;
        6'h14: o = 2; 6'h15: o = 3; 6'h16: o = 3; 6'h17: o = 4;
        6'h18: o = 2; 6'h19: o = 3; 6'h1A: o = 3; 6'h1B: o = 4;
        6'h1C: o = 3; 6'h1D: o = 4; 6'h1E: o = 4; 6'h1F: o = 5;
        6'h20: o = 1; 6'h21: o = 2; 6'h22: o = 2; 6'h23: o = 3;
        6'h24: o = 2; 6'h25: o = 3; 6'h26: o = 3; 6'h27: o = 4;
        6'h28: o = 2; 6'h29: o = 3; 6'h2A: o = 3; 6'h2B: o = 4;
        6'h2C: o = 3; 6'h2D: o = 4; 6'h2E: o = 4; 6'h2F: o = 5;
        6'h30: o = 2; 6'h31: o = 3; 6'h32: o = 3; 6'h33: o = 4;
        6'h34: o = 3; 6'h35: o = 4; 6'h36: o = 4; 6'h37: o = 5;
        6'h38: o = 3; 6'h39: o = 4; 6'h3A: o = 4; 6'h3B: o = 5;
        6'h3C: o = 4; 6'h3D: o = 5; 6'h3E: o = 5; 6'h3F: o = 6;
        endcase
    end
endmodule
