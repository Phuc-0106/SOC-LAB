# ===========================
# CASE 5: MULTI-CYCLE STYLE TEST
# Data memory base: 0x400 (1024)
# Chạy tốt với gen_hex.py (không dùng MUL/DIV)
# ===========================

########################################
# 1. CƠ BẢN: ADD, ADDI, SUB
########################################
addi x1, x0, 10          # x1 = 10
addi x2, x0, 20          # x2 = 20
add  x3, x1, x2          # x3 = 30

sub  x4, x3, x1          # x4 = 20
sub  x5, x1, x2          # x5 = -10 (0xFFFF FFF6)

addi x6, x0, -5          # x6 = -5
add  x7, x6, x1          # x7 = 5

########################################
# 2. LUI / AUIPC
########################################
lui  x8,  0x12345        # x8  = 0x12345000
auipc x9, 1              # x9  = PC + 0x1000

########################################
# 3. WORD LOAD / STORE (BASE = 0x400)
########################################
addi x10, x0, 1024       # x10 = 1024 (base data addr 0x400)
addi x11, x0, 555        # x11 = 555
sw   x11, 0(x10)         # Mem[1024] = 555
lw   x12, 0(x10)         # x12 = 555

########################################
# 4. BYTE STORE / LOAD (BASE = 0x400 + 100)
########################################
addi x13, x10, 100       # x13 = 1124
addi x14, x0, -1         # x14 = -1 (0xFFFF FFFF)
sb   x14, 0(x13)         # Mem[1124] = 0xFF
lb   x15, 0(x13)         # x15 = -1 (sign-extend)
lbu  x16, 0(x13)         # x16 = 255 (0x000000FF)

########################################
# 5. HALF-WORD STORE / LOAD (BASE = 0x400 + 200)
########################################
addi x17, x10, 200       # x17 = 1224
lui  x18, 0x0
addi x18, x18, 0x234     # x18 = 0x00000234
sh   x18, 0(x17)         # Mem[1224] = 0x34, Mem[1225] = 0x02
lh   x19, 0(x17)         # x19 = 0x00000234 (564)
lhu  x20, 0(x17)         # x20 = 0x00000234 (564, zero-extend)

########################################
# 6. OFFSET LOAD / STORE (BASE = 0x400)
########################################
# x10 vẫn là 1024
sw   x11, 4(x10)         # Mem[1028] = 555
lw   x21, 4(x10)         # x21 = 555

########################################
# 7. BRANCH: BEQ/BNE (taken & not taken)
########################################
# 7.1 BEQ không nhảy (not taken)
addi x1, x0, 1           # x1 = 1
addi x2, x0, 2           # x2 = 2
beq  x1, x2, 8           # 1 != 2 => không nhảy, thực thi addi x22
addi x22, x0, 123        # x22 = 123

# 7.2 BEQ nhảy (taken) – skip 1 lệnh
addi x3, x0, 5           # x3 = 5
addi x4, x0, 5           # x4 = 5
beq  x3, x4, 8           # equal -> nhảy qua addi x23
addi x23, x0, 999        # SKIP nếu BEQ đúng
addi x24, x0, 10         # x24 = 10

# 7.3 BNE nhảy (taken)
addi x5, x0, 100         # x5 = 100
addi x6, x0, 200         # x6 = 200
bne  x5, x6, 8           # khác -> nhảy qua addi x25
addi x25, x0, 999        # SKIP
addi x26, x0, 20         # x26 = 20

########################################
# 8. VÒNG LẶP NHỎ VỚI BLT (OFFSET ÂM)
# Ghi 0,1,2,3 vào 4 ô nhớ liên tiếp:
#   Mem[0x400 + 16], 20, 24, 28
########################################
addi x27, x10, 16        # x27 = 1024 + 16 = 1040 (base loop)
addi x28, x0, 0          # x28 = i = 0
addi x29, x0, 4          # x29 = limit = 4

# LOOP:
sw   x28, 0(x27)         # store i
addi x27, x27, 4         # base += 4
addi x28, x28, 1         # i++
blt  x28, x29, -12       # nếu i < 4 => nhảy về sw (3 lệnh * 4B = 12)

########################################
# 9. JAL – NHẢY QUA 2 LỆNH
########################################
jal  x30, 12             # x30 = PC+4, nhảy qua 2 lệnh tiếp theo
addi x1, x0, 999         # SKIP
addi x2, x0, 999         # SKIP
addi x31, x0, 42         # x31 = 42 (sentinel cuối)
