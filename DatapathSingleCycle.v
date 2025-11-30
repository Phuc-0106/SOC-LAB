`timescale 1ns / 1ns

// registers are 32 bits in RV32
`define REG_SIZE 31

// RV opcodes are 7 bits
`define OPCODE_SIZE 6

// Don't forget your previous ALUs
`include "divu.v"
`include "cla.v"

module RegFile (
    input      [        4:0] rd,
    input      [`REG_SIZE:0] rd_data,
    input      [        4:0] rs1,
    output reg [`REG_SIZE:0] rs1_data,
    input      [        4:0] rs2,
    output reg [`REG_SIZE:0] rs2_data,
    input                    clk,
    input                    we,
    input                    rst
);
  localparam NumRegs = 32;
  // TODO: your code here
  reg [`REG_SIZE:0] regs [0:NumRegs-1]; // was wire -> must be reg
  integer i;

  always @(posedge clk) begin
    if (rst) begin
      for (i = 0; i < NumRegs; i = i + 1) begin
        regs[i] <= 32'b0;
      end
    end else if (we && rd != 5'd0) begin
      regs[rd] <= rd_data;
    end
  end

  always @* begin
    rs1_data = (rs1 == 5'd0) ? 32'b0 : regs[rs1];
    rs2_data = (rs2 == 5'd0) ? 32'b0 : regs[rs2];
  end

endmodule

module DatapathSingleCycle (
    input                    clk,
    input                    rst,
    output reg               halt,
    output     [`REG_SIZE:0] pc_to_imem,
    input      [`REG_SIZE:0] inst_from_imem,
    // addr_to_dmem is a read-write port
    output reg [`REG_SIZE:0] addr_to_dmem,
    input      [`REG_SIZE:0] load_data_from_dmem,
    output reg [`REG_SIZE:0] store_data_to_dmem,
    output reg [        3:0] store_we_to_dmem
);
//carry look-ahead adder
  wire [31:0] cla_sum;
  wire        cla_cout;

  cla cla_unit (
      .a       (alu_a),
      .b       (alu_b),
      .c0      (1'b0),
      .sum     (cla_sum),
      .cout    (cla_cout)
  );
  //Divider
  wire [`REG_SIZE:0] div_quotient, div_remainder;
  divu unit (
      .dividend   (rs1_data),
      .divisor    (rs2_data),
      .quotient   (div_quotient),
      .remainder  (div_remainder)
  );  
  // components of the instruction
  wire [           6:0] inst_funct7;
  wire [           4:0] inst_rs2;
  wire [           4:0] inst_rs1;
  wire [           2:0] inst_funct3;
  wire [           4:0] inst_rd;
  wire [`OPCODE_SIZE:0] inst_opcode;

  // split R-type instruction - see section 2.2 of RiscV spec
  assign {inst_funct7, inst_rs2, inst_rs1, inst_funct3, inst_rd, inst_opcode} = inst_from_imem;

  // setup for I, S, B & J type instructions
  // I - short immediates and loads
  wire [11:0] imm_i;
  assign imm_i = inst_from_imem[31:20];
  wire [ 4:0] imm_shamt = inst_from_imem[24:20];

  // S - stores
  wire [11:0] imm_s;
  assign imm_s = {inst_funct7, inst_rd};

  // B - conditionals
  wire [12:0] imm_b;
  assign {imm_b[12], imm_b[10:1], imm_b[11], imm_b[0]} = {inst_funct7, inst_rd, 1'b0};

  // J - unconditional jumps
  wire [20:0] imm_j;
  assign {imm_j[20], imm_j[10:1], imm_j[11], imm_j[19:12], imm_j[0]} = {inst_from_imem[31:12], 1'b0};

  wire [`REG_SIZE:0] imm_i_sext = {{20{imm_i[11]}}, imm_i[11:0]};
  wire [`REG_SIZE:0] imm_s_sext = {{20{imm_s[11]}}, imm_s[11:0]};
  wire [`REG_SIZE:0] imm_b_sext = {{19{imm_b[12]}}, imm_b[12:0]};
  wire [`REG_SIZE:0] imm_j_sext = {{11{imm_j[20]}}, imm_j[20:0]};

  // opcodes - see section 19 of RiscV spec
  localparam [`OPCODE_SIZE:0] OpLoad    = 7'b00_000_11;
  localparam [`OPCODE_SIZE:0] OpStore   = 7'b01_000_11;
  localparam [`OPCODE_SIZE:0] OpBranch  = 7'b11_000_11;
  localparam [`OPCODE_SIZE:0] OpJalr    = 7'b11_001_11;
  localparam [`OPCODE_SIZE:0] OpMiscMem = 7'b00_011_11;
  localparam [`OPCODE_SIZE:0] OpJal     = 7'b11_011_11;

  localparam [`OPCODE_SIZE:0] OpRegImm  = 7'b00_100_11;
  localparam [`OPCODE_SIZE:0] OpRegReg  = 7'b01_100_11;
  localparam [`OPCODE_SIZE:0] OpEnviron = 7'b11_100_11;

  localparam [`OPCODE_SIZE:0] OpAuipc   = 7'b00_101_11;
  localparam [`OPCODE_SIZE:0] OpLui     = 7'b01_101_11;

  wire inst_lui    = (inst_opcode == OpLui    );
  wire inst_auipc  = (inst_opcode == OpAuipc  );
  wire inst_jal    = (inst_opcode == OpJal    );
  wire inst_jalr   = (inst_opcode == OpJalr   );

  wire inst_beq    = (inst_opcode == OpBranch ) & (inst_from_imem[14:12] == 3'b000);
  wire inst_bne    = (inst_opcode == OpBranch ) & (inst_from_imem[14:12] == 3'b001);
  wire inst_blt    = (inst_opcode == OpBranch ) & (inst_from_imem[14:12] == 3'b100);
  wire inst_bge    = (inst_opcode == OpBranch ) & (inst_from_imem[14:12] == 3'b101);
  wire inst_bltu   = (inst_opcode == OpBranch ) & (inst_from_imem[14:12] == 3'b110);
  wire inst_bgeu   = (inst_opcode == OpBranch ) & (inst_from_imem[14:12] == 3'b111);

  wire inst_lb     = (inst_opcode == OpLoad   ) & (inst_from_imem[14:12] == 3'b000);
  wire inst_lh     = (inst_opcode == OpLoad   ) & (inst_from_imem[14:12] == 3'b001);
  wire inst_lw     = (inst_opcode == OpLoad   ) & (inst_from_imem[14:12] == 3'b010);
  wire inst_lbu    = (inst_opcode == OpLoad   ) & (inst_from_imem[14:12] == 3'b100);
  wire inst_lhu    = (inst_opcode == OpLoad   ) & (inst_from_imem[14:12] == 3'b101);

  wire inst_sb     = (inst_opcode == OpStore  ) & (inst_from_imem[14:12] == 3'b000);
  wire inst_sh     = (inst_opcode == OpStore  ) & (inst_from_imem[14:12] == 3'b001);
  wire inst_sw     = (inst_opcode == OpStore  ) & (inst_from_imem[14:12] == 3'b010);

  wire inst_addi   = (inst_opcode == OpRegImm ) & (inst_from_imem[14:12] == 3'b000);
  wire inst_slti   = (inst_opcode == OpRegImm ) & (inst_from_imem[14:12] == 3'b010);
  wire inst_sltiu  = (inst_opcode == OpRegImm ) & (inst_from_imem[14:12] == 3'b011);
  wire inst_xori   = (inst_opcode == OpRegImm ) & (inst_from_imem[14:12] == 3'b100);
  wire inst_ori    = (inst_opcode == OpRegImm ) & (inst_from_imem[14:12] == 3'b110);
  wire inst_andi   = (inst_opcode == OpRegImm ) & (inst_from_imem[14:12] == 3'b111);

  wire inst_slli   = (inst_opcode == OpRegImm ) & (inst_from_imem[14:12] == 3'b001) & (inst_from_imem[31:25] == 7'd0      );
  wire inst_srli   = (inst_opcode == OpRegImm ) & (inst_from_imem[14:12] == 3'b101) & (inst_from_imem[31:25] == 7'd0      );
  wire inst_srai   = (inst_opcode == OpRegImm ) & (inst_from_imem[14:12] == 3'b101) & (inst_from_imem[31:25] == 7'b0100000);

  wire inst_add    = (inst_opcode == OpRegReg ) & (inst_from_imem[14:12] == 3'b000) & (inst_from_imem[31:25] == 7'd0      );
  wire inst_sub    = (inst_opcode == OpRegReg ) & (inst_from_imem[14:12] == 3'b000) & (inst_from_imem[31:25] == 7'b0100000);
  wire inst_sll    = (inst_opcode == OpRegReg ) & (inst_from_imem[14:12] == 3'b001) & (inst_from_imem[31:25] == 7'd0      );
  wire inst_slt    = (inst_opcode == OpRegReg ) & (inst_from_imem[14:12] == 3'b010) & (inst_from_imem[31:25] == 7'd0      );
  wire inst_sltu   = (inst_opcode == OpRegReg ) & (inst_from_imem[14:12] == 3'b011) & (inst_from_imem[31:25] == 7'd0      );
  wire inst_xor    = (inst_opcode == OpRegReg ) & (inst_from_imem[14:12] == 3'b100) & (inst_from_imem[31:25] == 7'd0      );
  wire inst_srl    = (inst_opcode == OpRegReg ) & (inst_from_imem[14:12] == 3'b101) & (inst_from_imem[31:25] == 7'd0      );
  wire inst_sra    = (inst_opcode == OpRegReg ) & (inst_from_imem[14:12] == 3'b101) & (inst_from_imem[31:25] == 7'b0100000);
  wire inst_or     = (inst_opcode == OpRegReg ) & (inst_from_imem[14:12] == 3'b110) & (inst_from_imem[31:25] == 7'd0      );
  wire inst_and    = (inst_opcode == OpRegReg ) & (inst_from_imem[14:12] == 3'b111) & (inst_from_imem[31:25] == 7'd0      );

  wire inst_mul    = (inst_opcode == OpRegReg ) & (inst_from_imem[31:25] == 7'd1  ) & (inst_from_imem[14:12] == 3'b000    );
  wire inst_mulh   = (inst_opcode == OpRegReg ) & (inst_from_imem[31:25] == 7'd1  ) & (inst_from_imem[14:12] == 3'b001    );
  wire inst_mulhsu = (inst_opcode == OpRegReg ) & (inst_from_imem[31:25] == 7'd1  ) & (inst_from_imem[14:12] == 3'b010    );
  wire inst_mulhu  = (inst_opcode == OpRegReg ) & (inst_from_imem[31:25] == 7'd1  ) & (inst_from_imem[14:12] == 3'b011    );
  wire inst_div    = (inst_opcode == OpRegReg ) & (inst_from_imem[31:25] == 7'd1  ) & (inst_from_imem[14:12] == 3'b100    );
  wire inst_divu   = (inst_opcode == OpRegReg ) & (inst_from_imem[31:25] == 7'd1  ) & (inst_from_imem[14:12] == 3'b101    );
  wire inst_rem    = (inst_opcode == OpRegReg ) & (inst_from_imem[31:25] == 7'd1  ) & (inst_from_imem[14:12] == 3'b110    );
  wire inst_remu   = (inst_opcode == OpRegReg ) & (inst_from_imem[31:25] == 7'd1  ) & (inst_from_imem[14:12] == 3'b111    );

  wire inst_ecall  = (inst_opcode == OpEnviron) & (inst_from_imem[31:7] == 25'd0  );
  wire inst_fence  = (inst_opcode == OpMiscMem);

  // program counter
  reg [`REG_SIZE:0] pcNext, pcCurrent;
  always @(posedge clk) begin
    if (rst) begin
      pcCurrent <= 32'd0;
    end else begin
      pcCurrent <= pcNext;
    end
  end
  assign pc_to_imem = pcCurrent;


  // NOTE: don't rename your RegFile instance as the tests expect it to be `rf`
  // TODO: you will need to edit the port connections, however.
    // Control signals
  reg [1:0] pc_sel;
  reg [1:0] a_sel;
  reg [1:0] b_sel;
  reg [3:0] alu_sel;  // Extended to 4 bits to support division
  reg mem_we;
  reg reg_we;
  reg [1:0] wb_sel;

  // ALU signals
  reg [`REG_SIZE:0] alu_a;
  reg [`REG_SIZE:0] alu_b;
  reg [`REG_SIZE:0] alu_result;
  reg alu_zero;
  reg branch_taken;

  // Register file connections
  wire [`REG_SIZE:0] rs1_data;
  wire [`REG_SIZE:0] rs2_data;
  wire [`REG_SIZE:0] reg_wdata;


  // Register file - instance must be named 'rf' for tests
  RegFile rf (
    .clk(clk),
    .rst(rst),
    .we(reg_we),
    .rd(inst_rd),
    .rd_data(reg_wdata),
    .rs1(inst_rs1),
    .rs2(inst_rs2),
    .rs1_data(rs1_data),
    .rs2_data(rs2_data)
  );

  reg illegal_inst;

  always @(*) begin
    // Default values
    illegal_inst = 1'b0;
    pc_sel = 2'b00;
    a_sel = 2'b00;
    b_sel = 2'b00;
    alu_sel = 4'b0000;
    mem_we = 1'b0;
    reg_we = 1'b0;
    wb_sel = 2'b00;
    halt = 1'b0;
    branch_taken = 1'b0;

    case (inst_opcode)
      // LUI
      OpLui: begin
        reg_we = 1'b1;
        wb_sel = 2'b11; // Immediate value
      end

      // AUIPC
      OpAuipc: begin
        a_sel = 2'b01; // PC
        b_sel = 2'b01; // Immediate
        alu_sel = 4'b0000; // ADD (using CLA)
        reg_we = 1'b1;
        wb_sel = 2'b00; // ALU result
      end

      // JAL
      OpJal: begin
        pc_sel = 2'b11; // Jump
        reg_we = 1'b1;
        wb_sel = 2'b10; // PC + 4
      end

      // JALR
      OpJalr: begin
        pc_sel = 2'b01; // Jump register
        a_sel = 2'b00; // RS1
        b_sel = 2'b01; // Immediate
        alu_sel = 4'b0000; // ADD (using CLA)
        reg_we = 1'b1;
        wb_sel = 2'b10; // PC + 4
      end

      // Branch instructions
      OpBranch: begin
        a_sel = 2'b00; // RS1
        b_sel = 2'b00; // RS2
        alu_sel = 4'b0001; // SUB for comparison
        
        // Determine branch condition
        case (inst_funct3)
          3'b000: branch_taken = (rs1_data == rs2_data); // BEQ
          3'b001: branch_taken = (rs1_data != rs2_data); // BNE
          3'b100: branch_taken = ($signed(rs1_data) < $signed(rs2_data)); // BLT
          3'b101: branch_taken = ($signed(rs1_data) >= $signed(rs2_data)); // BGE
          3'b110: branch_taken = (rs1_data < rs2_data); // BLTU
          3'b111: branch_taken = (rs1_data >= rs2_data); // BGEU
          default: branch_taken = 1'b0;
        endcase
        
        pc_sel = branch_taken ? 2'b10 : 2'b00; // Branch if condition met
      end

      // Load instructions
      OpLoad: begin
        a_sel = 2'b00; // RS1
        b_sel = 2'b01; // Immediate
        alu_sel = 4'b0000; // ADD (using CLA)
        reg_we = 1'b1;
        wb_sel = 2'b01; // Memory data
      end

      // Store instructions
      OpStore: begin
        a_sel = 2'b00; // RS1
        b_sel = 2'b10; // Immediate (S-type)
        alu_sel = 4'b0000; // ADD (using CLA)
        mem_we = 1'b1;
      end

      // ALU immediate instructions
      OpRegImm: begin
        a_sel = 2'b00; // RS1
        b_sel = 2'b01; // Immediate
        reg_we = 1'b1;
        wb_sel = 2'b00; // ALU result
        
        case (inst_funct3)
          3'b000: alu_sel = 4'b0000; // ADDI (using CLA)
          3'b010: alu_sel = 4'b0010; // SLTI
          3'b011: alu_sel = 4'b0011; // SLTIU
          3'b100: alu_sel = 4'b0100; // XORI
          3'b110: alu_sel = 4'b0110; // ORI
          3'b111: alu_sel = 4'b0111; // ANDI
          3'b001: alu_sel = 4'b0101; // SLLI
          3'b101: alu_sel = (inst_funct7[5]) ? 4'b0111 : 4'b0110; // SRAI vs SRLI
        endcase
      end

      // ALU register instructions
      OpRegReg: begin
        a_sel = 2'b00; // RS1
        b_sel = 2'b00; // RS2
        reg_we = 1'b1;
        wb_sel = 2'b00; // ALU result
        
        case (inst_funct3)
          3'b000: alu_sel = (inst_funct7[5]) ? 4'b0001 : 4'b0000; // SUB vs ADD (CLA)
          3'b001: alu_sel = 4'b0101; // SLL
          3'b010: alu_sel = 4'b0010; // SLT
          3'b011: alu_sel = 4'b0011; // SLTU
          3'b100: alu_sel = 4'b0100; // XOR
          3'b101: alu_sel = (inst_funct7[5]) ? 4'b0111 : 4'b0110; // SRA vs SRL
          3'b110: alu_sel = 4'b0110; // OR
          3'b111: alu_sel = 4'b0111; // AND
        endcase

        // Multiplication and Division instructions
        if (inst_funct7 == 7'b0000001) begin
          case (inst_funct3)
            3'b000: alu_sel = 4'b1000; // MUL - use multiplication operator
            3'b100: alu_sel = 4'b1001; // DIV
            3'b101: alu_sel = 4'b1010; // DIVU
            3'b110: alu_sel = 4'b1011; // REM
            3'b111: alu_sel = 4'b1100; // REMU
            // Note: MULH, MULHSU, MULHU would need additional handling
            default: alu_sel = 4'b0000;
          endcase
        end
      end

      // ECALL
      OpEnviron: begin
        if (inst_ecall) begin
          halt = 1'b1;
        end
      end

      default: begin
        illegal_inst = 1'b1;
      end
    endcase
  end

  // ALU input multiplexers
  always @(*) begin
    case (a_sel)
      2'b00: alu_a = rs1_data;
      2'b01: alu_a = pcCurrent;
      2'b10: alu_a = 32'b0;
      default: alu_a = 32'b0;
    endcase

    case (b_sel)
      2'b00: alu_b = rs2_data;
      2'b01: alu_b = imm_i_sext;
      2'b10: alu_b = imm_s_sext;
      2'b11: alu_b = 32'h4;
      default: alu_b = 32'b0;
    endcase
  end

  // ALU logic with CLA and Divider integration
  always @(*) begin
    case (alu_sel)
      4'b0000: alu_result = cla_sum;        // ADD (using CLA)
      4'b0001: alu_result = alu_a - alu_b;  // SUB
      4'b0010: alu_result = ($signed(alu_a) < $signed(alu_b)) ? 32'b1 : 32'b0; // SLT
      4'b0011: alu_result = (alu_a < alu_b) ? 32'b1 : 32'b0; // SLTU
      4'b0100: alu_result = alu_a ^ alu_b;        // XOR
      4'b0101: alu_result = alu_a << alu_b[4:0];  // SLL
      4'b0110: alu_result = alu_a >> alu_b[4:0];  // SRL
      4'b0111: alu_result = $signed(alu_a) >>> alu_b[4:0]; // SRA
      4'b1000: alu_result = alu_a * alu_b;        // MUL (using operator)
      4'b1001: alu_result = div_quotient;         // DIV
      4'b1010: alu_result = div_quotient;         // DIVU
      4'b1011: alu_result = div_remainder;        // REM
      4'b1100: alu_result = div_remainder;        // REMU
      default: alu_result = 32'b0;
    endcase
    
    alu_zero = (alu_result == 32'b0);
  end

  // Writeback multiplexer
  assign reg_wdata = (wb_sel == 2'b00) ? alu_result :
                     (wb_sel == 2'b01) ? load_data_from_dmem :
                     (wb_sel == 2'b10) ? pcCurrent + 4 :
                     (wb_sel == 2'b11) ? {imm_i_sext[31:12], 12'b0} : 32'b0;

  // Next PC calculation
  always @(*) begin
    case (pc_sel)
      2'b00: pcNext = pcCurrent + 4;  // Normal increment
      2'b01: pcNext = {alu_result[31:1], 1'b0};     // JALR (clear LSB)
      2'b10: pcNext = pcCurrent + imm_b_sext; // Branch
      2'b11: pcNext = pcCurrent + imm_j_sext; // JAL
      default: pcNext = pcCurrent + 4;
    endcase
  end

  // Memory access
  always @(*) begin
    addr_to_dmem = alu_result;
    store_data_to_dmem = rs2_data;
    
    // Handle byte/halfword stores
    case (inst_funct3)
      3'b000: store_we_to_dmem = (mem_we) ? 4'b0001 : 4'b0000; // SB
      3'b001: store_we_to_dmem = (mem_we) ? 4'b0011 : 4'b0000; // SH
      3'b010: store_we_to_dmem = (mem_we) ? 4'b1111 : 4'b0000; // SW
      default: store_we_to_dmem = 4'b0000;
    endcase
  end

  // Cycle/instruction counters
  reg [`REG_SIZE:0] cycles_current, num_inst_current;
  always @(posedge clk) begin
    if (rst) begin
      cycles_current <= 0;
      num_inst_current <= 0;
    end else begin
      cycles_current <= cycles_current + 1;
      if (!halt) begin
        num_inst_current <= num_inst_current + 1;
      end
    end
  end

endmodule

/* A memory module that supports 1-cycle reads and writes, with one read-only port
 * and one read+write port.
 */
module MemorySingleCycle #(
    parameter NUM_WORDS = 512
) (
  input                    rst,                 // rst for both imem and dmem
  input                    clock_mem,           // clock for both imem and dmem
  input      [`REG_SIZE:0] pc_to_imem,          // must always be aligned to a 4B boundary
  output reg [`REG_SIZE:0] inst_from_imem,      // the value at memory location pc_to_imem
  input      [`REG_SIZE:0] addr_to_dmem,        // must always be aligned to a 4B boundary
  output reg [`REG_SIZE:0] load_data_from_dmem, // the value at memory location addr_to_dmem
  input      [`REG_SIZE:0] store_data_to_dmem,  // the value to be written to addr_to_dmem, controlled by store_we_to_dmem
  // Each bit determines whether to write the corresponding byte of store_data_to_dmem to memory location addr_to_dmem.
  // E.g., 4'b1111 will write 4 bytes. 4'b0001 will write only the least-significant byte.
  input      [        3:0] store_we_to_dmem
);

  // memory is arranged as an array of 4B words
  reg [`REG_SIZE:0] mem_array[0:NUM_WORDS-1];

  // preload instructions to mem_array
  initial begin
    $readmemh("mem_initial_contents.hex", mem_array);
  end

  localparam AddrMsb = $clog2(NUM_WORDS) + 1;
  localparam AddrLsb = 2;

  always @(posedge clock_mem) begin
    inst_from_imem <= mem_array[pc_to_imem[AddrMsb:AddrLsb]];
  end

  always @(negedge clock_mem) begin
   if (store_we_to_dmem[0]) begin
     mem_array[addr_to_dmem[AddrMsb:AddrLsb]][7:0] <= store_data_to_dmem[7:0];
   end
   if (store_we_to_dmem[1]) begin
     mem_array[addr_to_dmem[AddrMsb:AddrLsb]][15:8] <= store_data_to_dmem[15:8];
   end
   if (store_we_to_dmem[2]) begin
     mem_array[addr_to_dmem[AddrMsb:AddrLsb]][23:16] <= store_data_to_dmem[23:16];
   end
   if (store_we_to_dmem[3]) begin
     mem_array[addr_to_dmem[AddrMsb:AddrLsb]][31:24] <= store_data_to_dmem[31:24];
   end
   // dmem is "read-first": read returns value before the write
    load_data_from_dmem <= mem_array[addr_to_dmem[AddrMsb:AddrLsb]];
  end
endmodule

/*
This shows the relationship between clock_proc and clock_mem. The clock_mem is
phase-shifted 90° from clock_proc. You could think of one proc cycle being
broken down into 3 parts. During part 1 (which starts @posedge clock_proc)
the current PC is sent to the imem. In part 2 (starting @posedge clock_mem) we
read from imem. In part 3 (starting @negedge clock_mem) we read/write memory and
prepare register/PC updates, which occur at @posedge clock_proc.

        ____
 proc: |    |______
           ____
 mem:  ___|    |___
*/
module Processor (
    input  clock_proc,
    input  clock_mem,
    input  rst,
    output halt
);

  wire [`REG_SIZE:0] pc_to_imem, inst_from_imem, mem_data_addr, mem_data_loaded_value, mem_data_to_write;
  wire [        3:0] mem_data_we;

  // This wire is set by cocotb to the name of the currently-running test, to make it easier
  // to see what is going on in the waveforms.
  wire [(8*32)-1:0] test_case;

  MemorySingleCycle #(
      .NUM_WORDS(8192)
  ) memory (
    .rst                 (rst),
    .clock_mem           (clock_mem),
    // imem is read-only
    .pc_to_imem          (pc_to_imem),
    .inst_from_imem      (inst_from_imem),
    // dmem is read-write
    .addr_to_dmem        (mem_data_addr),
    .load_data_from_dmem (mem_data_loaded_value),
    .store_data_to_dmem  (mem_data_to_write),
    .store_we_to_dmem    (mem_data_we)
  );

  DatapathSingleCycle datapath (
    .clk                 (clock_proc),
    .rst                 (rst),
    .pc_to_imem          (pc_to_imem),
    .inst_from_imem      (inst_from_imem),
    .addr_to_dmem        (mem_data_addr),
    .store_data_to_dmem  (mem_data_to_write),
    .store_we_to_dmem    (mem_data_we),
    .load_data_from_dmem (mem_data_loaded_value),
    .halt                (halt)
  );

endmodule