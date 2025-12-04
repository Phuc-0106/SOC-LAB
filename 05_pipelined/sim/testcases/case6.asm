# CASE 6: Branch correctness + flush

# x1 = 5, x2 = 5 → beq taken
addi x1, x0, 5
addi x2, x0, 5
beq  x1, x2, 8     # skip one instruction
addi x3, x0, 999   # must be flushed
addi x4, x0, 10    # expected x4 = 10

# x5 = 100, x6 = 200 → bne taken
addi x5, x0, 100
addi x6, x0, 200
bne  x5, x6, 8
addi x7, x0, 999   # must be flushed
addi x8, x0, 20    # expected x8 = 20

# default: untouched regs = 0
