# CASE17: LB / LBU / LH / LHU sign & zero extend

    addi x1, x0, 0          # clear x1
    lui  x1, 0x12345        # x1 = 0x12345000
    addi x1, x1, 0x678      # x1 = 0x12345678

    sw   x1, 0(x0)

    lb   x2, 0(x0)          # 0x78 sign-extend  => 0x00000078
    lbu  x3, 0(x0)          # 0x78 zero-extend  => 0x00000078

    lh   x4, 0(x0)          # 0x5678 sign-extend => 0x00005678
    lhu  x5, 0(x0)          # 0x5678 zero-extend => 0x00005678

    # HALT sẽ được gen_hex.py tự chèn: 00000073
