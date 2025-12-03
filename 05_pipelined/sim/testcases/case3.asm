# CASE 3: LUI + SLTI / SLTIU

    lui  x1, 0x12345        # x1 = 0x12345000
    addi x2, x1, 0x789      # x2 = 0x12345789

    addi x3, x0, -1         # x3 = -1 = 0xffffffff

    slti  x4, x3, 0         # signed: -1 < 0 => 1
    sltiu x5, x3, 0         # unsigned: 0xffffffff < 0 ? => 0

    # HALT auto
