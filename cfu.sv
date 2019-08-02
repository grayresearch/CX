// Copyright (C) 2019, Gray Research LLC

/* verilator lint_off DECLFILENAME */

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
    input logic clock,
    input logic reset,
    input logic clock_en,

    output logic req_ready,
    input logic req_valid,
    input logic [CFU_INTERFACE_ID_W-1:0] req_interface_id,
    input logic [CFU_FUNCTION_ID_W-1:0] req_function_id,
    input logic [CFU_REORDER_ID_W-1:0] req_reorder_id,
    input logic [CFU_REQ_RESP_ID_W-1:0] req_id,
    input logic [CFU_REQ_INPUTS*CFU_REQ_DATA_W-1:0] req_data,

    input logic resp_ready,
    output logic resp_valid,
    output logic [CFU_REQ_RESP_ID_W-1:0] resp_id,
    output logic [CFU_RESP_OUTPUTS*CFU_RESP_DATA_W-1:0] resp_data,
    output logic resp_ok,
    output logic [CFU_ERROR_ID_W-1:0] resp_error_id
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
    input logic clock,
    input logic reset,
    input logic clock_en,

    input logic req_valid,
    input logic [CFU_FUNCTION_ID_W-1:0] req_function_id,
    input logic [CFU_REQ_RESP_ID_W-1:0] req_id,
    input logic [CFU_REQ_INPUTS*CFU_REQ_DATA_W-1:0] req_data,

    output logic resp_valid,
    output logic [CFU_REQ_RESP_ID_W-1:0] resp_id,
    output logic [CFU_RESP_OUTPUTS*CFU_RESP_DATA_W-1:0] resp_data,
    output logic resp_ok,
    output logic [CFU_ERROR_ID_W-1:0] resp_error_id
);
    localparam N_STAGES = 3;
    typedef logic [CFU_FUNCTION_ID_W-1:0] FnID;
    typedef logic [CFU_REQ_DATA_W-1:0] In;
    typedef logic [CFU_RESP_DATA_W-1:0] Out;
    typedef logic [CFU_REQ_RESP_ID_W-1:0] RespID;
    typedef struct packed {
        logic valid;
        RespID id;
        Out data;
    } PipeStage;

    // assert(VERSION == 0 && CFU_REQ_INPUTS == 2 && CFU_RESP_OUTPUTS == 1);

    function Out Fn(input FnID id, input In i0, input In i1); begin Fn = i0 * i1; end endfunction

    PipeStage [0:N_STAGES-1] pipeline;

    always_ff @(posedge clock) begin
        if (reset) begin
            pipeline <= '0;
        end
        else if (clock_en) begin
            pipeline[0] <= '{ valid: req_valid, id: req_id, data: Fn(req_function_id, req_data[0], req_data[1]) };
            for (i = 1; i < N_STAGES; ++i)
                pipeline[i] <= pipeline[i-1];
        end
    end
    always_comb begin
        resp_valid = pipeline[N_STAGES-1].valid;
        resp_id = pipeline[N_STAGES-1].id;
        resp_data[0] = pipeline[N_STAGES-1].data;
        resp_ok = 1;
        resp_error_id = '0;
    end
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
    input logic [CFU_FUNCTION_ID_W-1:0] req_function_id,
    input logic [CFU_REQ_INPUTS*CFU_REQ_DATA_W-1:0] req_data,
    output logic [CFU_RESP_OUTPUTS*CFU_RESP_DATA_W-1:0] resp_data
);
    typedef logic [CFU_FUNCTION_ID_W-1:0] FnID;
    typedef logic [CFU_REQ_DATA_W-1:0] In;
    typedef logic [CFU_RESP_DATA_W-1:0] Out;

    function Out Fn(input FnID id, input In i0, input In i1); begin Fn = i0 * i1; end endfunction

    always_comb resp_data[0] = Fn(req_function_id, req_data[0], req_data[1]);
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
    input logic clock,
    input logic reset,
    input logic clock_en,

    output logic req_ready,
    input logic req_valid,
    input logic [CFU_INTERFACE_ID_W-1:0] req_interface_id,
    input logic [CFU_FUNCTION_ID_W-1:0] req_function_id,
    input logic [CFU_REORDER_ID_W-1:0] req_reorder_id,
    input logic [CFU_REQ_RESP_ID_W-1:0] req_id,
    input logic [CFU_REQ_INPUTS*CFU_REQ_DATA_W-1:0] req_data,

    input logic resp_ready,
    output logic resp_valid,
    output logic [CFU_REQ_RESP_ID_W-1:0] resp_id,
    output logic [CFU_RESP_OUTPUTS*CFU_RESP_DATA_W-1:0] resp_data,
    output logic resp_ok,
    output logic [CFU_ERROR_ID_W-1:0] resp_error_id
);
    CFUComb #(
        .CFU_FUNCTION_ID_W(CFU_FUNCTION_ID_W),
        .CFU_REQ_INPUTS(CFU_REQ_INPUTS), .CFU_REQ_DATA_W(CFU_REQ_DATA_W),
        .CFU_RESP_OUTPUTS(CFU_RESP_OUTPUTS), .CFU_RESP_DATA_W(CFU_RESP_DATA_W))
    comb(.req_function_id, .req_data, .resp_data);

    always_comb begin
        req_ready = resp_ready;
        resp_valid = req_valid;
        resp_id = req_id;
        resp_ok = 1;
        resp_error_id = '0;
    end
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
    input logic clock,
    input logic reset,
    input logic clock_en,

    output logic req_ready,
    input logic req_valid,
    input logic [CFU_INTERFACE_ID_W-1:0] req_interface_id,
    input logic [CFU_FUNCTION_ID_W-1:0] req_function_id,
    input logic [CFU_REORDER_ID_W-1:0] req_reorder_id,
    input logic [CFU_REQ_RESP_ID_W-1:0] req_id,
    input logic [CFU_REQ_INPUTS*CFU_REQ_DATA_W-1:0] req_data,

    input logic resp_ready,
    output logic resp_valid,
    output logic [CFU_REQ_RESP_ID_W-1:0] resp_id,
    output logic [CFU_RESP_OUTPUTS*CFU_RESP_DATA_W-1:0] resp_data,
    output logic resp_ok,
    output logic [CFU_ERROR_ID_W-1:0] resp_error_id
);
    logic pipe_ce;

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
    always_comb req_ready = !(resp_valid && !resp_ready);
    always_comb pipe_ce = clock_en && req_ready;
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
    input logic clock,
    input logic reset,
    input logic clock_en,

    input logic req_valid,
    input logic [CFU_FUNCTION_ID_W-1:0] req_function_id,
    input logic [CFU_REQ_RESP_ID_W-1:0] req_id,
    input logic [CFU_REQ_INPUTS*CFU_REQ_DATA_W-1:0] req_data,

    output logic resp_valid,
    output logic [CFU_REQ_RESP_ID_W-1:0] resp_id,
    output logic [CFU_RESP_OUTPUTS*CFU_RESP_DATA_W-1:0] resp_data,
    output logic resp_ok,
    output logic [CFU_ERROR_ID_W-1:0] resp_error_id
);
    CFUComb #(
        .CFU_FUNCTION_ID_W(CFU_FUNCTION_ID_W),
        .CFU_REQ_INPUTS(CFU_REQ_INPUTS), .CFU_REQ_DATA_W(CFU_REQ_DATA_W),
        .CFU_RESP_OUTPUTS(CFU_RESP_OUTPUTS), .CFU_RESP_DATA_W(CFU_RESP_DATA_W))
    comb(.req_function_id, .req_data, .resp_data);

    always_comb begin
        resp_valid = req_valid;
        resp_id = req_id;
        resp_ok = 1;
        resp_error_id = '0;
    end
endmodule
