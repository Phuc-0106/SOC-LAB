# CASE 12: DIV / DIVU / REM / REMU regression, dùng nhiều thanh ghi

    # 1. Khởi tạo các hằng dương
    addi x1,  x0, 100        # x1 = 100
    addi x2,  x0, 7          # x2 = 7
    addi x3,  x0, 255        # x3 = 255
    addi x4,  x0, 16         # x4 = 16
    addi x5,  x0, 42         # x5 = 42
    addi x6,  x0, 9          # x6 = 9

    # 2. Các giá trị âm để test DIV/REM signed
    addi x7,  x0, -100       # x7 = -100
    addi x8,  x0, -7         # x8 = -7
    addi x9,  x0, -42        # x9 = -42

    # 3. Các cặp DIV/REM signed

    # 100 / 7
    div  x10, x1, x2         # x10 = 14
    rem  x11, x1, x2         # x11 = 2

    # 100 / -7
    div  x12, x1, x8         # x12 = -14  (trunc toward zero)
    rem  x13, x1, x8         # x13 = 2    (cùng dấu với dividend 100)

    # -100 / 7
    div  x14, x7, x2         # x14 = -14
    rem  x15, x7, x2         # x15 = -2   (-100 = -14*7 + -2)

    # -100 / -7
    div  x16, x7, x8         # x16 = 14
    rem  x17, x7, x8         # x17 = -2   (-100 = 14*(-7) + -2)

    # 4. Các cặp DIVU/REMU unsigned

    # 255 / 16
    divu x18, x3, x4         # x18 = 15
    remu x19, x3, x4         # x19 = 15

    # 42 / 9 (dương hết, signed/unsigned giống nhau)
    div  x20, x5, x6         # x20 = 4
    remu x21, x5, x6         # x21 = 6

    # -42 / 9 signed
    div  x22, x9, x6         # x22 = -4
    rem  x23, x9, x6         # x23 = -6   (-42 = -4*9 + -6)

    # 5. Trường hợp chia cho 0 (behavior theo spec RISC-V)
    addi x24, x0, 0          # x24 = 0 làm divisor

    # DIV/REM signed với divisor = 0
    div  x25, x1, x24        # x25 = -1 (0xFFFFFFFF)
    rem  x26, x1, x24        # x26 = 100 (giữ nguyên dividend)

    # DIVU/REMU unsigned với divisor = 0
    divu x27, x1, x24        # x27 = 0xFFFFFFFF
    remu x28, x1, x24        # x28 = 100

    # 6. Kết hợp kết quả để dùng thêm các thanh ghi cuối
    add  x29, x10, x18       # x29 = 14 + 15 = 29
    add  x30, x20, x21       # x30 = 4 + 6 = 10
    add  x31, x29, x30       # x31 = 29 + 10 = 39

    # HALT sẽ được gen_hex.py chèn tự động (0x00000073)
