# CASE3: LUI + SLTI

    # x1 = 0x12345000
    lui   x1, 0x12345

    # x2 = x1 + 0x789 = 0x12345789
    addi  x2, x1, 0x789

    # x3 = -1 = 0xffffffff
    addi  x3, x0, -1

    # x4 = 1 vì 0 < 1 (signed)
    slti  x4, x0, 1

    # x5 = 0 vì 0 < -1 là false (signed)
    slti  x5, x0, -1

    # HALT
    ecall
