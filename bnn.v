// Copyright (C) 2019, Gray Research LLC
//

//////////////////////////////////////////////////////////////////////////////
// BNNDotProd CFU

/* verilator lint_off DECLFILENAME */

`include "cfu.h"

// Test bench
module BNNDotProd32TB #(
    parameter CFU_REQ_DATA_W = 32,
    parameter CFU_RESP_DATA_W = CFU_REQ_DATA_W
) (
    input clock,
    input [15:0] cycle,
    input [15:0] lfsr);

    reg [1:0] `CFU_REQ_DATA req_data `vp = 0;
    reg [0:0] `CFU_RESP_DATA resp_data `vp = 0;

    reg `CFU_RESP_DATA xnor_ `vp = 0;
    reg `CFU_RESP_DATA answer `vp = 0;
    int i;
    always @* begin
        req_data[0] = {cycle-1'b1,cycle};
        req_data[1] = {16'b0,lfsr};

        xnor_ = req_data[0] ~^ req_data[1];
        answer = 0;
        for (i = 0; i < CFU_REQ_DATA_W; i = i + 1) begin
            if (xnor_[i])
                answer = answer + 1;
        end
    end

    BNNDotProd32_CombCFU #(
        .CFU_FUNCTION_ID_W(1),
        .CFU_REQ_INPUTS(2), .CFU_REQ_DATA_W(CFU_REQ_DATA_W),
        .CFU_RESP_OUTPUTS(1), .CFU_RESP_DATA_W(CFU_RESP_DATA_W))
      bnn(.req_function_id(1'b0), .req_data, .resp_data);

    always @(posedge clock) begin
        if (resp_data[0] != answer)
            $display("fail: bnn(%08x, %08x): resp_data[0]=%1d != %1d", req_data[0], req_data[1], resp_data[0], answer);
    end
endmodule


// Level-0 (Combinational) 1b binary neural net dot product combinational CFU
//
// A binary neural net has 1b weights and activations, each encoded { 0=>+1, 1=>-1 }.
// The dot product of W: w*1b weights and A: w*1b activations is popcount(W~^A).
//
// Metadata
//  Supports: REQ_WIDTH==32 or REQ_WIDTH==64
//  IID: IID_BNNDotProd
//  Functions: {BNNDotProd}
//  Inputs: w*1b activations, w*1b weights
//  Outputs: w-bit BNN dot product
//
// TODO: figure out how to handle configurable CFU e.g. REQ_WIDTH is 32b *or* 64b.
// 
module BNNDotProd32_CombCFU #(
    `CFU_L0_PARAMETERS(2,32)
) (
    input `CFU_FUNCTION_ID req_function_id,
    input [1:0] `CFU_REQ_DATA req_data,
    output [0:0] `CFU_RESP_DATA resp_data
);
    wire `CFU_DATA xnor_ = req_data[0] ~^ req_data[1];
    wire [5:0] count;
    Popcount32 count_(.i(xnor_), .popcount(count));
    assign resp_data[0] = {26'b0,count};

    // assert(req_function_id == IID_BNNDotProd32.BNNDotProd32)
    wire _unused_ok = &{1'b0,req_function_id,1'b0};
endmodule

