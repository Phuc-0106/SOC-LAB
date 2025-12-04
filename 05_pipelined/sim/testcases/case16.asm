addi x1, x0, 100
addi x2, x0, 3
div  x3, x1, x2     # x3 = 33

div  x4, x3, x2     # MUST stall until x3 available
