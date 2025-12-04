# CASE 13: WD bypass
addi x1, x0, 5
addi x2, x0, 7
add  x3, x1, x2    # x3 = 12   (enter W stage)
add  x4, x3, x0    # MUST read new x3 via WD bypass
