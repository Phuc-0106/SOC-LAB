# CASE 1: Basic ALU + immediate (no memory)

    addi x1, x0, 10         # x1 = 10
    addi x2, x0, 20         # x2 = 20

    add  x3, x1, x2         # x3 = 30
    sub  x4, x1, x2         # x4 = 10 - 20 = -10 = 0xfffffff6

    addi x5, x0, -5         # x5 = -5 = 0xfffffffb
    add  x6, x3, x5         # x6 = 30 + (-5) = 25

    and  x7, x3, x2         # x7 = 30 & 20 = 20
    or   x8, x3, x5         # x8 = 0x0000001e | 0xfffffffb = 0xffffffff
    xor  x9, x1, x2         # x9 = 10 XOR 20 = 30

    slt  x10, x5, x0        # signed: -5 < 0 => 1
    sltu x11, x5, x0        # unsigned: 0xfffffffb > 0 => 0

    # HALT sẽ được gen_hex.py chèn thêm (0x00000073)
