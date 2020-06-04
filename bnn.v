// Copyright (C) 2019, Gray Research LLC
//

//////////////////////////////////////////////////////////////////////////////
// BNNDotProd CFU

/* verilator lint_off DECLFILENAME */

`include "cfu.vh"

// Test bench
module BNNDotProd32TB #(
    parameter CFU_FUNC_ID_W = 1,
    parameter CFU_REQ_DATA_W = 32,
    parameter CFU_RESP_DATA_W = CFU_REQ_DATA_W
) (
    input clk,
    input [15:0] cycle,
    input [15:0] lfsr);

    wire `CFU_FUNC_ID req_func_id = 0;
    reg `CFU_REQ_DATA req_data0 `vp = 0;
    reg `CFU_REQ_DATA req_data1 `vp = 0;
    reg `CFU_RESP_DATA resp_data `vp = 0;

    reg `CFU_RESP_DATA xnor_ `vp = 0;
    reg `CFU_RESP_DATA answer `vp = 0;
    int i;
    always @* begin
        req_data0 = {cycle-1'b1,cycle};
        req_data1 = {16'b0,lfsr};

        xnor_ = req_data0 ~^ req_data1;
        answer = 0;
        for (i = 0; i < CFU_REQ_DATA_W; i = i + 1) begin
            if (xnor_[i])
                answer = answer + 1;
        end
    end

    BNNDotProd32_CFU_LI0 #(
        .CFU_FUNC_ID_W(CFU_FUNC_ID_W),
        .CFU_REQ_DATA_W(CFU_REQ_DATA_W),
        .CFU_RESP_DATA_W(CFU_RESP_DATA_W))
      bnn(.req_valid(1'b1), .req_func_id(req_func_id), .req_data0(req_data0), .req_data1(req_data1), .resp_data(resp_data));

    always @(posedge clk) begin
        if (resp_data != answer)
            $display("fail: bnn(%08x, %08x): resp_data=%1d != %1d", req_data0, req_data1, resp_data, answer);
    end
endmodule


// Level-0 (Combinational) 1b binary neural net dot product combinational CFU
//
// A binary neural net has 1b weights and activations, each encoded { 0=>+1, 1=>-1 }.
// The (biased) dot product of W: w*1b weights and A: w*1b activations is popcount(W~^A).
//
// (Obselete) Metadata -- REVIEW
//  Supports: REQ_WIDTH==32 or REQ_WIDTH==64
//  IID: IID_BNNDotProd
//  Functions: {BNNDotProd}
//  Inputs: w*1b activations, w*1b weights
//  Outputs: w-bit BNN dot product
// 
/* Metadata
CFU_LI:
    - feature_level: 0
    - cfu_req_data_w: [32]
    - cfu_resp_data_w: [32]
    - cfu_func_id_w: [1]
*/
module BNNDotProd32_CFU_LI0 #(
    parameter CFU_FUNC_ID_W = 1,
    parameter CFU_REQ_DATA_W = 32,
    parameter CFU_RESP_DATA_W = 32
) (
    input req_valid, // unused
    input `CFU_FUNC_ID req_func_id,  // unused
    input `CFU_REQ_DATA req_data0,
    input `CFU_REQ_DATA req_data1,
    output `CFU_RESP_DATA resp_data
);
    wire `CFU_REQ_DATA xnor_ = req_data0 ~^ req_data1;
    wire [5:0] count;
    Popcount32 count_(.i(xnor_), .popcount(count));
    assign resp_data = {26'b0,count};

    // assert(req_function_id == IID_BNNDotProd32.BNNDotProd32)
    wire _unused_ok = &{1'b0,req_valid,req_func_id,1'b0};
endmodule

