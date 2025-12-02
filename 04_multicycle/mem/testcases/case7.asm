# case7.asm - Extra test for 8-stage pipelined unsigned divider (DIVU/REMU)
# Mục tiêu:
#  - Kiểm tra chia không dấu với nhiều pattern khác nhau
#  - Có dependency giữa các phép chia để ép stall của multi-cycle datapath
#  - Không dùng chia cho divisor = 0 để tránh phụ thuộc vào xử lý corner-case

############################
# Scenario 1: Chain DIVU/REMU
# 100 / 7 = 14, remainder = 2
# 14  / 3 = 4,  remainder = 2
############################

    addi x1, x0, 100        # x1 = 100
    addi x2, x0, 7          # x2 = 7

    divu x3, x1, x2         # x3 = x1 / x2 = 100 / 7 = 14
    addi x4, x0, 3          # x4 = 3

    divu x5, x3, x4         # x5 = x3 / x4 = 14 / 3 = 4
    remu x6, x3, x4         # x6 = x3 % x4 = 14 % 3 = 2

############################
# Scenario 2: Back-to-back DIVU + REMU
# 255 / 16 = 15, remainder = 15
############################

    addi x7,  x0, 255       # x7  = 255
    addi x8,  x0, 16        # x8  = 16

    divu x9,  x7, x8        # x9  = 255 / 16 = 15
    remu x10, x7, x8        # x10 = 255 % 16 = 15

############################
# Scenario 3: Another distinct pair
# 200 / 11 = 18, remainder = 2
############################

    addi x11, x0, 200       # x11 = 200
    addi x12, x0, 11        # x12 = 11

    divu x13, x11, x12      # x13 = 200 / 11 = 18
    remu x14, x11, x12      # x14 = 200 % 11 = 2

    # (Không cần ecall/halt: script Python sẽ tự chèn 00000073 vào cuối)
