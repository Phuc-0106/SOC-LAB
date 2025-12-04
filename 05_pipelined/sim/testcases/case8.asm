# CASE 8: Branch hazard + load-use hazard chain

addi x1, x0, 5
addi x2, x0, 5
beq  x1, x2, 8
addi x3, x0, 999
addi x4, x0, 10

# load-use leading into branch
addi x5, x0, 100
sw   x5, 0(x0)
lw   x6, 0(x0)

beq  x6, x5, 8
addi x7, x0, 999
addi x8, x0, 42
