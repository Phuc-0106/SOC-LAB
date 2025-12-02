# ===========================
# FIXED TEST CASE FOR RISC-V SINGLE CYCLE
# Data memory moved to offset 1024 (0x400)
# ===========================

# --- CASE 1: ADD, ADDI ---
addi x1, x0, 10
addi x2, x0, 20
add  x3, x1, x2        # x3 = 30

# --- CASE 2: SUB ---
sub  x4, x3, x1        # x4 = 20
sub  x5, x1, x2        # x5 = -10 (0xFFFFFFF6)

# --- CASE 3: ADDI Negative ---
addi x6, x0, -5        # x6 = -5
add  x7, x6, x1        # x7 = 5

# --- CASE 4: LUI ---
lui  x8, 0x12345       # x8 = 0x12345000

# --- CASE 5: AUIPC ---
auipc x9, 1            # x9 = PC + 0x1000

# --- CASE 6: Word Load/Store (BASE = 0x400) ---
addi x1, x0, 1024      # x1 = 1024 (Base Data Address)
addi x2, x0, 555       # x2 = 555
sw   x2, 0(x1)         # Mem[1024] = 555
lw   x3, 0(x1)         # x3 = 555 (Ghi đè lại x3 cũ)

# --- CASE 7: Byte Store/Load (BASE = 0x400 + 100) ---
addi x4, x1, 100       # x4 = 1124
addi x5, x0, -1        # x5 = -1
sb   x5, 0(x4)         # Mem[1124] = 0xFF
lb   x6, 0(x4)         # x6 = -1 (0xFFFFFFFF)
lbu  x7, 0(x4)         # x7 = 255 (0x000000FF)

# --- CASE 8: Half-word (BASE = 0x400 + 200) ---
addi x8, x1, 200       # x8 = 1224
lui  x9, 0x1
addi x9, x9, 0x234     # x9 = 0x1234
sh   x9, 0(x8)         # Mem[1224] = 0x34, Mem[1225] = 0x12
lh   x10, 0(x8)        # x10 = 0x1234 (4660)

# --- CASE 9: Offset Load ---
# x1 đang là 1024.
# Ghi 555 vào Mem[1028]
sw   x2, 4(x1)         
lw   x11, 4(x1)        # x11 = 555

# --- CASE 10: BRANCH & JUMP ---
# Lưu ý: Các thanh ghi x1-x8 sẽ bị ghi đè để test branch

# 10.1 BEQ (Taken)
addi x1, x0, 5
addi x2, x0, 5
beq  x1, x2, 8         # Nhảy qua addi x30
addi x30, x0, 999      # SKIP (Nếu x30 = 0 là đúng)
addi x12, x0, 10       # x12 = 10 (Dùng x12 thay x4 để dễ debug)

# 10.2 BNE (Taken)
addi x5, x0, 100
addi x6, x0, 200
bne  x5, x6, 8         # Nhảy qua addi x31
addi x31, x0, 999      # SKIP
addi x13, x0, 20       # x13 = 20

# 10.3 JAL
jal  x14, 12           # x14 = PC+4, Nhảy qua 2 lệnh
addi x28, x0, 999      # SKIP
addi x29, x0, 999      # SKIP
addi x15, x0, 30       # x15 = 30

# 10.4 JALR
auipc x16, 0
addi  x16, x16, 20     # Tính offset tới TARGET
jalr  x17, 0(x16)      # Jump
addi  x27, x0, 999     # SKIP
addi  x26, x0, 999     # SKIP

TARGET:
addi  x18, x0, 40      # x18 = 40