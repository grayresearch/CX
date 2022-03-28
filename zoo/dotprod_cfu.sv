// dotprod_cfu.sv: dot product of vectors of elements, a serializable stateful fixed latency
// (CFU-L1) CFU
//
// Copyright (C) 2019-2022, Gray Research LLC.
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

// IDotProduct inherits IObjectContext custom functions:
//     0:   dotprod
//     1:   dotprod-acc
//     *:   error
//  1020:   cfid_write_state
//  1021:   cfid_read_state
//  1022:   cfid_write_status
//  1023:   cfid_read_status

`include "common.svh"
`include "cfu.svh"

/* verilator lint_off DECLFILENAME */

// dotprod_cfu: 32/64-bit stateful serializable fixed latency (CFU-L1) CFU
module dotprod_cfu
    import common_pkg::*;
    import cfu_pkg::*;
#(
    `CFU_L1_PARAMS(/*N_CFUS*/1, /*N_STATES*/1, /*LATENCY*/0, /*RESET_LATENCY*/0,
        /*FUNC_ID_W*/10, /*DATA_W*/32),
    parameter int ELEM_W    = 8
) (
    `CFU_L1_ALL_PORTS(input, output, req, resp)
);
    typedef `V(CFU_FUNC_ID_W)   func_id_t;
    typedef `V(CFU_STATE_ID_W)  state_id_t;
    typedef `V(CFU_DATA_W)      data_t;

    initial begin
        ignore(
            check_cfu_l1_params("dotprod_cfu", CFU_LI_VERSION, CFU_N_CFUS,
                CFU_LATENCY, CFU_RESET_LATENCY, CFU_CFU_ID_W, CFU_STATE_ID_W,
                CFU_FUNC_ID_W, CFU_DATA_W)
        &&  check_param_pos("dotprod_cfu", "CFU_N_STATES", CFU_N_STATES)
        &&  check_param("dotprod_cfu", "CFU_FUNC_ID_W", CFU_FUNC_ID_W, $bits(cfid_t))
        &&  check_param_expr("dotprod_cfu", "ELEM_W", ELEM_W,
              (2**$clog2(ELEM_W) == ELEM_W && 1 <= ELEM_W && ELEM_W <= CFU_DATA_W),
              "must be power of 2"));
    end
    wire _unused_ok = &{1'b0,req_cfu,1'b0};
`ifdef DOTPROD_CFU_VCD
    initial begin $dumpfile("dotprod_cfu.vcd"); $dumpvars(0, dotprod_cfu); end
`endif
    typedef enum logic[$bits(cfid_t)-1:0] {
        cfid_dotprod    = 0,             // acc = dotproduct-elementwise(data0,data1)
        cfid_dotprodacc = 1              // acc += dotproduct-elementwise(data0,data1)
        // + IStateContext's standard CF_IDs
    } dotprod_cfid_t;                    // IDotProd CF_IDs

    // state contexts
    logic [CFU_N_STATES-1:0][1:0] css;// context statuses (flops)
    logic [CFU_N_STATES-1:0] zaccs; // zero'd-accumulators (flops)
    data_t accs[CFU_N_STATES];      // accumulators (prob. LUT-RAM)
    // Cannot flash clear accs[*] on reset. Flash set zero-indicators zaccs[*] instead.

    // elementwise products
    logic [CFU_DATA_W/ELEM_W-1:0][2*ELEM_W-1:0] prods;
    // type of sum of products, no overflow, unless capped at CFU_DATA_W
    localparam int DOTP_W = min(2*ELEM_W + $clog2(CFU_DATA_W/ELEM_W), CFU_DATA_W);
    typedef logic [DOTP_W-1:0] dotp_t;
    dotp_t      dotp_0;                 // dot product (current cycle)

    // Multiply elementwise products. Awkward construction, but keeps icarus happy.
    for (genvar i = 0; i < CFU_DATA_W/ELEM_W; ++i)
        assign prods[i] = req_data0[(i+1)*ELEM_W-1:i*ELEM_W] * req_data1[(i+1)*ELEM_W-1:i*ELEM_W];
    always_comb begin
        // model a combinational dot product feeding a shift register, relying upon synthesis
        // and pipeline retiming to optimize this datapath, potentially into cascaded DSPs
        dotp_0 = '0;
        for (int i = 0; i < CFU_DATA_W/ELEM_W; ++i)
            dotp_0 = dotp_0 + dotp_t'(prods[i]);
    end

    // fixed latency pipeline: shift registers' inputs and outputs
    func_id_t   func;                   // function ID             (+CFU_LATENCY cycles)
    state_id_t  state_raw;              // raw state ID            (+CFU_LATENCY cycles)
    dotp_t      dotp;                   // dot product             (+CFU_LATENCY cycles)
    data_t      wr_data;                // write data value        (+CFU_LATENCY cycles)
    state_id_t  state;                  // bounds-checked state ID (+CFU_LATENCY cycles)

    localparam int N = CFU_LATENCY;
    shift_reg #(.W(1),                 .N(N)) valid_  (.clk, .rst, .clk_en, .d(req_valid), .q(resp_valid));
    shift_reg #(.W($bits(func_id_t)),  .N(N)) func_   (.clk, .rst, .clk_en, .d(req_func),  .q(func));
    shift_reg #(.W($bits(state_id_t)), .N(N)) state_  (.clk, .rst, .clk_en, .d(req_state), .q(state_raw));
    shift_reg #(.W($bits(dotp_t)),     .N(N)) dotp_   (.clk, .rst, .clk_en, .d(dotp_0),    .q(dotp));
    shift_reg #(.W($bits(data_t)),     .N(N)) wr_data_(.clk, .rst, .clk_en, .d(req_data0), .q(wr_data));
    // (when N==0, shift_reg is a 0-stage shift register, i.e. just wires)

    // Compute response and update current accumulator and context status state.
    // All state access happens as the product emerges from the mult. pipeline.
    // This block is structured to minimize edge-case control signals from impacting
    // logic-intensive case statement datapath that computes resp_data.
    // Besides resp_*, block computes wr and cs for the sync state update block below.
    logic       wr;                     // state write enable
    cfu_cs_t    cs_nxt;                 // next CSW.CS (when func is cfid_write_status)

    always_comb begin
        cfu_csw_t   csw;                // current state context status word
        data_t      acc;                // accumulator value, or zero when zaccs[state]

        // clamp state index here to keep simulation clean; CFU_ERROR_STATE check is later
        state = (int'(state_raw) < CFU_N_STATES) ? state_raw : 0;

        // current and possible new context status words
        csw = '0; csw.state_size = 1; csw.cs = css[state];
        cs_nxt = cfu_cs_t'(wr_data);

        // select response
        resp_status = CFU_OK;           // default
        acc = zaccs[state] ? '0 : accs[state];
        case (func)
        cfid_dotprod:       begin wr = 1; resp_data = data_t'(dotp);          end
        cfid_dotprodacc:    begin wr = 1; resp_data = acc + data_t'(dotp);    end
        cfid_read_status:   begin wr = 0; resp_data = data_t'(csw);           end
        cfid_write_status:  begin wr = 1; resp_data = data_t'(csw);           end
        cfid_read_state:    begin wr = 0; resp_data = acc;                    end
        cfid_write_state:   begin wr = 1; resp_data = wr_data;                end
        default:            begin wr = 0; resp_data = data_t'(dotp); resp_status = CFU_ERROR_FUNC; end
        endcase

        // error cases, can overrule above CFU_ERROR_FUNC
        if (!resp_valid) begin
            // non-requests are ignored, no side effects
            resp_status = CFU_OK;       // not strictly necessary
            wr = 0;
        end
        else if (int'(state_raw) >= CFU_N_STATES) begin
            // invalid state index
            resp_status = CFU_ERROR_STATE;
            wr = 0;
        end
        else if (css[state] == CFU_OFF && !(func==cfid_read_status || func==cfid_write_status)) begin
            // valid state context, but it's turned off
            resp_status = CFU_ERROR_OFF;
            wr = 0;
        end
    end
    // reset or update state
    always_ff @(posedge clk) begin
        if (rst) begin
            // reset all state contexts to init status, with all accumulators zero
            css <= {CFU_N_STATES{CFU_INIT}};
            zaccs <= '1;
        end
        else if (clk_en && wr) begin
            if (func == cfid_write_status) begin
                css[state] <= cs_nxt;
                // when context status becomes off or init, logically zero this state's accumulator
                if (cs_nxt == CFU_OFF || cs_nxt == CFU_INIT)
                    zaccs[state] <= 1;
            end
            else begin
                // context status becomes dirty when state is updated
                css[state] <= CFU_DIRTY;
                zaccs[state] <= 0;
                accs[state] <= resp_data;
            end
        end
    end
endmodule
