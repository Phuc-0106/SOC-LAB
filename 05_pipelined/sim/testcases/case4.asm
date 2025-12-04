# =========================================
# CASE4 - Loads/Stores
# Mục tiêu:
#   x1 = 0x00000400                      (base addr)
#   x2 = 0x11223344 (sau khi lw lại)
#   x3 = 0x00000044 (LBU byte 0)
#   x4 = 0x00000033 (LBU byte 1)
#   x5 = 0x00001122 (LHU halfword trên)
#   x6 = 0x00003344 (LHU halfword dưới)
# =========================================

    # x1 = 0x400
    addi x1, x0, 0x400

    # x2 = 0x11223344 = (0x11223 << 12) | 0x344
    lui  x2, 0x11223
    ori  x2, x2, 0x344

    # store word x2 -> [x1]
    sw   x2, 0(x1)

    # load lại nguyên word -> x2 = 0x11223344
    lw   x2, 0(x1)

    # byte thấp nhất -> 0x44
    lbu  x3, 0(x1)

    # byte thứ 2 -> 0x33
    lbu  x4, 1(x1)

    # halfword trên (addr + 2) -> 0x1122
    lhu  x5, 2(x1)

    # halfword dưới (addr + 0) -> 0x3344
    lhu  x6, 0(x1)

    # HALT (assembler sẽ chèn 00000073)
    # (không cần tự viết, gen_hex.py đã tự append)
