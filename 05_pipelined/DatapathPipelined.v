`timescale 1ns / 1ns

// registers are 32 bits in RV32
`define REG_SIZE 31

// inst. are 32 bits in RV32IM
`define INST_SIZE 31

// RV opcodes are 7 bits
`define OPCODE_SIZE 6

`define DIVIDER_STAGES 8

// Don't forget your old codes
`include "cla.v"
`include "DividerUnsignedPipelined.v"

// ====================================================
// Register File
// ====================================================
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

  always @(*) begin
    rs1_data = (rs1 == 5'd0) ? 32'd0 : regs[rs1];
    rs2_data = (rs2 == 5'd0) ? 32'd0 : regs[rs2];

    if (we && rd != 5'd0 && rd == rs1) begin
      rs1_data = rd_data;
    end
    if (we && rd != 5'd0 && rd == rs2) begin
      rs2_data = rd_data;
    end
  end
endmodule

// ====================================================
// DatapathPipelined
// ====================================================
module DatapathPipelined (
  input                     clk,
  input                     rst,
  output     [ `REG_SIZE:0] pc_to_imem,
  input      [`INST_SIZE:0] inst_from_imem,
  // dmem is read/write
  output reg [ `REG_SIZE:0] addr_to_dmem,
  input      [ `REG_SIZE:0] load_data_from_dmem,
  output reg [ `REG_SIZE:0] store_data_to_dmem,
  output reg [         3:0] store_we_to_dmem,
  output reg                halt,
  // The PC of the inst currently in Writeback. 0 if not a valid inst.
  output reg [ `REG_SIZE:0] trace_writeback_pc,
  // The bits of the inst currently in Writeback. 0 if not a valid inst.
  output reg [`INST_SIZE:0] trace_writeback_inst
);

  // ------------------------------------------------
  // 0. Common constants / opcodes
  // ------------------------------------------------
  // opcodes - see section 19 of RiscV spec
  localparam [`OPCODE_SIZE:0] OpcodeLoad    = 7'b00_000_11;
  localparam [`OPCODE_SIZE:0] OpcodeStore   = 7'b01_000_11;
  localparam [`OPCODE_SIZE:0] OpcodeBranch  = 7'b11_000_11;
  localparam [`OPCODE_SIZE:0] OpcodeJalr    = 7'b11_001_11;
  localparam [`OPCODE_SIZE:0] OpcodeMiscMem = 7'b00_011_11;
  localparam [`OPCODE_SIZE:0] OpcodeJal     = 7'b11_011_11;

  localparam [`OPCODE_SIZE:0] OpcodeRegImm  = 7'b00_100_11;
  localparam [`OPCODE_SIZE:0] OpcodeRegReg  = 7'b01_100_11;
  localparam [`OPCODE_SIZE:0] OpcodeEnviron = 7'b11_100_11;

  localparam [`OPCODE_SIZE:0] OpcodeAuipc   = 7'b00_101_11;
  localparam [`OPCODE_SIZE:0] OpcodeLui     = 7'b01_101_11;

  // ------------------------------------------------
  // 0'. Cycle counter (debug)
  // ------------------------------------------------
  reg [`REG_SIZE:0] cycles_current;
  always @(posedge clk) begin
    if (rst) begin
      cycles_current <= 0;
    end else begin
      cycles_current <= cycles_current + 1;
    end
  end

    // =========================
  // 1. Hazard / Stall logic
  // =========================

  // 1) Load-use hazard: D dùng ngay kết quả từ load ở X
  wire load_use_hazard =
      x_is_load &&
      x_reg_write_en &&
      x_valid &&
      d_valid &&
      (x_rd != 5'd0) &&
      ((d_rs1 == x_rd) || (d_rs2 == x_rd));

  // 2) Divider: start / busy / done
  wire x_divisor_zero = (x_rs2_fwd == 32'd0);

  // Bắt đầu phép chia khi X có DIV/REM, rs2 != 0, divider đang IDLE
  wire div_start =
      x_valid &&
      x_inst_any_div &&
      !x_divisor_zero &&
      (div_state == DIV_IDLE) &&
      !x_div_started;    // chỉ cho start đúng 1 lần / instruction ở X

    always @(posedge clk) begin
      if (rst) begin
        x_div_started <= 1'b0;

      end else if (flush_x) begin
        // X bị flush → instruction cũ bị loại, reset flag
        x_div_started <= 1'b0;

      end else if (!x_valid) begin
        // X không chứa instruction hợp lệ → không thể là DIV → reset
        x_div_started <= 1'b0;
      end else if (dx_en) begin       // <--- THÊM DÒNG NÀY
        // Có lệnh mới đi vào Stage X, reset cờ để chuẩn bị cho lệnh mới
        x_div_started <= 1'b0;
      end else if (div_start) begin
        // Bắt đầu thực sự phép chia → đánh dấu đã start
        x_div_started <= 1'b1;
      end
    end


  wire div_busy     = (div_state == DIV_BUSY);
  // DONE đúng 1 cycle khi đang BUSY và đếm đủ số stage
  wire div_done_now = (div_state == DIV_BUSY) && (div_cnt == `DIVIDER_STAGES);

  // Stall trong suốt thời gian BUSY (đang chia)
  wire stall_div = (div_busy && !div_done_now) || div_start;
  // Stall load-use: dừng F,D và bơm bubble vào X
  wire stall_load = load_use_hazard;

  // F và D dừng khi: load-use hoặc divider đang bận
  wire global_stall = stall_load || stall_div;

  // Enable cho các pipeline register
  wire pc_en = ~global_stall;   // F-stage PC
  wire fd_en = ~global_stall;   // F -> D

  // X,M,W chỉ cần đứng khi divider bận; load-use vẫn cho phép X,M,W chạy
  // (bubble được bơm vào X từ D thông qua flush_x)
  wire dx_en = ~stall_div;      // D -> X
  wire xm_en = ~stall_div;      // X -> M
  wire mw_en = 1'b1;      // M -> W

  // Flush: chỉ dùng cho load-use, xoá instruction tại X (bubble)
  wire flush_f = 1'b0;
  wire flush_d = 1'b0;
  wire flush_x = stall_load;






  // ------------------------------------------------
  // 2. FETCH STAGE (F)
  // ------------------------------------------------
  reg  [`REG_SIZE:0] f_pc_current;
  reg                f_valid;
  wire [`REG_SIZE:0] f_inst = inst_from_imem;

  wire [`REG_SIZE:0] f_pc_next = f_pc_current + 4;

  always @(posedge clk) begin
    if (rst) begin
      f_pc_current <= 32'd0;
      f_valid      <= 1'b0;
    end else if (pc_en) begin
      if (flush_f) begin
        f_pc_current <= 32'd0;
        f_valid      <= 1'b0;
      end else begin
        f_pc_current <= f_pc_next;
        f_valid      <= 1'b1;
      end
    end
  end

  assign pc_to_imem = f_pc_current;

  // ------------------------------------------------
  // 3. DECODE STAGE (D)
  //    - pipeline F -> D
  //    - decode d_inst
  //    - read RegFile
  //    - sinh control signal d_*
  // ------------------------------------------------

  // ---------- 3.1. Pipeline F -> D ----------
  reg [`REG_SIZE:0] d_pc;
  reg [`INST_SIZE:0] d_inst;
  reg                d_valid;

  always @(posedge clk) begin
    if (rst) begin
      d_pc    <= 32'd0;
      d_inst  <= 32'd0;
      d_valid <= 1'b0;
    end else if (fd_en) begin
      if (flush_d) begin
        d_pc    <= 32'd0;
        d_inst  <= 32'd0;
        d_valid <= 1'b0;
      end else begin
        d_pc    <= f_pc_current;
        d_inst  <= f_inst;
        d_valid <= f_valid;
      end
    end
  end

  // ---------- 3.2. Field decode from d_inst ----------
  wire [6:0]  d_opcode = d_inst[6:0];
  wire [4:0]  d_rd     = d_inst[11:7];
  wire [2:0]  d_funct3 = d_inst[14:12];
  wire [4:0]  d_rs1    = d_inst[19:15];
  wire [4:0]  d_rs2    = d_inst[24:20];
  wire [6:0]  d_funct7 = d_inst[31:25];

  // Immediates
  wire [11:0] d_imm_i_raw = d_inst[31:20];
  wire [4:0]  d_imm_shamt = d_inst[24:20];
  wire [11:0] d_imm_s_raw = {d_funct7, d_rd};

  wire [12:0] d_imm_b_raw;
  assign {d_imm_b_raw[12], d_imm_b_raw[10:1], d_imm_b_raw[11], d_imm_b_raw[0]}
       = {d_funct7, d_rd, 1'b0};

  wire [20:0] d_imm_j_raw;
  assign {d_imm_j_raw[20], d_imm_j_raw[10:1], d_imm_j_raw[11], d_imm_j_raw[19:12], d_imm_j_raw[0]}
       = {d_inst[31:12], 1'b0};

  // sign-extend to 32-bit
  wire [`REG_SIZE:0] d_imm_i_sext = {{20{d_imm_i_raw[11]}}, d_imm_i_raw[11:0]};
  wire [`REG_SIZE:0] d_imm_s_sext = {{20{d_imm_s_raw[11]}}, d_imm_s_raw[11:0]};
  wire [`REG_SIZE:0] d_imm_b_sext = {{19{d_imm_b_raw[12]}}, d_imm_b_raw[12:0]};
  wire [`REG_SIZE:0] d_imm_j_sext = {{11{d_imm_j_raw[20]}}, d_imm_j_raw[20:0]};
  wire [`REG_SIZE:0] d_imm_u_sext = {d_inst[31:12], 12'b0};

  // Để tương thích với skeleton X-stage (x_imm <= d_imm_i)
  wire [`REG_SIZE:0] d_imm_i = d_imm_i_sext;

  // ---------- 3.3. RegFile + operand values ----------
  // W-stage writeback wires (định nghĩa ở đây để dùng cho RegFile)
  wire [`REG_SIZE:0] w_wdata;
  wire [4:0]         w_rd;
  wire               w_reg_write;

  wire [`REG_SIZE:0] rf_rs1_data;
  wire [`REG_SIZE:0] rf_rs2_data;

  RegFile rf (
    .clk      (clk),
    .rst      (rst),
    .we       (w_reg_write),
    .rd       (w_rd),
    .rd_data  (w_wdata),
    .rs1      (d_rs1),
    .rs2      (d_rs2),
    .rs1_data (rf_rs1_data),
    .rs2_data (rf_rs2_data)
  );

  // Giá trị operand tại D stage (chưa forwarding phức tạp)
  wire [`REG_SIZE:0] d_rs1_val = rf_rs1_data;
  wire [`REG_SIZE:0] d_rs2_val = rf_rs2_data;

  // ---------- 3.4. Instruction type & control signals ----------
  // Instruction class flags (chỉ dùng opcode + funct3/funct7)
  wire d_is_lui    = (d_opcode == OpcodeLui);
  wire d_is_auipc  = (d_opcode == OpcodeAuipc);
  wire d_is_jal    = (d_opcode == OpcodeJal);
  wire d_is_jalr   = (d_opcode == OpcodeJalr);
  wire d_is_branch = (d_opcode == OpcodeBranch);
  wire d_is_load   = (d_opcode == OpcodeLoad);
  wire d_is_store  = (d_opcode == OpcodeStore);
  wire d_is_regimm = (d_opcode == OpcodeRegImm);
  wire d_is_regreg = (d_opcode == OpcodeRegReg);
  wire d_is_env    = (d_opcode == OpcodeEnviron);

  // RegWrite: load, ALU-immediate, ALU-register, JAL, JALR, LUI, AUIPC
  wire d_reg_write_en =
    d_is_load   |
    d_is_regimm |
    d_is_regreg |
    d_is_jal    |
    d_is_jalr   |
    d_is_lui    |
    d_is_auipc;

  // MemToReg: chỉ load mới lấy từ memory
  wire d_mem_to_reg = d_is_load;

  // ALU srcB = immediate? (skeleton)
  wire d_alu_src_imm =
    d_is_regimm | d_is_load | d_is_store | d_is_jalr | d_is_auipc | d_is_lui;

  // Các control flags sẽ được pipeline sang X
  // (d_is_* giữ nguyên, chỉ rename cho rõ)
  wire d_is_load_c   = d_is_load;
  wire d_is_store_c  = d_is_store;
  wire d_is_branch_c = d_is_branch;
  wire d_is_jal_c    = d_is_jal;
  wire d_is_jalr_c   = d_is_jalr;
  wire d_is_lui_c    = d_is_lui;
  wire d_is_auipc_c  = d_is_auipc;

  // ------------------------------------------------
  // 4. EXECUTE STAGE (X)
  // ------------------------------------------------
  reg [`REG_SIZE:0]  x_pc;
  reg [`INST_SIZE:0] x_inst;
  reg                x_valid;

  reg [`REG_SIZE:0]  x_rs1_val;
  reg [`REG_SIZE:0]  x_rs2_val;
  reg [`REG_SIZE:0]  x_imm;
  reg [4:0]          x_rd;

  reg [4:0]          x_rs1_idx;
  reg [4:0]          x_rs2_idx;
  // Control signal latch
  reg x_is_load;
  reg x_is_store;
  reg x_is_branch;
  reg x_is_jal;
  reg x_is_jalr;
  reg x_is_lui;
  reg x_is_auipc;
  reg x_reg_write_en;
  reg x_mem_to_reg;
  reg x_alu_src_imm;


  //MUX for mux in D -> X

  wire [`REG_SIZE:0] d_imm_sel;

  assign d_imm_sel =
  d_is_load ? d_imm_i_sext :
  d_is_regimm ? d_imm_i_sext :
  d_is_store  ? d_imm_s_sext :
  d_is_branch ? d_imm_b_sext :
  d_is_jal ? d_imm_j_sext :
  d_is_jalr ? d_imm_i_sext :
  d_is_lui ? d_imm_u_sext :
  d_is_auipc ? d_imm_u_sext :
  32'd0;

  // Pipeline D -> X
  always @(posedge clk) begin
    if (rst) begin
      x_pc           <= 32'd0;
      x_inst         <= 32'd0;
      x_valid        <= 1'b0;
      x_rs1_val      <= 32'd0;
      x_rs2_val      <= 32'd0;
      x_imm          <= 32'd0;
      x_rd           <= 5'd0;
      x_is_load      <= 1'b0;
      x_is_store     <= 1'b0;
      x_is_branch    <= 1'b0;
      x_is_jal       <= 1'b0;
      x_is_jalr      <= 1'b0;
      x_is_lui       <= 1'b0;
      x_is_auipc     <= 1'b0;
      x_reg_write_en <= 1'b0;
      x_mem_to_reg   <= 1'b0;
      x_alu_src_imm  <= 1'b0;
      x_rs1_idx      <= 5'd0;
      x_rs2_idx      <= 5'd0;
    end else if (dx_en) begin
      if (flush_x) begin
        x_pc           <= 32'd0;
        x_inst         <= 32'd0;
        x_valid        <= 1'b0;
        x_rs1_val      <= 32'd0;
        x_rs2_val      <= 32'd0;
        x_imm          <= 32'd0;
        x_rd           <= 5'd0;
        x_is_load      <= 1'b0;
        x_is_store     <= 1'b0;
        x_is_branch    <= 1'b0;
        x_is_jal       <= 1'b0;
        x_is_jalr      <= 1'b0;
        x_is_lui       <= 1'b0;
        x_is_auipc     <= 1'b0;
        x_reg_write_en <= 1'b0;
        x_mem_to_reg   <= 1'b0;
        x_alu_src_imm  <= 1'b0;
        x_rs1_idx      <= 5'd0;
        x_rs2_idx      <= 5'd0;
      end else begin
        x_pc           <= d_pc;
        x_inst         <= d_inst;
        x_valid        <= d_valid;
        x_rs1_val      <= d_rs1_val;
        x_rs2_val      <= d_rs2_val;
        x_imm          <= d_imm_sel;
        x_rd           <= d_rd;

        x_is_load      <= d_is_load_c;
        x_is_store     <= d_is_store_c;
        x_is_branch    <= d_is_branch_c;
        x_is_jal       <= d_is_jal_c;
        x_is_jalr      <= d_is_jalr_c;
        x_is_lui       <= d_is_lui_c;
        x_is_auipc     <= d_is_auipc_c;
        x_reg_write_en <= d_reg_write_en;
        x_mem_to_reg   <= d_mem_to_reg;
        x_alu_src_imm  <= d_alu_src_imm;
        x_rs1_idx      <= d_rs1;
        x_rs2_idx      <= d_rs2;
      end
    end
  end

  // ALU input (skeleton – chưa có forwarding)
  wire [6:0] x_opcode = x_inst[6:0];
  wire [2:0] x_funct3 = x_inst[14:12];
  wire [6:0] x_funct7 = x_inst[31:25];

  wire x_inst_lui = x_is_lui;
  wire x_inst_auipc = x_is_auipc;
  wire x_inst_jal = x_is_jal;
  wire x_inst_jalr = x_is_jalr;

  wire x_inst_beq = x_is_branch && (x_funct3 == 3'b000);
  wire x_inst_bne = x_is_branch && (x_funct3 == 3'b001);
  wire x_inst_blt = x_is_branch && (x_funct3 == 3'b100);
  wire x_inst_bge = x_is_branch && (x_funct3 == 3'b101);
  wire x_inst_bltu = x_is_branch && (x_funct3 == 3'b110);
  wire x_inst_bgeu = x_is_branch && (x_funct3 == 3'b111);

  wire x_inst_lb = x_is_load && (x_funct3 == 3'b000);
  wire x_inst_lh = x_is_load && (x_funct3 == 3'b001);
  wire x_inst_lw = x_is_load && (x_funct3 == 3'b010);
  wire x_inst_lbu = x_is_load && (x_funct3 == 3'b100);
  wire x_inst_lhu = x_is_load && (x_funct3 == 3'b101);

  wire x_inst_sb = x_is_store && (x_funct3 == 3'b000);
  wire x_inst_sh = x_is_store && (x_funct3 == 3'b001);
  wire x_inst_sw = x_is_store && (x_funct3 == 3'b010); 
  
  wire x_is_regreg = (x_opcode == OpcodeRegReg);  

  wire x_inst_add  = x_is_regreg && (x_funct3 == 3'b000) && (x_funct7 == 7'b0000000);
  wire x_inst_sub  = x_is_regreg && (x_funct3 == 3'b000) && (x_funct7 == 7'b0100000);
  wire x_inst_and  = x_is_regreg && (x_funct3 == 3'b111) && (x_funct7 == 7'b0000000);
  wire x_inst_or   = x_is_regreg && (x_funct3 == 3'b110) && (x_funct7 == 7'b0000000); 
  wire x_inst_xor = x_is_regreg && (x_funct3 == 3'b100) && (x_funct7 == 7'b0000000);
  wire x_inst_sll = x_is_regreg && (x_funct3 == 3'b001) && (x_funct7 == 7'b0000000);
  wire x_inst_srl = x_is_regreg && (x_funct3 == 3'b101) && (x_funct7 == 7'b0000000);  
  wire x_inst_sra = x_is_regreg && (x_funct3 == 3'b101) && (x_funct7 == 7'b0100000);
  wire x_inst_slt = x_is_regreg && (x_funct3 == 3'b010) && (x_funct7 == 7'b0000000);
  wire x_inst_sltu = x_is_regreg && (x_funct3 ==3'b011) && (x_funct7 == 7'b0000000);

  wire x_inst_mul = x_is_regreg && (x_funct3 == 3'b000) && (x_funct7 == 7'b0000001);
  wire x_inst_mulh = x_is_regreg && (x_funct3 == 3'b001) && (x_funct7 == 7'b0000001);
  wire x_inst_mulsu = x_is_regreg && (x_funct3 == 3'b010) && (x_funct7 == 7'b0000001);
  wire x_inst_mulhu = x_is_regreg && (x_funct3 == 3'b011) && (x_funct7 == 7'b0000001);
  wire x_inst_div = x_is_regreg && (x_funct3 == 3'b100) && (x_funct7 == 7'b0000001);  
  wire x_inst_divu = x_is_regreg && (x_funct3 == 3'b101) && (x_funct7 == 7'b0000001);
  wire x_inst_rem = x_is_regreg && (x_funct3 == 3'b110) && (x_funct7 == 7'b0000001);
  wire x_inst_remu = x_is_regreg && (x_funct3 == 3'b111) && (x_funct7 == 7'b0000001);

  wire x_is_regimm = (x_opcode == OpcodeRegImm);

  wire x_inst_addi = x_is_regimm && (x_funct3 == 3'b000);
  wire x_inst_andi = x_is_regimm && (x_funct3 == 3'b111);
  wire x_inst_ori = x_is_regimm && (x_funct3 == 3'b110);
  wire x_inst_xori = x_is_regimm && (x_funct3 == 3'b100);
  wire x_inst_slli = x_is_regimm && (x_funct3 == 3'b001) && (x_funct7 == 7'b0000000);
  wire x_inst_srli = x_is_regimm && (x_funct3 == 3'b101) && (x_funct7 == 7'b0000000);
  wire x_inst_srai = x_is_regimm && (x_funct3 == 3'b101) && (x_funct7 == 7'b0100000);
  wire x_inst_slti = x_is_regimm && (x_funct3 == 3'b010);
  wire x_inst_sltiu = x_is_regimm && (x_funct3 == 3'b011);

    // Nhóm DIV/REM bất kỳ
  wire x_inst_any_div =
    x_inst_div  || x_inst_divu ||
    x_inst_rem  || x_inst_remu;

  reg x_div_started;


  // Branch decision (skeleton – luôn không nhảy)
  wire x_branch_taken = 1'b0;
    // ==================================================
  // 4.x Forwarding logic (RAW hazard giải quyết cho Case1)
  // ==================================================

  // Ưu tiên: W > M > RegFile
  // Lưu ý: nếu M là load thì dữ liệu thật chỉ có ở W, nên không forward từ M khi m_is_load=1

  wire fwd_rs1_from_m = m_reg_write_en && !m_is_load &&
                         (m_rd != 5'd0) && (m_rd == x_rs1_idx);
  wire fwd_rs1_from_w = w_reg_write_reg &&
                         (w_rd_reg != 5'd0) && (w_rd_reg == x_rs1_idx);

  wire fwd_rs2_from_m = m_reg_write_en && !m_is_load &&
                         (m_rd != 5'd0) && (m_rd == x_rs2_idx);
  wire fwd_rs2_from_w = w_reg_write_reg &&
                         (w_rd_reg != 5'd0) && (w_rd_reg == x_rs2_idx);

  wire [`REG_SIZE:0] x_rs1_fwd =
    fwd_rs1_from_m ? m_alu_res    :
    fwd_rs1_from_w ? w_result_reg :
                    x_rs1_val;

  wire [`REG_SIZE:0] x_rs2_fwd =
    fwd_rs2_from_m ? m_alu_res    :
    fwd_rs2_from_w ? w_result_reg :
                    x_rs2_val;


  // ==================================================
  // ALU B-input + CLA
  // ==================================================
  reg [`REG_SIZE:0] alu_b;
  reg               alu_b_invert;
  reg               alu_cin;
  wire[`REG_SIZE:0] alu_sum;
  wire              alu_cout;

  always @(*) begin
    // default: chọn B đã tính forwarding, rồi mới xét immediate
    alu_b        = x_alu_src_imm ? x_imm : x_rs2_fwd;
    alu_b_invert = 1'b0;
    alu_cin      = 1'b0;

    // SUB dùng a + (~b) + 1
    if (x_inst_sub) begin
      alu_b_invert = 1'b1;
      alu_cin      = 1'b1;
    end
  end

  wire [`REG_SIZE:0] cla_b_input = alu_b_invert ? ~alu_b : alu_b;

  cla cla_inst (
    .a   (x_rs1_fwd),      // dùng giá trị đã forward
    .b   (cla_b_input),
    .c0  (alu_cin),
    .sum (alu_sum),
    .cout(alu_cout)
  );


    // ===========================
  // 4.x Divider control / state
  // ===========================
  // Phân loại signed / unsigned và loại phép DIV hay REM
  wire div_is_signed   = x_inst_div  || x_inst_rem;
  wire div_is_unsigned = x_inst_divu || x_inst_remu;

  wire op_is_div = x_inst_div  || x_inst_divu;
  wire op_is_rem = x_inst_rem  || x_inst_remu;

  // Lấy dấu và giá trị tuyệt đối của toán hạng A,B (cho signed DIV/REM)
  wire        sign_a = x_rs1_fwd[31];
  wire        sign_b = x_rs2_fwd[31];
  wire [31:0] abs_a  = sign_a ? (~x_rs1_fwd + 32'd1) : x_rs1_fwd;
  wire [31:0] abs_b  = sign_b ? (~x_rs2_fwd + 32'd1) : x_rs2_fwd;

  // Dividend/divisor đưa vào divider unsigned 8-stage
  wire [31:0] div_dividend = div_is_signed ? abs_a : x_rs1_fwd;
  wire [31:0] div_divisor  = div_is_signed ? abs_b : x_rs2_fwd;

  // Trạng thái divider
  localparam DIV_IDLE = 2'd0;
  localparam DIV_BUSY = 2'd1;

  reg  [1:0]  div_state;
  reg  [3:0]  div_cnt;
  reg  [31:0] div_quotient_r, div_remainder_r;
  wire [31:0] div_quotient_w, div_remainder_w;

  // Kết nối divider unsigned
  // stall của core KHÔNG cần dùng để chặn nội bộ divider, nên mình buộc về 0
  wire div_stall_to_core = 1'b0;

  DividerUnsignedPipelined divu8 (
    .clk        (clk),
    .rst        (rst),
    .stall      (div_stall_to_core),
    .i_dividend (div_dividend),
    .i_divisor  (div_divisor),
    .o_remainder(div_remainder_w),
    .o_quotient (div_quotient_w)
  );


    // ===========================
  // 4.x Divider FSM
  // ===========================
  always @(posedge clk) begin
    if (rst) begin
      div_state       <= DIV_IDLE;
      div_cnt         <= 4'd0;
      div_quotient_r  <= 32'd0;
      div_remainder_r <= 32'd0;
    end else begin
      case (div_state)
        DIV_IDLE: begin
          div_cnt <= 4'd0;
          if (div_start) begin
            div_state <= DIV_BUSY;
            div_cnt   <= 4'd1; // bắt đầu đếm từ 1
          end
        end

        DIV_BUSY: begin
          if (div_cnt == (`DIVIDER_STAGES)) begin
            // Đủ 8 stage: chốt kết quả lại
            div_quotient_r  <= div_quotient_w;
            div_remainder_r <= div_remainder_w;
            div_state       <= DIV_IDLE;
            div_cnt         <= 4'd0;
          end else begin
            // Vẫn đang pipeline
            div_cnt <= div_cnt + 4'd1;
          end
        end

        default: begin
          div_state <= DIV_IDLE;
          div_cnt   <= 4'd0;
        end
      endcase
    end
  end


    reg [`REG_SIZE:0] x_alu_res_r;

  // Nhân 64-bit cho M-extension
  wire [63:0] mult_ss = $signed(x_rs1_fwd) * $signed(x_rs2_fwd);
  wire [63:0] mult_su = $signed(x_rs1_fwd) * $unsigned(x_rs2_fwd);
  wire [63:0] mult_uu = $unsigned(x_rs1_fwd) * $unsigned(x_rs2_fwd);

  always @(*) begin
    x_alu_res_r = 32'd0;

    // ADD / ADDI / SUB (dùng cla)
    if (x_inst_add || x_inst_addi || x_inst_sub) begin
      x_alu_res_r = alu_sum;
    end
    // LOAD/STORE address calc
    else if (x_is_load || x_is_store) begin
      x_alu_res_r = alu_sum;
    end
    else if (x_inst_and || x_inst_andi) begin
      x_alu_res_r = x_rs1_fwd & alu_b;
    end
    else if (x_inst_or || x_inst_ori) begin
      x_alu_res_r = x_rs1_fwd | alu_b;
    end
    else if (x_inst_xor || x_inst_xori) begin
      x_alu_res_r = x_rs1_fwd ^ alu_b;
    end
    else if (x_inst_sll || x_inst_slli) begin
      x_alu_res_r = x_rs1_fwd << alu_b[4:0];
    end
    else if (x_inst_srl || x_inst_srli) begin
      x_alu_res_r = x_rs1_fwd >> alu_b[4:0];
    end
    else if (x_inst_sra || x_inst_srai) begin
      x_alu_res_r = $signed(x_rs1_fwd) >>> alu_b[4:0];
    end
    else if (x_inst_slt || x_inst_slti) begin
      x_alu_res_r = ($signed(x_rs1_fwd) < $signed(alu_b)) ? 32'd1 : 32'd0;
    end
    else if (x_inst_sltu || x_inst_sltiu) begin
      x_alu_res_r = (x_rs1_fwd < alu_b) ? 32'd1 : 32'd0;
    end
    else if (x_inst_lui) begin
      x_alu_res_r = x_imm;
    end
    else if (x_inst_auipc) begin
      x_alu_res_r = x_pc + x_imm;
    end
    // ---------- M-extension: MUL ----------
    else if (x_inst_mul) begin
      // MUL: low 32 bits of signed*signed
      x_alu_res_r = mult_ss[31:0];
    end
    else if (x_inst_mulh) begin
      // MULH: high 32 bits of signed*signed
      x_alu_res_r = mult_ss[63:32];
    end
    else if (x_inst_mulsu) begin
      // MULHSU: high 32 bits của signed*unsigned
      x_alu_res_r = mult_su[63:32];
    end
    else if (x_inst_mulhu) begin
      // MULHU: high 32 bits của unsigned*unsigned
      x_alu_res_r = mult_uu[63:32];
    end
    // ---------- M-extension: DIV / REM ----------
    else if (x_inst_any_div) begin
      // Trường hợp chia cho 0
      if (x_divisor_zero) begin
        if (op_is_div) begin
          // DIV, DIVU: quotient = -1
          x_alu_res_r = 32'hFFFF_FFFF;
        end else begin
          // REM, REMU: remainder = dividend
          x_alu_res_r = x_rs1_fwd;
        end
      end else begin
        // Chia bình thường
        reg [31:0] q;
        reg [31:0] r;

        if (div_done_now) begin
          // Chu kỳ cuối BUSY: lấy thẳng từ output divider
          q = div_quotient_w;
          r = div_remainder_w;
        end else begin
          // Các chu kỳ sau: lấy từ bản đã chốt
          q = div_quotient_r;
          r = div_remainder_r;
        end

        if (op_is_div) begin
          if (div_is_signed) begin
            // Nếu khác dấu thì quotient âm
            x_alu_res_r = (sign_a ^ sign_b) ? (~q + 32'd1) : q;
          end else begin
            // DIVU
            x_alu_res_r = q;
          end
        end else begin
          // REM / REMU
          if (div_is_signed) begin
            // Remainder cùng dấu với dividend (rs1)
            x_alu_res_r = sign_a ? (~r + 32'd1) : r;
          end else begin
            // REMU
            x_alu_res_r = r;
          end
        end
      end
    end
  end

  wire [`REG_SIZE:0] x_alu_res = x_alu_res_r;


  wire stall_w = global_stall;
  always @(posedge clk) begin
  if (!rst && x_valid && x_inst_any_div) begin
    $display("[X ] DIV/REM pc=0x%08x rd=%0d rs1=0x%08x rs2=0x%08x state=%0d cnt=%0d alu_res=0x%08x",
             x_pc, x_rd, x_rs1_fwd, x_rs2_fwd, div_state, div_cnt, x_alu_res);
  end
end

  // ------------------------------------------------
  // 5. MEMORY STAGE (M)
  // ------------------------------------------------
  reg [`REG_SIZE:0]  m_pc;
  reg [`INST_SIZE:0] m_inst;
  reg                m_valid;

  reg [`REG_SIZE:0]  m_alu_res;
  reg [`REG_SIZE:0]  m_rs2_val;
  reg [4:0]          m_rd;

  reg m_is_load;
  reg m_is_store;
  reg m_reg_write_en;
  reg m_mem_to_reg;
  reg [2:0] m_funct3;

  // Pipeline X -> M
  always @(posedge clk) begin
    if (rst) begin
      m_pc           <= 32'd0;
      m_inst         <= 32'd0;
      m_valid        <= 1'b0;
      m_alu_res      <= 32'd0;
      m_rs2_val      <= 32'd0;
      m_rd           <= 5'd0;
      m_is_load      <= 1'b0;
      m_is_store     <= 1'b0;
      m_reg_write_en <= 1'b0;
      m_mem_to_reg   <= 1'b0;
      m_funct3       <= 3'd0;

    end else if (xm_en) begin
      m_pc           <= x_pc;
      m_inst         <= x_inst;
      m_valid        <= x_valid;
      m_alu_res      <= x_alu_res;
      m_rs2_val      <= x_rs2_fwd;
      m_rd           <= x_rd;
      m_is_load      <= x_is_load;
      m_is_store     <= x_is_store;
      m_reg_write_en <= x_reg_write_en;
      m_mem_to_reg   <= x_mem_to_reg;
      m_funct3       <= x_funct3;
    end
  end

  // Kết nối dmem từ M stage (skeleton: store full word)
  // ---------- 5.1 STORE path ----------
  always @(*) begin
    addr_to_dmem       = m_alu_res;
    store_data_to_dmem = m_rs2_val;
    store_we_to_dmem   = 4'b0000;

    if (m_is_store) begin
      case (m_funct3)
        3'b000: begin // SB
          case (m_alu_res[1:0])
            2'b00: store_we_to_dmem = 4'b0001;
            2'b01: store_we_to_dmem = 4'b0010;
            2'b10: store_we_to_dmem = 4'b0100;
            2'b11: store_we_to_dmem = 4'b1000;
          endcase
        end
        3'b001: begin // SH
          case (m_alu_res[1:0])
            2'b00: store_we_to_dmem = 4'b0011;
            2'b10: store_we_to_dmem = 4'b1100;
          endcase
        end
        3'b010: begin // SW
          store_we_to_dmem = 4'b1111;
        end
        default: begin
          store_we_to_dmem = 4'b0000;
        end
      endcase
    end
  end

  // ---------- 5.2 LOAD path ----------
  reg [`REG_SIZE:0] m_load_data_ext;

  always @(*) begin
    m_load_data_ext = 32'd0;

    if (m_is_load) begin
      case (m_funct3)
        3'b000: begin // LB
          case (m_alu_res[1:0])
            2'b00: m_load_data_ext = {{24{load_data_from_dmem[7]}},  load_data_from_dmem[7:0]};
            2'b01: m_load_data_ext = {{24{load_data_from_dmem[15]}}, load_data_from_dmem[15:8]};
            2'b10: m_load_data_ext = {{24{load_data_from_dmem[23]}}, load_data_from_dmem[23:16]};
            2'b11: m_load_data_ext = {{24{load_data_from_dmem[31]}}, load_data_from_dmem[31:24]};
          endcase
        end
        3'b001: begin // LH
          if (m_alu_res[1] == 1'b0)
            m_load_data_ext = {{16{load_data_from_dmem[15]}}, load_data_from_dmem[15:0]};
          else
            m_load_data_ext = {{16{load_data_from_dmem[31]}}, load_data_from_dmem[31:16]};
        end
        3'b010: begin // LW
          m_load_data_ext = load_data_from_dmem;
        end
        3'b100: begin // LBU
          case (m_alu_res[1:0])
            2'b00: m_load_data_ext = {24'd0, load_data_from_dmem[7:0]};
            2'b01: m_load_data_ext = {24'd0, load_data_from_dmem[15:8]};
            2'b10: m_load_data_ext = {24'd0, load_data_from_dmem[23:16]};
            2'b11: m_load_data_ext = {24'd0, load_data_from_dmem[31:24]};
          endcase
        end
        3'b101: begin // LHU
          if (m_alu_res[1] == 1'b0)
            m_load_data_ext = {16'd0, load_data_from_dmem[15:0]};
          else
            m_load_data_ext = {16'd0, load_data_from_dmem[31:16]};
        end
        default: m_load_data_ext = 32'd0;
      endcase
    end
  end
    // ---------- 5.3 Data đưa sang W stage ----------
  wire [`REG_SIZE:0] m_wdata_pre =
    (m_is_load) ? m_load_data_ext : m_alu_res;

  // ------------------------------------------------
  // 6. WRITEBACK STAGE (W)
  // ------------------------------------------------
  reg [`REG_SIZE:0]  w_pc_reg;
  reg [`INST_SIZE:0] w_inst_reg;
  reg                w_valid_reg;

  reg [`REG_SIZE:0]  w_result_reg;
  reg [4:0]          w_rd_reg;
  reg                w_reg_write_reg;

  always @(posedge clk) begin
    if (rst) begin
      w_pc_reg        <= 32'd0;
      w_inst_reg      <= 32'd0;
      w_valid_reg     <= 1'b0;
      w_result_reg    <= 32'd0;
      w_rd_reg        <= 5'd0;
      w_reg_write_reg <= 1'b0;
    end else if (mw_en) begin
      w_pc_reg        <= m_pc;
      w_inst_reg      <= m_inst;
      w_valid_reg     <= m_valid;
      w_result_reg    <= m_wdata_pre;
      w_rd_reg        <= m_rd;
      w_reg_write_reg <= m_reg_write_en;
    end
  end

  // Xuất sang RegFile
  assign w_wdata     = w_result_reg;
  assign w_rd        = w_rd_reg;
  assign w_reg_write = w_reg_write_reg;


  // Trace outputs (so sánh với trace-*.json)
  always @(posedge clk) begin
    if (rst) begin
      trace_writeback_pc   <= 32'd0;
      trace_writeback_inst <= 32'd0;
    end else begin
      if (w_valid_reg) begin
        trace_writeback_pc   <= w_pc_reg;
        trace_writeback_inst <= w_inst_reg;
      end else begin
        trace_writeback_pc   <= 32'd0;
        trace_writeback_inst <= 32'd0;
      end
    end
  end
    wire [6:0]  w_opcode = w_inst_reg[6:0];
    wire [2:0]  w_funct3 = w_inst_reg[14:12];
    wire [6:0]  w_funct7 = w_inst_reg[31:25];

    wire w_is_regreg = (w_opcode == OpcodeRegReg);
    wire w_inst_div  = w_is_regreg && (w_funct3 == 3'b100) && (w_funct7 == 7'b0000001);
    wire w_inst_divu = w_is_regreg && (w_funct3 == 3'b101) && (w_funct7 == 7'b0000001);
    wire w_inst_rem  = w_is_regreg && (w_funct3 == 3'b110) && (w_funct7 == 7'b0000001);
    wire w_inst_remu = w_is_regreg && (w_funct3 == 3'b111) && (w_funct7 == 7'b0000001);

    wire w_inst_any_div = w_inst_div || w_inst_divu || w_inst_rem || w_inst_remu;

    always @(posedge clk) begin
      if (!rst && w_valid_reg && w_inst_any_div) begin
        $display("[WB] DIV/REM rd=x%0d, value=0x%08x", w_rd_reg, w_result_reg);
      end
    end
    
  // ------------------------------------------------
  // 7. HALT: dừng khi lệnh 0x00000073 đến W-stage
  // ------------------------------------------------
  always @(posedge clk) begin
    if (rst) begin
      halt <= 1'b0;
    end else begin
      // Khi một instruction hợp lệ tới W-stage
      if (w_valid_reg && (w_inst_reg == 32'h00000073)) begin
        halt <= 1'b1;
      end
    end
  end

endmodule

// ====================================================
// MemorySingleCycle (giữ nguyên)
// ====================================================
module MemorySingleCycle #(
    parameter NUM_WORDS = 512
) (
    input                    rst,                 // rst for both imem and dmem
    input                    clk,                 // clock for both imem and dmem
                                                  // The memory reads/writes on @(negedge clk)
    input      [`REG_SIZE:0] pc_to_imem,          // must always be aligned to a 4B boundary
    output reg [`REG_SIZE:0] inst_from_imem,      // the value at memory location pc_to_imem
    input      [`REG_SIZE:0] addr_to_dmem,        // must always be aligned to a 4B boundary
    output reg [`REG_SIZE:0] load_data_from_dmem, // the value at memory location addr_to_dmem
    input      [`REG_SIZE:0] store_data_to_dmem,  // the value to be written to addr_to_dmem
    input      [        3:0] store_we_to_dmem     // byte enables
);

  // memory is arranged as an array of 4B words
  reg [`REG_SIZE:0] mem_array[0:NUM_WORDS-1];

  // preload instructions to mem_array
  initial begin
    $readmemh("mem_initial_contents.hex", mem_array);
  end

  localparam AddrMsb = $clog2(NUM_WORDS) + 1;
  localparam AddrLsb = 2;

  always @(negedge clk) begin
    inst_from_imem <= mem_array[pc_to_imem[AddrMsb:AddrLsb]];
  end

  always @(negedge clk) begin
    if (store_we_to_dmem[0]) begin
      mem_array[addr_to_dmem[AddrMsb:AddrLsb]][7:0]   <= store_data_to_dmem[7:0];
    end
    if (store_we_to_dmem[1]) begin
      mem_array[addr_to_dmem[AddrMsb:AddrLsb]][15:8]  <= store_data_to_dmem[15:8];
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

// ====================================================
// Top-level Processor
// ====================================================
module Processor (
    input                 clk,
    input                 rst,
    output                halt,
    output [ `REG_SIZE:0] trace_writeback_pc,
    output [`INST_SIZE:0] trace_writeback_inst
);

  wire [`INST_SIZE:0] inst_from_imem;
  wire [ `REG_SIZE:0] pc_to_imem;
  wire [ `REG_SIZE:0] mem_data_addr;
  wire [ `REG_SIZE:0] mem_data_loaded_value;
  wire [ `REG_SIZE:0] mem_data_to_write;
  wire [         3:0] mem_data_we;

  // This wire is set by cocotb to the name of the currently-running test
  wire [(8*32)-1:0] test_case;

  MemorySingleCycle #(
      .NUM_WORDS(8192)
  ) memory (
    .rst                 (rst),
    .clk                 (clk),
    // imem is read-only
    .pc_to_imem          (pc_to_imem),
    .inst_from_imem      (inst_from_imem),
    // dmem is read-write
    .addr_to_dmem        (mem_data_addr),
    .load_data_from_dmem (mem_data_loaded_value),
    .store_data_to_dmem  (mem_data_to_write),
    .store_we_to_dmem    (mem_data_we)
  );

  DatapathPipelined datapath (
    .clk                  (clk),
    .rst                  (rst),
    .pc_to_imem           (pc_to_imem),
    .inst_from_imem       (inst_from_imem),
    .addr_to_dmem         (mem_data_addr),
    .store_data_to_dmem   (mem_data_to_write),
    .store_we_to_dmem     (mem_data_we),
    .load_data_from_dmem  (mem_data_loaded_value),
    .halt                 (halt),
    .trace_writeback_pc   (trace_writeback_pc),
    .trace_writeback_inst (trace_writeback_inst)
  );

endmodule
