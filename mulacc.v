// Copyright (C) 2019, Gray Research LLC
//

/* verilator lint_off DECLFILENAME */

`include "cfu.h"

// Test bench
module MulAccTB #(
    parameter CFU_VERSION = 0,
    parameter CFU_FUNCTION_ID_W = 1,
    parameter CFU_REQ_RESP_ID_W = 6,
    parameter CFU_REQ_DATA_W = 32,
    parameter CFU_RESP_DATA_W = CFU_REQ_DATA_W,
    parameter CFU_ERROR_ID_W = CFU_RESP_DATA_W
) (
	input clock,
	input reset,
	input [15:0] cycle,
	input [15:0] lfsr);

    reg req_valid;
    reg `CFU_FUNCTION_ID req_function_id;
    reg `CFU_REQ_RESP_ID req_id;
    reg [1:0] `CFU_REQ_DATA req_data;

    wire resp_valid;
    wire resp_ok;
    wire `CFU_REQ_RESP_ID resp_id;
    wire [0:0] `CFU_RESP_DATA resp_data;
    wire `CFU_ERROR_ID resp_error_id;

	always @* begin
		req_valid = 1;			// default: valid
		req_function_id = 1;	// default: mul-acc
		req_id = 0;	
		req_data = 0;

		if (cycle[7:0] == 0) begin
			req_function_id = 0; // reset
		end
		else if (cycle[15:8] == 0) begin
			// Sum 1..100 in honor of young Gauss
			if (cycle[7:0] <= 100) begin
				req_data[0] = 1;
				req_data[1] = {16'b0,cycle};
			end
			else begin
				req_valid = 0;
			end
		end
		else begin
			req_data[0] = {16'b0,cycle};
			req_data[1] = {16'b0,lfsr};
		end
	end

	// model the accumulator
    reg `CFU_DATA acc;
    reg `CFU_DATA acc_q;
    reg `CFU_DATA acc_qq;
	always @(posedge clock) begin
		if (reset) begin
			acc <= 0;
		end
		else if (req_valid) begin
			if (req_function_id == 0) // reset?
				acc <= 0;
			else 
				acc <= acc + req_data[0] * req_data[1];
		end
		acc_q <= acc;
		acc_qq <= acc_q;
	end

    MulAcc_PipeCFU #(
        .CFU_FUNCTION_ID_W(1),
        .CFU_REQ_RESP_ID_W(CFU_REQ_RESP_ID_W),
        .CFU_REQ_INPUTS(2), .CFU_REQ_DATA_W(CFU_REQ_DATA_W),
        .CFU_RESP_OUTPUTS(1), .CFU_RESP_DATA_W(CFU_RESP_DATA_W),
        .CFU_ERROR_ID_W(CFU_RESP_DATA_W), .CFU_LATENCY(3))
      mulacc(.clock, .reset, .clock_en(1'b1),
             .req_valid, .req_function_id, .req_id, .req_data,
             .resp_valid, .resp_id, .resp_data, .resp_ok, .resp_error_id);

	always @(posedge clock) begin
		if (resp_valid && !resp_ok)
			$display("fail: mul_acc: !resp_ok");
		else if (resp_valid && resp_data[0] != acc_qq)
			$display("fail: mul_acc: resp_data[0]=%1d != %1d", resp_data[0], acc_qq);
	end

    wire _unused_ok = &{1'b0,resp_id,resp_error_id,1'b0};
endmodule


// Level-1 (Pipelined) multiply-accumulate (cumulative dot product)
//
// Pipeline advances every clock cycle unless clock_en negated.
// No dynamic interface_id, reorder_id, req_ready, resp_ready
//
// Metadata
//  Supports: REQ_WIDTH==32 or REQ_WIDTH==64
//  stateful interface /*IID_IMulAcc*/ IMulAcc {
//      int acc;
//      /*0*/ reset(a,b) { return acc = 0; }
//      /*1*/ mulacc(a,b) { return acc += a*b; }
//  }
//  II=1
//  Latency=3
//  Inputs=2
//  Outputs=1
// 
module MulAcc_PipeCFU #(
    parameter CFU_VERSION = 0,
    parameter CFU_FUNCTION_ID_W = 16,
    parameter CFU_REQ_RESP_ID_W = 6,
    parameter CFU_REQ_INPUTS = 2,
    parameter CFU_REQ_DATA_W = 32,
    parameter CFU_RESP_OUTPUTS = 1,
    parameter CFU_RESP_DATA_W = CFU_REQ_DATA_W,
    parameter CFU_ERROR_ID_W = CFU_RESP_DATA_W,
    parameter CFU_LATENCY = 3
) (
    input clock,
    input reset,
    input clock_en,

    input req_valid,
    input `CFU_FUNCTION_ID req_function_id,
    input `CFU_REQ_RESP_ID req_id,
    input [1:0] `CFU_REQ_DATA req_data,

    output resp_valid,
    output `CFU_REQ_RESP_ID resp_id,
    output [0:0] `CFU_RESP_DATA resp_data,
    output resp_ok,
    output `CFU_ERROR_ID resp_error_id
);
    // assert(CFU_REQ_WIDTH == CFU_RESP_WIDTH);

    // accumulator
    reg `CFU_DATA acc;

    // response pipeline state
    reg [CFU_LATENCY-1:0] valid;
    reg [CFU_LATENCY-1:0] `CFU_REQ_RESP_ID id;
    reg [CFU_LATENCY-2:0] reset_acc;
    reg [CFU_LATENCY-2:0] `CFU_DATA prod;

    // response pipeline
	int i;
    always @(posedge clock) begin
        if (reset) begin
            {valid,id,reset_acc,prod} <= 0;
            acc <= 0;
        end
        else if (clock_en) begin
            valid[0] <= req_valid;
            id[0] <= req_id;
            reset_acc[0] <= (req_function_id == 0);
            prod[0] <= req_data[0] * req_data[1];

            for (i = 1; i < CFU_LATENCY; i = i + 1)
                valid[i] <= valid[i-1];
            for (i = 1; i < CFU_LATENCY; i = i + 1)
                id[i] <= id[i-1];
            for (i = 1; i < CFU_LATENCY-1; i = i + 1)
                reset_acc[i] <= reset_acc[i-1];
            for (i = 1; i < CFU_LATENCY-1; i = i + 1)
                prod[i] <= prod[i-1];

            if (valid[CFU_LATENCY-2]) begin
                if (reset_acc[CFU_LATENCY-2])
                    acc <= 0;
                else
                    acc <= acc + prod[CFU_LATENCY-2];
            end
        end
    end

    // response
    assign resp_valid = valid[CFU_LATENCY-1];
    assign resp_id = id[CFU_LATENCY-1];
    assign resp_data = acc;
    assign resp_ok = 1;
    assign resp_error_id = 0;
endmodule
