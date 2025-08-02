`default_nettype none
`timescale 1ns / 1ps

/* This testbench just instantiates the module and makes some convenient wires
   that can be driven / tested by the cocotb test.py.
*/
module tb ();
  // Dump the signals to a VCD file. You can view it with gtkwave or surfer.
  initial begin
    $dumpfile("tb.vcd");
    $dumpvars(0, tb);
  end

  // Wire up the inputs and outputs:
  reg clk;
  reg rst_n;
  reg ena;
  reg [7:0] ui_in;
  reg [7:0] uio_in;
  wire [7:0] uo_out;
  wire [7:0] uio_out;
  wire [7:0] uio_oe;

  // Replace tt_um_example with your module name:
  tt_um_example user_project (
      .ui_in  (ui_in),    // Dedicated inputs
      .uo_out (uo_out),   // Dedicated outputs
      .uio_in (uio_in),   // IOs: Input path
      .uio_out(uio_out),  // IOs: Output path
      .uio_oe (uio_oe),   // IOs: Enable path (active high: 0=input, 1=output)
      .ena    (ena),      // enable - goes high when design is selected
      .clk    (clk),      // clock
      .rst_n  (rst_n)     // not reset
  );

  // Clock generation
  initial begin
    clk = 0;
    forever #5 clk = ~clk; // 100MHz clock (10ns period)
  end

  // Test stimulus
  initial begin
    // Initialize signals
    ui_in = 8'b0;
    uio_in = 8'b0;
    ena = 1'b1;
    rst_n = 1'b0;
    
    // Hold reset for a few clock cycles
    #20;
    rst_n = 1'b1; // Release reset
    
    // Monitor processor execution for several clock cycles
    repeat(20) begin
      @(posedge clk);
      #1; // Small delay for signal settling
      $display("%0t\t|   %b   | %3d |   %3d   |    %8b |   %2b   |   %2b   |    %b", 
               $time, ~rst_n, uio_out, uo_out, 
               user_project.processor.data, user_project.processor.opcode, 
               user_project.processor.alu_op, user_project.processor.reg_write);
    end
    
    // Test reset functionality
    $display("\n--- Testing Reset ---");
    rst_n = 1'b0;
    #10;
    rst_n = 1'b1;
    
    repeat(5) begin
      @(posedge clk);
      #1;
      $display("%0t\t|   %b   | %3d |   %3d   |    %8b |   %2b   |   %2b   |    %b", 
               $time, ~rst_n, uio_out, uo_out, 
               user_project.processor.data, user_project.processor.opcode, 
               user_project.processor.alu_op, user_project.processor.reg_write);
    end
    
    $display("\n--- Test Complete ---");
    #10000 $finish;
  end

  // Monitor register file changes
  initial begin
    $display("\n--- Register File Initial Values ---");
    #25; // Wait for reset to complete
    for (integer i = 0; i < 8; i = i + 1) begin
      $display("Register[%0d] = %8b (%3d)", i, 
               user_project.processor.rf.registers[i], 
               user_project.processor.rf.registers[i]);
    end
    
    // Monitor register changes during execution
    $display("\n--- Monitoring Register Changes ---");
    forever begin
      @(posedge user_project.processor.reg_write);
      @(posedge clk);
      #1;
      $display("Register[%0d] updated to %8b (%3d) at time %0t", 
               user_project.processor.rd, 
               user_project.processor.rf.registers[user_project.processor.rd],
               user_project.processor.rf.registers[user_project.processor.rd],
               $time);
    end
  end

  // Additional monitoring for debugging
  initial begin
    #30; // Start after reset
    $display("\n--- Detailed Execution Trace ---");

    repeat(15) begin
      @(posedge clk);
      #1;
      $display("  %2d  |%3d | %8b| %2b |%2d  |%2d  |%2d  |  %3d    |   %3d   |    %3d", 
               (uio_out + 1), uio_out, user_project.processor.data, user_project.processor.opcode,
               user_project.processor.rs, user_project.processor.rt, user_project.processor.rd,
               user_project.processor.rs_data, user_project.processor.rt_data, uo_out);
    end
  end

endmodule
