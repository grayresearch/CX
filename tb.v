// Copyright (C) 2019, Gray Research LLC

/* verilator lint_off DECLFILENAME */

`include "cfu.h"

module TB #(
    parameter CFU_VERSION = 0,
    parameter CFU_INTERFACE_ID_W = 16,
    parameter CFU_FUNCTION_ID_W = 1,
    parameter CFU_REORDER_ID_W = 8,
    parameter CFU_REQ_RESP_ID_W = 6,
    parameter CFU_REQ_INPUTS = 1,
    parameter CFU_REQ_DATA_W = 32,
    parameter CFU_RESP_OUTPUTS = 1,
    parameter CFU_RESP_DATA_W = CFU_REQ_DATA_W,
    parameter CFU_ERROR_ID_W = CFU_RESP_DATA_W,
    parameter IID_IMULACC = 1000
) (
    input clock,
    input reset);

//  reg clock_en = 1;
    reg [15:0] cycle = 0;
    reg [15:0] lfsr = 0;

    always @(posedge clock) begin
        if (&cycle) $finish;
        cycle <= reset ? 0 : (cycle + 1'b1);
        // XAPP 052 RIP Peter Aflke
        lfsr <= reset ? 0 : {lfsr[14:0],~(lfsr[15]^lfsr[14]^lfsr[12]^lfsr[3])};
    end

    PopcountTB ptb(.clock, .cycle);

    BNNDotProd32TB btb(.clock, .cycle, .lfsr);

    MulAccTB mactb(.clock, .reset, .cycle, .lfsr);
endmodule
