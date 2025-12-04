# CASE 10: Memory → ALU hazard chain

addi x1, x0, 123
sw   x1, 0(x0)
lw   x2, 0(x0)
add  x3, x2, x2     # 246
add  x4, x3, x2     # 246 + 123 = 369
