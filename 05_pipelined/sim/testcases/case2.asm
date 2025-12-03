# CASE 2: Shift operations

    addi x1, x0, 1          # x1 = 1
    slli x2, x1, 3          # x2 = 1 << 3 = 8
    slli x3, x1, 10         # x3 = 1 << 10 = 1024

    addi x4, x0, -16        # x4 = -16 = 0xfffffff0

    srli x5, x4, 2          # logical shift right: 0xfffffff0 >> 2 = 0x3ffffffc
    srai x6, x4, 2          # arithmetic shift right: -16 >> 2 = -4 = 0xfffffffc

    # HALT auto by gen_hex.py
