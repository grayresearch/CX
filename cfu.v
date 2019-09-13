// Copyright (C) 2019, Gray Research LLC

/* verilator lint_off DECLFILENAME */

`include "cfu.h"

module top();
    initial $finish;
endmodule

// General CFU interface
//
// Handshake
//  {req,resp}_{ready,valid} -- handshaken request/response
// Transaction
//  req_id, resp_id -- request/response correlation
//  reorder_id -- fine grained transaction reorder control -- transactions with same ID are not reordered
// Request
//  interface_id, function_id -- may implement multiple functions of multiple interfaces/interface versions.
// Response
//  resp_ok, error_id -- OK/error response and error details
//
// Anticipated metadata
//  IID=#
//  Functions={#}
//  II=#
//  Latency=#
//  Inputs=# x width
//  Outputs=# x width
// 
module CFU #(
    parameter CFU_VERSION = 0,
    parameter CFU_INTERFACE_ID_W = 16,
    parameter CFU_FUNCTION_ID_W = 16,
    parameter CFU_REORDER_ID_W = 8,
    parameter CFU_REQ_RESP_ID_W = 6,
    parameter CFU_REQ_INPUTS = 2,
    parameter CFU_REQ_DATA_W = 32,
    parameter CFU_RESP_OUTPUTS = 1,
    parameter CFU_RESP_DATA_W = CFU_REQ_DATA_W,
    parameter CFU_ERROR_ID_W = CFU_RESP_DATA_W
) (
    input wire clock,
    input wire reset,
    input wire clock_en,

    output wire req_ready,
    input wire req_valid,
    input wire `CFU_INTERFACE_ID req_interface_id,
    input wire `CFU_FUNCTION_ID req_function_id,
    input wire `CFU_REORDER_ID req_reorder_id,
    input wire `CFU_REQ_RESP_ID req_id,
    input wire `CFU_REQ_DATA[0:REQ_INPUTS-1] req_data,

    input wire resp_ready,
    output wire resp_valid,
    output wire `CFU_REQ_RESP_ID resp_id,
    output wire `CFU_RESP_DATA[0:CFU_RESP_OUTPUTS-1] resp_data,
    output wire resp_ok,
    output wire `CFU_ERROR_ID resp_error_id
);
    initial $finish;
    // TODO: discuss interaction with clock_en and handshakes.
    // In general I believe nothing happens / nothing sequential
    // changes between master/slave when clock_en is negated.
endmodule


// Simple registed, pipelined CFU
// Pipeline advances every clock cycle unless clock_en negated.
// No dynamic interface_id, reorder_id, req_ready, resp_ready
//
// Metadata
//  IID=#
//  Functions={#}
//  II=#
//  Latency=#
//  Inputs=# x width
//  Outputs=# x width
// 
module CFUPipelined #(
    parameter CFU_VERSION = 0,
    parameter CFU_FUNCTION_ID_W = 16,
    parameter CFU_REQ_RESP_ID_W = 6,
    parameter CFU_REQ_INPUTS = 2,
    parameter CFU_REQ_DATA_W = 32,
    parameter CFU_RESP_OUTPUTS = 1,
    parameter CFU_RESP_DATA_W = CFU_REQ_DATA_W,
    parameter CFU_ERROR_ID_W = CFU_REQ_DATA_W
) (
    input wire clock,
    input wire reset,
    input wire clock_en,

    input wire req_valid,
    input wire `CFU_FUNCTION_ID req_function_id,
    input wire `CFU_REQ_RESP_ID req_id,
    input wire `CFU_REQ_DATA[0:CFU_REQ_INPUTS-1] req_data,

    output wire resp_valid,
    output wire `CFU_REQ_RESP_ID resp_id,
    output wire `CFU_RESP_DATA[0:CFU_RESP_OUTPUTS-1] resp_data,
    output wire resp_ok,
    output wire `CFU_ERROR_ID resp_error_id
);
    // assert(VERSION == 0 && CFU_REQ_INPUTS == 2 && CFU_RESP_OUTPUTS == 1);
    function `CFU_RESP_DATA Fn(input `CFU_FUNCTION_ID id, input `CFU_REQ_DATA i0, input `CFU_REQ_DATA i1); begin
        Fn = i0 * i1;
    end endfunction

    // response pipeline state
    localparam N_STAGES = 3;
    reg [0:N_STAGES-1] valids;
    reg `CFU_REQ_RESP_ID[0:N_STAGES-1] ids;
    reg `CFU_RESP_DATA[0:N_STAGES-1] data;

    // response pipeline
    always @(posedge clock) begin
        if (reset) begin
            {valids,ids,data} <= 0;
        end
        else if (clock_en) begin
            valids[0] <= req_valid;
            ids[0] <= req_id;
            data[0] <= Fn(req_function_id, req_data[0], req_data[1]);
            for (i = 1; i < N_STAGES; ++i) begin
                {valids[i],ids[i],data[i]} <= {valids[i-1],ids[i-1],data[i-1]};
            end
        end
    end

    // response
    assign resp_valid = valids[N_STAGES-1];
    assign resp_id = ids[N_STAGES-1];
    assign resp_data = data[N_STAGES-1];
    assign resp_ok = 1;
    assign resp_error_id = 0;
endmodule


// Simple combinational CFU
// No version!
// No clock, reset, clock_en, interface_id, reorder_id, ready/valid flow control, transaction control.
// No resp_ok, error_id.
//
// Metadata
//  IID=#
//  Functions={#}
//  Inputs=# x width
//  Outputs=# x width
// 
module CFUComb #(
    parameter CFU_FUNCTION_ID_W = 16,
    parameter CFU_REQ_INPUTS = 2,
    parameter CFU_REQ_DATA_W = 32,
    parameter CFU_RESP_OUTPUTS = 1,
    parameter CFU_RESP_DATA_W = CFU_REQ_DATA_W
) (
    input wire `CFU_FUNCTION_ID req_function_id,
    input wire `CFU_REQ_DATA[0:C_REQ_INPUTS-1] req_data,
    output wire `CFU_RESP_DATA[0:CFU_RESP_OUTPUTS-1] resp_data
);
    function `CFU_RESP_DATA Fn(input `CFU_FUNCTION_ID id, input `CFU_REQ_DATA i0, input `CFU_REQ_DATA i1); begin
        Fn = i0 * i1;
    end endfunction

    assign resp_data[0] = Fn(req_function_id, req_data[0], req_data[1]);
endmodule


////////////////////////////////////////////////////////////////////////////////
// CFU Adapters
// CFUComb => CFU
// CFUComb => CFUPipelined
// CFUPipelined => CFU

module CFU_CFUComb_Adapter #(
    parameter CFU_VERSION = 0,
    parameter CFU_INTERFACE_ID_W = 16,
    parameter CFU_FUNCTION_ID_W = 16,
    parameter CFU_REORDER_ID_W = 8,
    parameter CFU_REQ_RESP_ID_W = 6,
    parameter CFU_REQ_INPUTS = 2,
    parameter CFU_REQ_DATA_W = 32,
    parameter CFU_RESP_OUTPUTS = 1,
    parameter CFU_RESP_DATA_W = CFU_REQ_DATA_W,
    parameter CFU_ERROR_ID_W = CFU_RESP_DATA_W
) (
    input wire clock,
    input wire reset,
    input wire clock_en,

    output wire req_ready,
    input wire req_valid,
    input wire `CFU_INTERFACE_ID req_interface_id,
    input wire `CFU_FUNCTION_ID req_function_id,
    input wire `CFU_REORDER_ID req_reorder_id,
    input wire `CFU_REQ_RESP_ID req_id,
    input wire `CFU_REQ_DATA[0:CFU_REQ_INPUTS-1] req_data,

    input wire resp_ready,
    output wire resp_valid,
    output wire `CFU_REQ_RESP_ID resp_id,
    output wire `CFU_RESP_DATA[0:CFU_RESP_OUTPUTS-1] resp_data,
    output wire resp_ok,
    output wire `CFU_ERROR_ID resp_error_id
);
    CFUComb #(
        .CFU_FUNCTION_ID_W(CFU_FUNCTION_ID_W),
        .CFU_REQ_INPUTS(CFU_REQ_INPUTS), .CFU_REQ_DATA_W(CFU_REQ_DATA_W),
        .CFU_RESP_OUTPUTS(CFU_RESP_OUTPUTS), .CFU_RESP_DATA_W(CFU_RESP_DATA_W))
    comb(.req_function_id, .req_data, .resp_data);

    assign req_ready = resp_ready;
    assign resp_valid = req_valid;
    assign resp_id = req_id;
    assign resp_ok = 1;
    assign resp_error_id = 0;
endmodule


module CFU_CFUPipelined_Adapter #(
    parameter CFU_VERSION = 0,
    parameter CFU_INTERFACE_ID_W = 16,
    parameter CFU_FUNCTION_ID_W = 16,
    parameter CFU_REORDER_ID_W = 8,
    parameter CFU_REQ_RESP_ID_W = 6,
    parameter CFU_REQ_INPUTS = 2,
    parameter CFU_REQ_DATA_W = 32,
    parameter CFU_RESP_OUTPUTS = 1,
    parameter CFU_RESP_DATA_W = CFU_REQ_DATA_W,
    parameter CFU_ERROR_ID_W = CFU_RESP_DATA_W
) (
    input wire clock,
    input wire reset,
    input wire clock_en,

    output wire req_ready,
    input wire req_valid,
    input wire `CFU_INTERFACE_ID req_interface_id,
    input wire `CFU_FUNCTION_ID req_function_id,
    input wire `CFU_REORDER_ID req_reorder_id,
    input wire `CFU_REQ_RESP_ID req_id,
    input wire `CFU_REQ_DATA[0:CFU_REQ_INPUTS-1] req_data,

    input wire resp_ready,
    output wire resp_valid,
    output wire `CFU_REQ_RESP_ID resp_id,
    output wire `CFU_RESP_DATA[0:CFU_RESP_OUTPUTS-1] resp_data,
    output wire resp_ok,
    output wire `CFU_ERROR_ID resp_error_id
);
    wire pipe_ce = clock_en && req_ready;

    CFUPipelined #(
        .CFU_VERSION(CFU_VERSION),
        .CFU_FUNCTION_ID_W(CFU_FUNCTION_ID_W),
        .CFU_REQ_RESP_ID_W(CFU_REQ_RESP_ID_W),
        .CFU_REQ_INPUTS(CFU_REQ_INPUTS), .CFU_REQ_DATA_W(CFU_REQ_DATA_W),
        .CFU_RESP_OUTPUTS(CFU_RESP_OUTPUTS), .CFU_RESP_DATA_W(CFU_RESP_DATA_W),
        .CFU_ERROR_ID_W(CFU_ERROR_ID_W))
    pipe(.clock, .reset, .clock_en(pipe_ce),
         .req_valid, .req_function_id, .req_id, .req_data,
         .resp_valid, .resp_id, .resp_data, .resp_ok, .resp_error_id);

    // Advance pipeline unless a valid response is awaiting and is not
    // accepted this cycle.
    assign req_ready = !(resp_valid && !resp_ready);
endmodule


module CFUPipelined_CFUComb_Adapter #(
    parameter CFU_VERSION = 0,
    parameter CFU_FUNCTION_ID_W = 16,
    parameter CFU_REQ_RESP_ID_W = 6,
    parameter CFU_REQ_INPUTS = 2,
    parameter CFU_REQ_DATA_W = 32,
    parameter CFU_RESP_OUTPUTS = 1,
    parameter CFU_RESP_DATA_W = CFU_REQ_DATA_W,
    parameter CFU_ERROR_ID_W = CFU_REQ_DATA_W
) (
    input wire clock,
    input wire reset,
    input wire clock_en,

    input wire req_valid,
    input wire `CFU_FUNCTION_ID req_function_id,
    input wire `CFU_REQ_RESP_ID req_id,
    input wire `CFU_REQ_DATA[0:CFU_REQ_INPUTS-1] req_data,

    output wire resp_valid,
    output wire `CFU_REQ_RESP_ID resp_id,
    output wire `CFU_RESP_DATA[0:CFU_RESP_OUTPUTS-1] resp_data,
    output wire resp_ok,
    output wire `CFU_ERROR_ID resp_error_id
);
    CFUComb #(
        .CFU_FUNCTION_ID_W(CFU_FUNCTION_ID_W),
        .CFU_REQ_INPUTS(CFU_REQ_INPUTS), .CFU_REQ_DATA_W(CFU_REQ_DATA_W),
        .CFU_RESP_OUTPUTS(CFU_RESP_OUTPUTS), .CFU_RESP_DATA_W(CFU_RESP_DATA_W))
    comb(.req_function_id, .req_data, .resp_data);

    assign resp_valid = req_valid;
    assign resp_id = req_id;
    assign resp_ok = 1;
    assign resp_error_id = 0;
endmodule
