// Copyright (C) 2019, Gray Research LLC
//

/* verilator lint_off DECLFILENAME */

`include "cfu.vh"

// Test bench for level-2 (variable latency with request flow control) GCD
// (greatest common divisor)
module GCDLI2TB #(
    parameter CFU_FUNC_ID_W = 1,
    parameter CFU_REQ_RESP_ID_W = 8,
    parameter CFU_REQ_DATA_W = 32,
    parameter CFU_RESP_DATA_W = 32,
    parameter CFU_ERR_ID_W = 32
) (
    input clk,
    input rst,
    input [15:0] cycle,     // unused
    input [15:0] lfsr);

    function integer gcdfn(input integer a, input integer b); begin
        // assumes a, b > 0
        while (a != b) begin
            if (a > b)
                a = a - b;
            else
                b = b - a;
        end
        gcdfn = a;
    end endfunction

    // try asserting req_valid at "random" times
    wire req_valid = !rst && lfsr[0];
    wire req_ready;
    reg `CFU_FUNC_ID req_func_id = 0;
    reg `CFU_REQ_RESP_ID req_id;
    reg `CFU_REQ_DATA a;
    reg `CFU_REQ_DATA b;

    // last request issued
    reg `CFU_REQ_RESP_ID req_id_prev;
    reg `CFU_REQ_DATA a_prev;
    reg `CFU_REQ_DATA b_prev;

    wire resp_valid;
    wire `CFU_REQ_RESP_ID resp_id;
    wire `CFU_RESP_DATA resp_data;
    wire resp_err;
    wire `CFU_ERR_ID resp_err_id;

    // request GCD of (1,1), (1,2), (2,2), (1,3), (2,3), (3,3), (1,4), etc.
    always @(posedge clk) begin
        if (rst) begin
            req_id_prev <= 0;
            a_prev <= 0;
            b_prev <= 0;

            req_id <= 1;
            a <= 1;
            b <= 1;
        end
        else if (req_valid && req_ready) begin
            // issuing the current GCD request, so prepare next request
            req_id_prev <= req_id;
            a_prev <= a;
            b_prev <= b;

            req_id <= req_id + 1;
            if (a < b) begin
                a <= a + 1;
            end
            else begin
                a <= 1;
                b <= b + 1;
            end
        end

        if (resp_valid) begin
            // process GCD response
            if (resp_id != req_id_prev)
                $display("GCD2TB: FAIL: resp_id != req_id");
            else if (resp_err)
                $display("GCD2TB: FAIL: resp_err, resp_err_id=%1d", resp_err_id);
            else if (resp_data != gcdfn(a_prev, b_prev))
                $display("GCD2TB: FAIL: resp_data=%1d != %1d", resp_data, gcdfn(a_prev, b_prev));
        end
    end

    // Since a <= b, perform gcd(b,a) to force at least one swap of arguments
    // in GCD_CFU_LI2.
    GCD_CFU_LI2 #(
        .CFU_FUNC_ID_W(CFU_FUNC_ID_W),
        .CFU_REQ_RESP_ID_W(CFU_REQ_RESP_ID_W),
        .CFU_REQ_DATA_W(CFU_REQ_DATA_W),
        .CFU_RESP_DATA_W(CFU_RESP_DATA_W),
        .CFU_ERR_ID_W(CFU_ERR_ID_W))
      gcd(.clk, .rst,
          .req_valid, .req_ready, .req_func_id, .req_id, .req_data0(b), .req_data1(a),
          .resp_valid, .resp_id, .resp_data, .resp_err, .resp_err_id);

    wire _unused_ok = &{1'b0,cycle,lfsr[15:1],resp_err_id,1'b0};
endmodule


// Level-2 (variable latency with request flow control) GCD
// (greatest common divisor)
//
//  Latency=?
//  Inputs=2
//  Outputs=1
// 
/* Metadata
CFU_LI:
    - feature_level: 2
    - cfu_func_id_w: [1]
    - cfu_req_data_w: [32]
    - cfu_resp_data_w: [32]
    - cfu_err_id_w: [32]
    - cfu_resp_latecy: variable
*/
module GCD_CFU_LI2 #(
    parameter CFU_FUNC_ID_W = 1,
    parameter CFU_REQ_RESP_ID_W = 8,
    parameter CFU_REQ_DATA_W = 32,
    parameter CFU_RESP_DATA_W = 32,
    parameter CFU_ERR_ID_W = 32
) (
    input clk,
    input rst,
    input req_valid,
    output reg req_ready,
    input `CFU_FUNC_ID req_func_id, // unused
    input `CFU_REQ_RESP_ID req_id,
    input `CFU_REQ_DATA req_data0,
    input `CFU_REQ_DATA req_data1,
    output reg resp_valid,
    output reg `CFU_REQ_RESP_ID resp_id,
    output reg `CFU_RESP_DATA resp_data,
    output reg resp_err,
    output reg `CFU_ERR_ID resp_err_id
);
    // assert(CFU_REQ_WIDTH == CFU_RESP_WIDTH);

    reg `CFU_REQ_DATA a;
    reg `CFU_REQ_DATA b;

    always @(posedge clk) begin
        if (rst) begin
            req_ready <= 1;
            resp_valid <= 0;
            resp_id <= 0;
            resp_data <= 0;
            resp_err <= 0;
            resp_err_id <= 0;
        end
        else if (req_ready) begin
            if (req_valid) begin
                req_ready <= 0;
                a <= req_data0;
                b <= req_data1;
                resp_id <= req_id;
            end
            resp_valid <= 0;
        end
        else begin
            if (a < b) begin
                // swap a and b
                a <= b;
                b <= a;
            end
            else if (b != 0) begin
                a <= a - b;
            end
            else begin
                req_ready <= 1;     // assert until req_valid
                resp_valid <= 1;    // assert for one cycle ony
                resp_data <= a;
            end
        end
    end

    wire _unused_ok = &{1'b0,req_func_id,1'b0};
endmodule


// Test bench for level-3 (variable latency with request and response flow control)
// GCD (greatest common divisor)
module GCDLI3TB #(
    parameter CFU_FUNC_ID_W = 1,
    parameter CFU_REQ_RESP_ID_W = 8,
    parameter CFU_REQ_DATA_W = 32,
    parameter CFU_RESP_DATA_W = 32,
    parameter CFU_ERR_ID_W = 32
) (
    input clk,
    input rst,
    input [15:0] cycle,
    input [15:0] lfsr);

    function integer gcdfn(input integer a, input integer b); begin
        // assumes a, b > 0
        while (a != b) begin
            if (a > b)
                a = a - b;
            else
                b = b - a;
        end
        gcdfn = a;
    end endfunction

    // try asserting req_valid at "random" times
    wire req_valid = !rst && lfsr[0];	// pseudo-random
    wire req_ready;
    reg `CFU_FUNC_ID req_func_id = 0;
    reg `CFU_REQ_RESP_ID req_id;
    reg `CFU_REQ_DATA a;
    reg `CFU_REQ_DATA b;

    // last request issued
    reg `CFU_REQ_RESP_ID req_id_prev;
    reg `CFU_REQ_DATA a_prev;
    reg `CFU_REQ_DATA b_prev;

    wire resp_valid;
	wire resp_ready = ^cycle;			// pseudo-random
    wire `CFU_REQ_RESP_ID resp_id;
    wire `CFU_RESP_DATA resp_data;
    wire resp_err;
    wire `CFU_ERR_ID resp_err_id;

    // request GCD of (1,1), (1,2), (2,2), (1,3), (2,3), (3,3), (1,4), etc.
    always @(posedge clk) begin
        if (rst) begin
            req_id_prev <= 0;
            a_prev <= 0;
            b_prev <= 0;

            req_id <= 1;
            a <= 1;
            b <= 1;
        end
        else if (req_valid && req_ready) begin
            // issuing the current GCD request, so prepare next request
            req_id_prev <= req_id;
            a_prev <= a;
            b_prev <= b;

            req_id <= req_id + 1;
            if (a < b) begin
                a <= a + 1;
            end
            else begin
                a <= 1;
                b <= b + 1;
            end
        end

        if (resp_valid && resp_ready) begin
            // process GCD response
/*            if (resp_id != req_id_prev)
                $display("GCD3TB: FAIL: resp_id=%1d != req_id=%1d", resp_id, req_id_prev);
            else */if (resp_err)
                $display("GCD3TB: FAIL: resp_err, resp_err_id=%1d", resp_err_id);
            else if (resp_data != gcdfn(a_prev, b_prev))
                $display("GCD3TB: FAIL: resp_data=%1d != %1d", resp_data, gcdfn(a_prev, b_prev));
        end
    end

    // Since a <= b, perform gcd(b,a) to force at least one swap of arguments
    // in GCD_CFU_LI3.
    GCD_CFU_LI3 #(
        .CFU_FUNC_ID_W(CFU_FUNC_ID_W),
        .CFU_REQ_RESP_ID_W(CFU_REQ_RESP_ID_W),
        .CFU_REQ_DATA_W(CFU_REQ_DATA_W),
        .CFU_RESP_DATA_W(CFU_RESP_DATA_W),
        .CFU_ERR_ID_W(CFU_ERR_ID_W))
      gcd(.clk, .rst,
          .req_valid, .req_ready, .req_func_id, .req_id, .req_data0(b), .req_data1(a),
          .resp_valid, .resp_ready(1'b1), .resp_id, .resp_data, .resp_err, .resp_err_id);

    wire _unused_ok = &{1'b0,req_id_prev,resp_id,lfsr[15:1],resp_err_id,1'b0};
endmodule


// Level-3 (variable latency with request and response flow control) GCD
// (greatest common divisor)
//
//  Latency=?
//  Inputs=2
//  Outputs=1
// 
/* Metadata
CFU_LI:
    - feature_level: 2
    - cfu_func_id_w: [1]
    - cfu_req_data_w: [32]
    - cfu_resp_data_w: [32]
    - cfu_err_id_w: [32]
    - cfu_resp_latecy: variable
*/
module GCD_CFU_LI3 #(
    parameter CFU_FUNC_ID_W = 1,
    parameter CFU_REQ_RESP_ID_W = 8,
    parameter CFU_REQ_DATA_W = 32,
    parameter CFU_RESP_DATA_W = 32,
    parameter CFU_ERR_ID_W = 32
) (
    input clk,
    input rst,
    input req_valid,
    output reg req_ready,
    input `CFU_FUNC_ID req_func_id, // unused
    input `CFU_REQ_RESP_ID req_id,
    input `CFU_REQ_DATA req_data0,
    input `CFU_REQ_DATA req_data1,
    output reg resp_valid,
    input resp_ready,
    output reg `CFU_REQ_RESP_ID resp_id,
    output reg `CFU_RESP_DATA resp_data,
    output reg resp_err,
    output reg `CFU_ERR_ID resp_err_id
);
    // assert(CFU_REQ_WIDTH == CFU_RESP_WIDTH);

    reg `CFU_REQ_DATA a;
    reg `CFU_REQ_DATA b;
	reg `CFU_REQ_RESP_ID req_id_prev;

    always @(posedge clk) begin
        if (rst) begin
            req_ready <= 1;
			req_id_prev <= 0;
            resp_valid <= 0;
            resp_id <= 0;
            resp_data <= 0;
            resp_err <= 0;
            resp_err_id <= 0;
        end
        else begin
			if (req_ready) begin
				// idle; await valid request
				if (req_valid) begin
					req_ready <= 0;
					req_id_prev <= req_id;
					a <= req_data0;
					b <= req_data1;
				end
			end
			else begin
				// gcd in progress
				if (a < b) begin
					// swap a and b
					a <= b;
					b <= a;
				end
				else if (b != 0) begin
					a <= a - b;
				end
				else begin
					// have result; issue response unless previous
					// response has not yet been accepted
					if (!resp_valid) begin
						req_ready <= 1;
						resp_valid <= 1;
						resp_id <= req_id_prev;
						resp_data <= a;
					end
				end
			end

			// response flow control: assert response until response handshake
			if (resp_valid && resp_ready) begin
				resp_valid <= 0;
			end
		end
    end

    wire _unused_ok = &{1'b0,req_func_id,1'b0};
endmodule
