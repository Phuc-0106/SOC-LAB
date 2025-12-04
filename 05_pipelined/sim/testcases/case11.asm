# CASE 11: Mixed hazards

# ALU chain
addi x1, x0, 10
addi x2, x0, 20
add  x3, x1, x2     # 30

# branch using ALU result
beq  x3, x3, 8
addi x4, x0, 999
addi x5, x0, 7      # x5 = 7

# memory
sw   x3, 0(x0)
lw   x6, 0(x0)      # 30

add  x7, x6, x5     # 37
