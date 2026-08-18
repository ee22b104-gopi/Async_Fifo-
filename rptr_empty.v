//=============================================================================
// Module: rptr_empty — Read Pointer & Empty Flag Generator
//=============================================================================
// Purpose: Handles read domain logic.
//          - Maintains binary read pointer for memory addressing.
//          - Maintains Gray-coded read pointer to cross to write domain.
//          - Generates 'rempty' flag by comparing Gray read pointer with
//            the synchronized Gray write pointer.
//          - NEW: Generates 'ralmost_empty' flag based on threshold.
//          - NEW: Generates 'rfill_count' (approximate fill level from read domain).
//=============================================================================

module rptr_empty #(parameter ADDR_SIZE = 4, parameter ALMOST_EMPTY_THRESH = 2)(
    output reg                  rempty,
    output reg                  ralmost_empty,
    output [ADDR_SIZE:0]        rfill_count,
    output [ADDR_SIZE-1:0]      raddr,
    output reg [ADDR_SIZE:0]    rptr,
    input  [ADDR_SIZE:0]        rq2_wptr, // Synchronized Gray write pointer
    input                       rinc, rclk, rrst_n
);

    reg  [ADDR_SIZE:0] rbin;
    wire [ADDR_SIZE:0] rgray_next, rbin_next;
    wire rempty_val, ralmost_empty_val;
    
    // Internal wire for binary write pointer
    wire [ADDR_SIZE:0] wptr_bin;

    // Synchronous Read Pointer Updates
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n)
            {rbin, rptr} <= 0;
        else
            {rbin, rptr} <= {rbin_next, rgray_next};
    end

    // Binary next state & memory address
    assign raddr      = rbin[ADDR_SIZE-1:0];
    assign rbin_next  = rbin + (rinc & ~rempty);
    
    // Binary to Gray conversion
    assign rgray_next = (rbin_next >> 1) ^ rbin_next;

    // Empty Condition: pointers match exactly
    assign rempty_val = (rgray_next == rq2_wptr);

    // Gray to Binary conversion for rq2_wptr (used for fill count & almost empty)
    genvar i;
    generate
        for (i = 0; i <= ADDR_SIZE; i = i + 1) begin : gray_to_bin_block
            assign wptr_bin[i] = ^(rq2_wptr >> i);
        end
    endgenerate

    // Fill Count (from read domain perspective)
    assign rfill_count = wptr_bin - rbin_next;

    // Almost Empty Condition
    assign ralmost_empty_val = (rfill_count <= ALMOST_EMPTY_THRESH);

    // Registering flags for clean outputs
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rempty        <= 1'b1;
            ralmost_empty <= 1'b1;
        end else begin
            rempty        <= rempty_val;
            ralmost_empty <= ralmost_empty_val;
        end
    end

endmodule