//=============================================================================
// Module: FIFO — Top-Level Asynchronous FIFO
//=============================================================================
// Purpose: Wraps the dual-port RAM, pointer handlers, and synchronizers.
//          Added 'almost_full', 'almost_empty', and 'rfill_count' ports.
//=============================================================================

module FIFO #(parameter DSIZE = 8, parameter ASIZE = 4, parameter A_THRESH = 2)(
    output [DSIZE-1:0] rdata,
    output             wfull,
    output             walmost_full,
    output             rempty,
    output             ralmost_empty,
    output [ASIZE:0]   rfill_count,
    input  [DSIZE-1:0] wdata,
    input              winc, wclk, wrst_n,
    input              rinc, rclk, rrst_n
);

    wire [ASIZE-1:0] waddr, raddr;
    wire [ASIZE:0]   wptr, rptr, wq2_rptr, rq2_wptr;

    // Synchronize rptr into write domain (wq2_rptr)
    two_ff_sync #(ASIZE+1) sync_r2w (
        .q2(wq2_rptr), 
        .din(rptr),
        .clk(wclk), 
        .rst_n(wrst_n)
    );

    // Synchronize wptr into read domain (rq2_wptr)
    two_ff_sync #(ASIZE+1) sync_w2r (
        .q2(rq2_wptr), 
        .din(wptr),
        .clk(rclk), 
        .rst_n(rrst_n)
    );

    // Dual-port memory
    FIFO_memory #(DSIZE, ASIZE) fifomem(
        .rdata(rdata), 
        .wdata(wdata),
        .waddr(waddr), 
        .raddr(raddr),
        .wclk_en(winc), 
        .wfull(wfull),
        .wclk(wclk)
    );

    // Read pointer & empty logic
    rptr_empty #(ASIZE, A_THRESH) rptr_empty(
        .rempty(rempty),
        .ralmost_empty(ralmost_empty),
        .rfill_count(rfill_count),
        .raddr(raddr),
        .rptr(rptr), 
        .rq2_wptr(rq2_wptr),
        .rinc(rinc), 
        .rclk(rclk),
        .rrst_n(rrst_n)
    );

    // Write pointer & full logic
    wptr_full #(ASIZE, A_THRESH) wptr_full(
        .wfull(wfull), 
        .walmost_full(walmost_full),
        .waddr(waddr),
        .wptr(wptr), 
        .wq2_rptr(wq2_rptr),
        .winc(winc), 
        .wclk(wclk),
        .wrst_n(wrst_n)
    );

endmodule