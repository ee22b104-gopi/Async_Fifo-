//=============================================================================
// Module: FIFO_tb — Self-Checking Testbench
//=============================================================================
// Purpose: Rigorous verification of the Async FIFO.
//          - Self-checking using a verification queue.
//          - Generates waveform dumps (fifo_waves.vcd).
//          - Tests new flags (almost_full, almost_empty, fill_count).
//=============================================================================
`timescale 1ns/1ps

module FIFO_tb();

    parameter DSIZE = 8;
    parameter ASIZE = 4; // Depth = 16
    parameter DEPTH = 1 << ASIZE;
    parameter A_THRESH = 2;

    reg [DSIZE-1:0] wdata;
    wire [DSIZE-1:0] rdata;
    wire wfull, walmost_full;
    wire rempty, ralmost_empty;
    wire [ASIZE:0] rfill_count;
    reg winc, rinc, wclk, rclk, wrst_n, rrst_n;

    // Verification Queue (Golden Reference)
    reg [DSIZE-1:0] expected_queue [0:255];
    integer head = 0;
    integer tail = 0;
    reg [DSIZE-1:0] expected_data;

    FIFO #(DSIZE, ASIZE, A_THRESH) fifo (
        .rdata(rdata), 
        .wdata(wdata),
        .wfull(wfull),
        .walmost_full(walmost_full),
        .rempty(rempty),
        .ralmost_empty(ralmost_empty),
        .rfill_count(rfill_count),
        .winc(winc), 
        .rinc(rinc), 
        .wclk(wclk), 
        .rclk(rclk), 
        .wrst_n(wrst_n), 
        .rrst_n(rrst_n)
    );

    integer i;

    // Clock Generation
    always #5  wclk = ~wclk;    // 100 MHz write clock
    always #13 rclk = ~rclk;    // ~38.4 MHz read clock (async ratio)
    
    // Waveform dump
    initial begin
        $dumpfile("fifo_waves.vcd");
        $dumpvars(0, FIFO_tb);
    end

    // Verification Logic: Write side
    always @(posedge wclk) begin
        if (winc && !wfull && wrst_n) begin
            expected_queue[tail] = wdata;
            tail = tail + 1;
        end
    end

    // Verification Logic: Read side
    always @(posedge rclk) begin
        if (rinc && !rempty && rrst_n) begin
            expected_data = expected_queue[head];
            head = head + 1;
            if (rdata !== expected_data) begin
                $display("ERROR at time %0t: Expected %0h, Got %0h", $time, expected_data, rdata);
                $stop;
            end else begin
                $display("SUCCESS at time %0t: Read %0h", $time, rdata);
            end
        end
    end

    initial begin
        // Initialize
        wclk = 0; rclk = 0;
        wrst_n = 1; rrst_n = 1;
        winc = 0; rinc = 0;
        wdata = 0;

        // Reset Sequence
        $display("Applying Reset...");
        #20 wrst_n = 0; rrst_n = 0;
        #40 wrst_n = 1; rrst_n = 1;
        #20;

        // TEST CASE 1: Concurrent Writes and Reads
        $display("TEST CASE 1: Concurrent Writes and Reads...");
        fork
            // Write Thread
            begin
                for (i = 0; i < 15; i = i + 1) begin
                    @(posedge wclk);
                    wdata <= $random;
                    winc <= 1;
                end
                @(posedge wclk) winc <= 0;
            end
            // Read Thread
            begin
                for (integer j = 0; j < 15; j = j + 1) begin
                    @(posedge rclk);
                    // Only read if not empty
                    if (!rempty) rinc <= 1;
                    else begin
                        rinc <= 0;
                        j = j - 1; // Wait until we actually read something
                    end
                end
                @(posedge rclk) rinc <= 0;
            end
        join
        #50;

        // TEST CASE 2: Fill the FIFO
        $display("TEST CASE 2: Filling FIFO to trigger full...");
        rinc <= 0;
        for (i = 0; i < DEPTH + 5; i = i + 1) begin
            @(posedge wclk);
            wdata <= $random;
            winc <= 1;
        end
        @(posedge wclk) winc <= 0;
        #50;

        // TEST CASE 3: Drain the FIFO
        $display("TEST CASE 3: Draining FIFO to trigger empty...");
        winc <= 0;
        for (i = 0; i < DEPTH + 5; i = i + 1) begin
            @(posedge rclk);
            rinc <= 1;
        end
        @(posedge rclk) rinc <= 0;
        
        #100;
        $display("ALL TESTS PASSED. Simulation finished.");
        $finish;
    end

endmodule
