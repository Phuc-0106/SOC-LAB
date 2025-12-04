# CASE 9: MX/WX bypass stress

addi x1, x0, 1
addi x2, x0, 2
add  x3, x1, x2     # x3 = 3
add  x4, x3, x2     # x4 = 5  (uses x3)
add  x5, x4, x3     # x5 = 8
add  x6, x5, x4     # x6 = 13
add  x7, x6, x5     # x7 = 21
