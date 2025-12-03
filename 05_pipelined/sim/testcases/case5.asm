# CASE 5: Mixed ALU + memory + data dependencies

    addi x1, x0, 5          # x1 = 5
    addi x2, x0, 7          # x2 = 7
    add  x3, x1, x2         # x3 = 12

    addi x4, x3, 10         # x4 = 22

    addi x5, x0, 1024       # x5 = 1024 (base address)
    sw   x4, 0(x5)          # mem[0x400] = 22

    lw   x6, 0(x5)          # x6 = 22
    add  x7, x6, x3         # x7 = 22 + 12 = 34
    addi x8, x7, -2         # x8 = 32

    # HALT auto
