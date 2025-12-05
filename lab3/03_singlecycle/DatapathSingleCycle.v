`timescale 1ns / 1ns

// registers are 32 bits in RV32
`define REG_SIZE   31

// RV opcodes are 7 bits
`define OPCODE_SIZE 6



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
  reg [`REG_SIZE:0] regs[0:NumRegs-1];

  integer i;
  always @(posedge clk) begin
    if (rst) begin
      for (i = 0; i < NumRegs; i = i + 1) begin
        regs[i] <= 32'd0;
      end
    end else begin
      if (we && rd != 5'd0) begin
        regs[rd] <= rd_data;
      end
    end
  end

  // combinational read
  always @(*) begin
    rs1_data = (rs1 == 5'd0) ? 32'd0 : regs[rs1];
    rs2_data = (rs2 == 5'd0) ? 32'd0 : regs[rs2];
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

  // components of the instruction
  wire [           6:0] inst_funct7;
  wire [           4:0] inst_rs2;
  wire [           4:0] inst_rs1;
  wire [           2:0] inst_funct3;
  wire [           4:0] inst_rd;
  wire [`OPCODE_SIZE:0] inst_opcode;

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

  // sign extend
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

  // decoded inst
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

  wire is_valid_opcode =
    (inst_opcode == OpLoad   ) ||
    (inst_opcode == OpStore  ) ||
    (inst_opcode == OpBranch ) ||
    (inst_opcode == OpJalr   ) ||
    (inst_opcode == OpMiscMem) ||
    (inst_opcode == OpJal    ) ||
    (inst_opcode == OpRegImm ) ||
    (inst_opcode == OpRegReg ) ||
    (inst_opcode == OpEnviron) ||
    (inst_opcode == OpAuipc  ) ||
    (inst_opcode == OpLui    );
  wire [`REG_SIZE:0] imm_u;
  assign imm_u = {inst_from_imem[31:12], 12'd0};
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

  // cycle/inst counters
  reg [`REG_SIZE:0] cycles_current, num_inst_current;
  always @(posedge clk) begin
    if (rst) begin
      cycles_current   <= 0;
      num_inst_current <= 0;
    end else begin
      cycles_current   <= cycles_current + 1;
      num_inst_current <= num_inst_current + 1;
    end
  end

  wire [`REG_SIZE:0] rs1_data;
  wire [`REG_SIZE:0] rs2_data;
  reg                reg_we;
  reg [4:0]          reg_rd_addr;
  reg [`REG_SIZE:0]  reg_rd_data;

  RegFile rf (
    .clk      (clk),
    .rst      (rst),
    .we       (reg_we),
    .rd       (reg_rd_addr),
    .rd_data  (reg_rd_data),
    .rs1      (inst_rs1),
    .rs2      (inst_rs2),
    .rs1_data (rs1_data),
    .rs2_data (rs2_data)
  );

  reg illegal_inst;

  reg [31:0] alu_op2_in;     
  reg        alu_op2_invert; 
  reg        cin_for_cla;    

  wire [31:0] cla_b_input = alu_op2_invert ? ~alu_op2_in : alu_op2_in;
  wire [31:0] cla_sum;
  wire        cla_cout;
  
  cla cla_unit (
    .a   (rs1_data),
    .b   (cla_b_input),
    .c0  (cin_for_cla),
    .sum (cla_sum),
    .cout(cla_cout)
  );
  wire [31:0] alu_add_result;
  assign alu_add_result = rs1_data + cla_b_input + cin_for_cla;
  wire [`REG_SIZE:0] div_quotient, div_remainder;
  divider_unsigned unit (
    .dividend (rs1_data),
    .divisor  (rs2_data),
    .quotient (div_quotient),
    .remainder(div_remainder)
  );



  reg take;


  always @(*) begin
    halt         = 1'b0;
    illegal_inst = 1'b0;
    pcNext       = pcCurrent + 32'd4;

    reg_we        = 1'b0;
    reg_rd_addr   = inst_rd;
    reg_rd_data   = 32'd0;

    store_we_to_dmem   = 4'b0000;
    store_data_to_dmem = 32'd0;
    addr_to_dmem       = 32'd0;

    alu_op2_in     = rs2_data;
    alu_op2_invert = 1'b0;
    cin_for_cla    = 1'b0;
    take           = 1'b0;

    case (inst_opcode)
      OpLui: begin
        reg_we      = 1'b1;
        reg_rd_data = imm_u;              
        reg_rd_addr = inst_rd;
      end

      OpRegImm: begin
        reg_we      = 1'b1;
        reg_rd_addr = inst_rd;
        alu_op2_in  = imm_i_sext;

        case (inst_funct3)
          3'b000: begin 
            alu_op2_in     = imm_i_sext;
            alu_op2_invert = 1'b0;
            cin_for_cla    = 1'b0;
            reg_rd_data    = alu_add_result;
          end
          3'b010: reg_rd_data = ($signed(rs1_data) < $signed(imm_i_sext)) ? 32'd1 : 32'd0; 
          3'b011: reg_rd_data = (rs1_data < imm_i_sext) ? 32'd1 : 32'd0;                    
          3'b100: reg_rd_data = rs1_data ^ imm_i_sext;                                     
          3'b110: reg_rd_data = rs1_data | imm_i_sext;                                      
          3'b111: reg_rd_data = rs1_data & imm_i_sext;                                      
          3'b001: reg_rd_data = rs1_data << imm_shamt;                                      
          3'b101: begin
            if (inst_srai)
              reg_rd_data = $signed(rs1_data) >>> imm_shamt;                               
            else
              reg_rd_data = rs1_data >> imm_shamt;                                          
          end
          default: begin
            reg_we      = 1'b0;
            illegal_inst = 1'b1;
          end
        endcase
      end

      OpRegReg: begin
        reg_we      = 1'b1;
        reg_rd_addr = inst_rd;
        alu_op2_in  = rs2_data;

        case ({inst_funct7, inst_funct3})
          {7'd0,       3'b000}: begin 
            alu_op2_in     = rs2_data;
            alu_op2_invert = 1'b0;
            cin_for_cla    = 1'b0;
            reg_rd_data    = alu_add_result;
          end
          {7'b0100000, 3'b000}: begin 
            alu_op2_in     = rs2_data;
            alu_op2_invert = 1'b1;
            cin_for_cla    = 1'b1;
            reg_rd_data    = alu_add_result;
          end

          {7'd1, 3'b000}: reg_rd_data = rs1_data * rs2_data;    
          {7'd1, 3'b100}: reg_rd_data = div_quotient;           
          {7'd1, 3'b110}: reg_rd_data = div_remainder;          

          default: begin
            reg_we      = 1'b0;
            illegal_inst = 1'b1;
          end
        endcase
      end

      OpEnviron: begin
        if (inst_ecall) begin
          halt = 1'b1;
        end else begin
          illegal_inst = 1'b1;
        end
      end

      OpAuipc: begin
        reg_we      = 1'b1;
        reg_rd_addr = inst_rd;
        reg_rd_data = pcCurrent + {inst_from_imem[31:12], 12'd0};
      end

      OpJal: begin
        reg_we      = 1'b1;
        reg_rd_addr = inst_rd;
        reg_rd_data = pcCurrent + 32'd4;
        pcNext      = pcCurrent + imm_j_sext;
      end

      OpJalr: begin
        reg_we      = 1'b1;
        reg_rd_addr = inst_rd;
        reg_rd_data = pcCurrent + 32'd4;
        pcNext      = alu_add_result & ~32'h1;
        // $display("[JALR] pc=%0d inst=%08h opcode=%b rs1=x%0d=%08h imm_i=%0d target=%0d",
        //          pcCurrent, inst_from_imem, inst_opcode,
        //          inst_rs1, rs1_data,
        //          $signed(imm_i_sext),
        //          (rs1_data + imm_i_sext) & 32'hFFFF_FFFE);
      end

      OpBranch: begin
        reg_we = 1'b0;
        case (inst_funct3)
          3'b000: take = (rs1_data == rs2_data);                         
          3'b001: take = (rs1_data != rs2_data);                         
          3'b100: take = ($signed(rs1_data) <  $signed(rs2_data));       
          3'b101: take = ($signed(rs1_data) >= $signed(rs2_data));       
          3'b110: take = (rs1_data <  rs2_data);                        
          3'b111: take = (rs1_data >= rs2_data);                         
        endcase
        if (take)
          pcNext = pcCurrent + imm_b_sext;
      end

      OpLoad: begin
        addr_to_dmem = rs1_data + imm_i_sext;

        reg_we      = 1'b1;
        reg_rd_addr = inst_rd;
        reg_rd_data = 32'd0;

        if (inst_lw) begin
          reg_rd_data = load_data_from_dmem;
        end
        else if (inst_lb) begin
          case (addr_to_dmem[1:0])
            2'b00: reg_rd_data = {{24{load_data_from_dmem[7]}},  load_data_from_dmem[7:0]};
            2'b01: reg_rd_data = {{24{load_data_from_dmem[15]}}, load_data_from_dmem[15:8]};
            2'b10: reg_rd_data = {{24{load_data_from_dmem[23]}}, load_data_from_dmem[23:16]};
            2'b11: reg_rd_data = {{24{load_data_from_dmem[31]}}, load_data_from_dmem[31:24]};
          endcase
        end
        else if (inst_lbu) begin
          case (addr_to_dmem[1:0])
            2'b00: reg_rd_data = {24'b0, load_data_from_dmem[7:0]};
            2'b01: reg_rd_data = {24'b0, load_data_from_dmem[15:8]};
            2'b10: reg_rd_data = {24'b0, load_data_from_dmem[23:16]};
            2'b11: reg_rd_data = {24'b0, load_data_from_dmem[31:24]};
          endcase
        end
        else if (inst_lh) begin
          if (addr_to_dmem[1] == 1'b0)
            reg_rd_data = {{16{load_data_from_dmem[15]}}, load_data_from_dmem[15:0]};
          else
            reg_rd_data = {{16{load_data_from_dmem[31]}}, load_data_from_dmem[31:16]};
        end
        else if (inst_lhu) begin
          if (addr_to_dmem[1] == 1'b0)
            reg_rd_data = {16'b0, load_data_from_dmem[15:0]};
          else
            reg_rd_data = {16'b0, load_data_from_dmem[31:16]};
        end
        else begin
          reg_we      = 1'b0;
          reg_rd_data = 32'd0;
          illegal_inst = 1'b1;
        end

        // DEBUG LOAD
        // if (!rst && reg_we) begin
        //   $display("[LOAD ] pc=%0d opcode=%b funct3=%b rs1=x%0d=%08h rd=x%0d addr=%0d mem=%08h rd_data=%08h",
        //            pcCurrent, inst_opcode, inst_funct3,
        //            inst_rs1, rs1_data,
        //            inst_rd,
        //            addr_to_dmem,
        //            load_data_from_dmem,
        //            reg_rd_data);
        // end
      end


      OpStore: begin
        reg_we      = 1'b0;
        reg_rd_addr = 5'd0;
        reg_rd_data = 32'd0;
        addr_to_dmem       = rs1_data + imm_s_sext;
        store_we_to_dmem   = 4'b0000;
        store_data_to_dmem = 32'd0;

        if (inst_sw) begin
          store_we_to_dmem   = 4'b1111;
          store_data_to_dmem = rs2_data;
        end
        else if (inst_sh) begin
          if (addr_to_dmem[1] == 1'b0) begin
            store_we_to_dmem = 4'b0011;
          end else begin
            store_we_to_dmem = 4'b1100;
          end
          store_data_to_dmem = {2{rs2_data[15:0]}};
        end
        else if (inst_sb) begin
          case (addr_to_dmem[1:0])
            2'b00: store_we_to_dmem = 4'b0001;
            2'b01: store_we_to_dmem = 4'b0010;
            2'b10: store_we_to_dmem = 4'b0100;
            2'b11: store_we_to_dmem = 4'b1000;
          endcase
          store_data_to_dmem = {4{rs2_data[7:0]}};
        end
        else begin
          store_we_to_dmem   = 4'b0000;
          store_data_to_dmem = 32'd0;
          illegal_inst       = 1'b1;
        end

        // DEBUG STORE
        // if (!rst && store_we_to_dmem != 4'b0000) begin
        //   $display("[STORE] pc=%0d opcode=%b funct3=%b rs1=x%0d=%08h rs2=x%0d=%08h imm_s=%0d addr=%0d data=%08h mask=%b",
        //            pcCurrent, inst_opcode, inst_funct3,
        //            inst_rs1, rs1_data,
        //            inst_rs2, rs2_data,
        //            $signed(imm_s_sext),
        //            addr_to_dmem,
        //            store_data_to_dmem,
        //            store_we_to_dmem);
        // end
      end


      OpMiscMem: begin
      end

      default: begin
        illegal_inst = 1'b1;
      end
    endcase

    if (!is_valid_opcode) begin
      reg_we          = 1'b0;
      store_we_to_dmem = 4'b0000;
    end
  end


endmodule




module MemorySingleCycle #(
    parameter NUM_WORDS = 512
) (
  input                    rst,
  input      clock_mem,
  input      [`REG_SIZE:0] pc_to_imem,
  output reg [`REG_SIZE:0] inst_from_imem,
  input      [`REG_SIZE:0] addr_to_dmem,
  output reg [`REG_SIZE:0] load_data_from_dmem,
  input      [`REG_SIZE:0] store_data_to_dmem,
  input      [        3:0] store_we_to_dmem
);

  reg [`REG_SIZE:0] mem_array[0:NUM_WORDS-1];

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
  end

  always @(*) begin
    load_data_from_dmem = mem_array[addr_to_dmem[AddrMsb:AddrLsb]];
  end

endmodule


//======================================================================
// Processor Top
//======================================================================

module Processor (
    input  clock_proc,
    input  clock_mem,
    input  rst,
    output halt
);

  wire [`REG_SIZE:0] pc_to_imem;
  wire [`REG_SIZE:0] inst_from_imem;
  wire [`REG_SIZE:0] mem_data_addr;
  wire [`REG_SIZE:0] mem_data_loaded_value;
  wire [`REG_SIZE:0] mem_data_to_write;
  wire [        3:0] mem_data_we;

  // just for testbench naming
  wire [(8*32)-1:0] test_case;

  MemorySingleCycle #(
      .NUM_WORDS(8192)
  ) memory (
    .rst                 (rst),
    .clock_mem           (clock_mem),
    .pc_to_imem          (pc_to_imem),
    .inst_from_imem      (inst_from_imem),
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
