// Copyright (C) 2019, Gray Research LLC
//

/* verilator lint_off DECLFILENAME */

`include "cfu.vh"

// Test bench
module MulAccTB #(
    parameter CFU_FUNC_ID_W = 5,
    parameter CFU_REQ_DATA_W = 32,
    parameter CFU_RESP_DATA_W = 32,
    parameter CFU_ERR_ID_W = 32,
    parameter CFU_RESP_LATENCY = 3
) (
    input clk,
    input rst,
    input [15:0] cycle,
    input [15:0] lfsr);

    reg req_valid;
    reg `CFU_FUNC_ID req_func_id;
    reg `CFU_REQ_DATA req_data0;
    reg `CFU_REQ_DATA req_data1;

    wire resp_valid;
    wire resp_err;
    wire `CFU_RESP_DATA resp_data;
    wire `CFU_ERR_ID resp_err_id;

    always @* begin
        req_valid = 1;          // default: valid
        req_func_id = 1;    // default: mul-acc
        req_data0 = 0;
        req_data1 = 0;

        if (cycle[7:0] == 0) begin
            req_func_id = 0; // rst
        end
        else if (cycle[15:8] == 0) begin
            // First off, sum 1..100 in honor of young Gauss.
            if (cycle[7:0] <= 100) begin
                req_data0 = 1;
                req_data1 = {16'b0,cycle};
            end
            else begin
                req_valid = 0;
            end
        end
        else begin
            // Later iterations, MAC of random input pairs
            req_data0 = {16'b0,cycle};
            req_data1 = {cycle,lfsr};
        end
    end

    // model the accumulator
    reg `CFU_DATA acc;
    reg `CFU_DATA acc_q;
    reg `CFU_DATA acc_qq;
    always @(posedge clk) begin
        if (rst) begin
            acc <= 0;
        end
        else if (req_valid) begin
            if (req_func_id == 0) // rst?
                acc <= 0;
            else 
                acc <= acc + req_data0 * req_data1;
        end
        acc_q <= acc;
        acc_qq <= acc_q;
    end

    MulAcc_CFU_LI1 #(
        .CFU_FUNC_ID_W(CFU_FUNC_ID_W),
        .CFU_REQ_DATA_W(CFU_REQ_DATA_W),
        .CFU_RESP_DATA_W(CFU_RESP_DATA_W),
        .CFU_ERR_ID_W(CFU_ERR_ID_W),
        .CFU_RESP_LATENCY(CFU_RESP_LATENCY))
      mulacc(.clk, .rst,
             .req_valid, .req_func_id, .req_data0, .req_data1,
             .resp_valid, .resp_data, .resp_err, .resp_err_id);

    always @(posedge clk) begin
        if (resp_valid && resp_err)
            $display("MulAccTB: FAIL: resp_err");
        else if (resp_valid && resp_data != acc_qq)
            $display("MulAccTB: FAIL: resp_data=%1d != %1d", resp_data, acc_qq);
    end

    wire _unused_ok = &{1'b0,resp_err_id,1'b0};
endmodule


// Level-1 (Pipelined) multiply-accumulate (cumulative dot product)
//
// Pipeline advances every clk cycle unless clk_en negated.
// No dynamic interface_id, reorder_id, req_ready, resp_ready
//
// (Obsolete) Metadata // REVIEW
//  Supports: REQ_WIDTH==32 or REQ_WIDTH==64
//  stateful interface /*IID_IMulAcc*/ IMulAcc {
//      int acc;
//      /*0*/ rst(a,b) { return acc = 0; }
//      /*1*/ mulacc(a,b) { return acc += a*b; }
//  }
//  II=1
//  Latency=3
//  Inputs=2
//  Outputs=1
// 
/* Metadata
CFU_LI:
    - feature_level: 1
    - cfu_func_id_w: [5]
    - cfu_req_data_w: [32]
    - cfu_resp_data_w: [32]
    - cfu_err_id_w: [32]
    - cfu_resp_latecy: [3,4,5,6,7,8,9,10,11,12,13,14,15,16]
*/
module MulAcc_CFU_LI1 #(
    parameter CFU_FUNC_ID_W = 5,
    parameter CFU_REQ_DATA_W = 32,
    parameter CFU_RESP_DATA_W = 32,
    parameter CFU_ERR_ID_W = 32,
    parameter CFU_RESP_LATENCY = 3
) (
    input clk,
    input rst,
    input req_valid,
    input [CFU_FUNC_ID_W-1:0] req_func_id,
    input [CFU_REQ_DATA_W-1:0] req_data0,
    input [CFU_REQ_DATA_W-1:0] req_data1,
    output resp_valid,
    output [CFU_RESP_DATA_W-1:0] resp_data,
    output resp_err,
    output [CFU_ERR_ID_W-1:0] resp_err_id
);
    // assert(CFU_REQ_WIDTH == CFU_RESP_WIDTH);

    // accumulator
    reg [CFU_RESP_DATA_W-1:0] acc;

    // response pipeline state
    reg [CFU_RESP_LATENCY-1:0] valid;
    reg [CFU_RESP_LATENCY-2:0] rst_acc;
    reg [CFU_RESP_LATENCY-2:0] [CFU_RESP_DATA_W-1:0] prod;

    // response pipeline
    int i;
    always @(posedge clk) begin
        if (rst) begin
            {valid,rst_acc,prod} <= 0;
            acc <= 0;
        end
        else begin
            valid[0] <= req_valid;
            rst_acc[0] <= (req_func_id == 0);
            prod[0] <= req_data0 * req_data1;

            for (i = 1; i < CFU_RESP_LATENCY; i = i + 1)
                valid[i] <= valid[i-1];
            for (i = 1; i < CFU_RESP_LATENCY-1; i = i + 1)
                rst_acc[i] <= rst_acc[i-1];
            for (i = 1; i < CFU_RESP_LATENCY-1; i = i + 1)
                prod[i] <= prod[i-1];

            if (valid[CFU_RESP_LATENCY-2]) begin
                if (rst_acc[CFU_RESP_LATENCY-2])
                    acc <= 0;
                else
                    acc <= acc + prod[CFU_RESP_LATENCY-2];
            end
        end
    end

    // response
    assign resp_valid = valid[CFU_RESP_LATENCY-1];
    assign resp_data = acc;
    assign resp_err = 0;
    assign resp_err_id = 0;
endmodule


// Test bench
module MulAccSIMDTB #(
    parameter CFU_FUNC_ID_W = 5,
    parameter CFU_REQ_DATA_W = 32,
    parameter CFU_REQ_ELT_W = 8,
    parameter CFU_RESP_DATA_W = 32,
    parameter CFU_ERR_ID_W = 32,
    parameter CFU_RESP_LATENCY = 3
) (
    input clk,
    input rst,
    input [15:0] cycle,
    input [15:0] lfsr);

    reg req_valid;
    reg `CFU_FUNC_ID req_func_id;
    reg `CFU_REQ_DATA req_data0;
    reg `CFU_REQ_DATA req_data1;

    wire resp_valid;
    wire resp_err;
    wire `CFU_RESP_DATA resp_data;
    wire `CFU_ERR_ID resp_err_id;

    always @* begin
        req_valid = 1;          // default: valid
        req_func_id = 1;        // default: mul-acc
        req_data0 = 0;
        req_data1 = 0;

        if (cycle[7:0] == 0) begin
            req_func_id = 0; // rst
        end
        else if (cycle[15:8] == 0) begin
            // First off, sum 4 x 1..100 in honor of young Gauss.
            if (cycle[7:0] <= 100) begin
                req_data0 = {4{8'd1}};
                req_data1 = {4{cycle[7:0]}};
            end
            else begin
                req_valid = 0;
            end
        end
        else begin
            // Later iterations, MAC of random input pairs
            req_data0 = {4{cycle[7:0]}};
            req_data1 = {4{lfsr[7:0]}};
        end
    end

    // model the accumulator
    reg `CFU_DATA acc;
    reg `CFU_DATA acc_q;
    reg `CFU_DATA acc_qq;
    always @(posedge clk) begin
        if (rst) begin
            acc <= 0;
        end
        else if (req_valid) begin
            if (req_func_id == 0) // reset?
                acc <= 0;
            else 
                acc <= acc
                    + req_data0[ 0 +: 8] * req_data1[ 0 +: 8]
                    + req_data0[ 8 +: 8] * req_data1[ 8 +: 8]
                    + req_data0[16 +: 8] * req_data1[16 +: 8]
                    + req_data0[24 +: 8] * req_data1[24 +: 8];
        end
        acc_q <= acc;
        acc_qq <= acc_q;
    end

    MulAccSIMD_CFU_LI1 #(
        .CFU_FUNC_ID_W(CFU_FUNC_ID_W),
        .CFU_REQ_DATA_W(CFU_REQ_DATA_W),
        .CFU_REQ_ELT_W(CFU_REQ_ELT_W),
        .CFU_RESP_DATA_W(CFU_RESP_DATA_W),
        .CFU_ERR_ID_W(CFU_ERR_ID_W),
        .CFU_RESP_LATENCY(CFU_RESP_LATENCY))
      mulacc(.clk, .rst,
             .req_valid, .req_func_id, .req_data0, .req_data1,
             .resp_valid, .resp_data, .resp_err, .resp_err_id);

    always @(posedge clk) begin
        if (resp_valid && resp_err)
            $display("MulAccSIMDTB: FAIL: !resp_ok");
        else if (resp_valid && resp_data != acc_qq)
            $display("MulAccSIMDTB: FAIL: resp_data[0]=%1d != %1d", resp_data, acc_qq);
    end

    wire _unused_ok = &{1'b0,lfsr[15:8],resp_err_id,1'b0};
endmodule


// Level-1 (Pipelined) SIMD multiply-accumulate (cumulative dot product)
//
// Pipeline advances every clk cycle unless clk_en negated.
// No dynamic interface_id, reorder_id, req_ready, resp_ready
//
// Metadata
//  Supports: REQ_DATA_W==32 or REQ_DATA_W==64
//  Supports: REQ_ELT_W = 1, 2, 4, ..., REQ_DATA_W/2
//  stateful interface /*IID_IMulAcc*/ IMulAcc {
//      int acc;
//      /*0*/ rst(a,b) { return acc = 0; }
//      /*1*/ mulacc(a,b) { return acc += {a[j]*b[j] for each REQ_ELT_W-bit subword j in REQ_DATA_W}; }
//  }
//  II=1
//  Latency=3
//  Inputs=2
//  Outputs=1
// 
module MulAccSIMD_CFU_LI1 #(
    parameter CFU_FUNC_ID_W = 5,
    parameter CFU_REQ_DATA_W = 32,
    parameter CFU_RESP_DATA_W = 32,
    parameter CFU_ERR_ID_W = 32,
    parameter CFU_RESP_LATENCY = 3,
    parameter CFU_REQ_ELT_W = 8
) (
    input clk,
    input rst,
    input req_valid,
    input [CFU_FUNC_ID_W-1:0] req_func_id,
    input [CFU_REQ_DATA_W-1:0] req_data0,
    input [CFU_REQ_DATA_W-1:0] req_data1,
    output resp_valid,
    output [CFU_RESP_DATA_W-1:0] resp_data,
    output resp_err,
    output [CFU_ERR_ID_W-1:0] resp_err_id
);
    localparam N_ELTS = CFU_REQ_DATA_W / CFU_REQ_ELT_W;
    // assert(CFU_REQ_WIDTH == CFU_RESP_WIDTH);

    // accumulator
    reg `CFU_DATA acc;

    // response pipeline state
    reg [CFU_RESP_LATENCY-1:0] valid;
    reg [CFU_RESP_LATENCY-2:0] rst_acc;
    reg [CFU_RESP_LATENCY-2:0][N_ELTS-1:0][2*CFU_REQ_ELT_W-1:0] prod;

    // response pipeline
    int i;
    int j;
    reg `CFU_DATA prod_sum;
    `vloff_width
    always @* begin
        prod_sum = 0;
        for (j = 0; j < N_ELTS; j = j + 1)
            prod_sum = prod_sum + prod[CFU_RESP_LATENCY-2][j];
    end
    `vlon_width
    always @(posedge clk) begin
        if (rst) begin
            {valid,rst_acc,prod} <= 0;
            acc <= 0;
        end
        else begin
            valid[0] <= req_valid;
            rst_acc[0] <= (req_func_id == 0);
            for (j = 0; j < N_ELTS; j = j + 1)
                prod[0][j] <= req_data0[j*CFU_REQ_ELT_W +: CFU_REQ_ELT_W] * req_data1[j*CFU_REQ_ELT_W +: CFU_REQ_ELT_W];

            for (i = 1; i < CFU_RESP_LATENCY; i = i + 1)
                valid[i] <= valid[i-1];
            for (i = 1; i < CFU_RESP_LATENCY-1; i = i + 1)
                rst_acc[i] <= rst_acc[i-1];
            for (i = 1; i < CFU_RESP_LATENCY-1; i = i + 1)
                for (j = 0; j < N_ELTS; j = j + 1)
                    prod[i][j] <= prod[i-1][j];

            if (valid[CFU_RESP_LATENCY-2]) begin
                if (rst_acc[CFU_RESP_LATENCY-2])
                    acc <= 0;
                else
                    acc <= acc + prod_sum;
            end
        end
    end

    // response
    assign resp_valid = valid[CFU_RESP_LATENCY-1];
    assign resp_data = acc;
    assign resp_err = 0;
    assign resp_err_id = 0;
endmodule
