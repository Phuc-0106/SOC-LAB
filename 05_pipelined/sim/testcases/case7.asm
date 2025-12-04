# CASE 7: JAL + JALR + link correctness (spec-correct)

    # --- Test JAL ---
    # PC map:
    # 0:  addi x1, 10
    # 4:  jal  x2, 8        -> target = 4 + 8 = 12
    # 8:  addi x3, 999      -> phải bị FLUSH
    # 12: addi x4, 7        -> thực thi

    addi x1, x0, 10
    jal  x2, 8          # x2 = 8, nhảy tới PC=12
    addi x3, x0, 999    # phải flush
    addi x4, x0, 7      # x4 = 7

    # --- Test JALR ---
    # Ta muốn JALR nhảy tới địa chỉ 32 (addi x9)
    # Layout:
    # 16: addi x5, 32       # chuẩn bị rs1 = 32 (target)
    # 20: addi x6, 0
    # 24: jalr x7, x5, 0    # x7 = 28 (PC+4), PC_new = (32+0)&~1 = 32
    # 28: addi x8, 999      # phải bị FLUSH
    # 32: addi x9, 30       # x9 = 30
    # 36: halt

    addi x5, x0, 32
    addi x6, x0, 0
    jalr x7, x5, 0      # x7 = 28, nhảy tới PC=32
    addi x8, x0, 999    # phải flush
    addi x9, x0, 30     # x9 = 30

    # HALT (gen_hex.py auto chèn 0x00000073)
