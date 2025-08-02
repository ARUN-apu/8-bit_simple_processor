`timescale 1ns / 1ps
`default_nettype none

// Program Counter Module
module Program_counter(
    input clk,
    input rst,
    input [7:0] pc_in,
    output reg [7:0] pc_out
);
    always @(posedge clk or posedge rst) begin
        if (rst)
            pc_out <= 8'b0;
        else
            pc_out <= pc_in;
    end
endmodule

// Instruction Memory Module
module instruction_memory(
    input [7:0] addr,
    output reg [7:0] data
);
    reg [7:0] memory [0:255];
    
    initial begin
        memory[0] = 8'b00000001;
        memory[1] = 8'b01000010;
        memory[2] = 8'b10000011;
        memory[3] = 8'b11000100;
        memory[4] = 8'b11001001;
        memory[5] = 8'b01000110;
        memory[6] = 8'b10000111;
        memory[7] = 8'b00000000;
        // Initialize remaining memory to 0
        for (integer i = 8; i < 256; i = i + 1) begin
            memory[i] = 8'b0;
        end
    end
    
    always @(*) begin
        data = memory[addr];
    end
endmodule

// Control Unit Module
module control_unit(
    input [1:0] opcode,
    output reg [1:0] alu_op,
    output reg reg_write,
    output reg pc_write
);
    always @(*) begin
        // Default values
        alu_op = 2'b00;
        reg_write = 1'b0;
        pc_write = 1'b0;
        
        case (opcode)
            2'b00: begin // Add
                alu_op = 2'b01;
                reg_write = 1'b1;
            end
            2'b01: begin // Sub
                alu_op = 2'b10;
                reg_write = 1'b1;
            end
            2'b10: begin // OR
                alu_op = 2'b11;
                reg_write = 1'b1;
            end
            default: begin
                alu_op = 2'b00;
                reg_write = 1'b0;
                pc_write = 1'b0;
            end
        endcase
    end
endmodule

// Register File Module
module Register_file(
    input clk,
    input [1:0] rs,
    input [1:0] rt,
    input [1:0] rd,
    input [7:0] write_data,
    input reg_write,
    output [7:0] rs_data,
    output [7:0] rt_data
);
    reg [7:0] registers [0:7];
    
    initial begin
        registers[0] = 8'b00110000;
        registers[1] = 8'b01000011;
        registers[2] = 8'b10111100;
        registers[3] = 8'b11110010;
        registers[4] = 8'b11001011;
        registers[5] = 8'b10111100;
        registers[6] = 8'b01110011;
        registers[7] = 8'b00111111;
    end
    
    assign rs_data = registers[rs];
    assign rt_data = registers[rt];
    
    always @(posedge clk) begin
        if (reg_write) begin
            registers[rd] <= write_data;
        end
    end
endmodule

// ALU Module
module Alu(
    input [7:0] rs,
    input [7:0] rt,
    input [1:0] alu_op,
    output reg [7:0] result
);
    always @(*) begin
        case (alu_op)
            2'b01:   result = rs + rt;
            2'b10:   result = rs - rt;
            2'b11:   result = rs | rt;
            default: result = 8'b0;
        endcase
    end
endmodule

// Simple 8-bit Processor Module
module Simple_8bit_Processor(
    input clk,
    input rst,
    output [7:0] pc_out,
    output [7:0] data,
    output [1:0] opcode,
    output [1:0] alu_op,
    output reg_write,
    output pc_write,
    output [7:0] rs_data,
    output [7:0] rt_data,
    output [7:0] result
);
    wire [7:0] pc_in;
    wire [1:0] rs, rt, rd;
    
    Program_counter pc(
        .clk(clk),
        .rst(rst),
        .pc_in(pc_in),
        .pc_out(pc_out)
    );
    
    instruction_memory im(
        .addr(pc_out),
        .data(data)
    );
    
    assign opcode = data[7:6];
    assign rs = data[5:4];
    assign rt = data[3:2];
    assign rd = data[1:0];
    
    control_unit cu(
        .opcode(opcode),
        .alu_op(alu_op),
        .reg_write(reg_write),
        .pc_write(pc_write)
    );
    
    Register_file rf(
        .clk(clk),
        .rs(rs),
        .rt(rt),
        .rd(rd),
        .write_data(result),
        .reg_write(reg_write),
        .rs_data(rs_data),
        .rt_data(rt_data)
    );
    
    Alu alu(
        .rs(rs_data),
        .rt(rt_data),
        .alu_op(alu_op),
        .result(result)
    );
    
    assign pc_in = pc_write ? result : pc_out + 8'b1;
endmodule

// TinyTapeout Top Module with 8-bit Processor Integration
module tt_um_example (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

    // Internal wires for processor connections
    wire rst;
    wire [7:0] pc_out;
    wire [7:0] instruction_data;
    wire [1:0] opcode;
    wire [1:0] alu_op;
    wire reg_write;
    wire pc_write;
    wire [7:0] rs_data;
    wire [7:0] rt_data;
    wire [7:0] alu_result;
    
    // Convert active-low reset to active-high reset
    assign rst = ~rst_n;
    
    // Instantiate the 8-bit processor
    Simple_8bit_Processor processor(
        .clk(clk),
        .rst(rst),
        .pc_out(pc_out),
        .data(instruction_data),
        .opcode(opcode),
        .alu_op(alu_op),
        .reg_write(reg_write),
        .pc_write(pc_write),
        .rs_data(rs_data),
        .rt_data(rt_data),
        .result(alu_result)
    );
    
    // Output assignments - showing processor state on outputs
    assign uo_out = alu_result;  // Main output shows ALU result
    
    // Use bidirectional IOs to show additional processor state
    assign uio_out[7:0] = pc_out;  // Show program counter on bidirectional outputs
    assign uio_oe = 8'hFF;         // Set all bidirectional pins as outputs
    
    // List all unused inputs to prevent warnings
    wire _unused = &{ena, ui_in, uio_in, instruction_data, opcode, alu_op, 
                     reg_write, pc_write, rs_data, rt_data, 1'b0};

endmodule
