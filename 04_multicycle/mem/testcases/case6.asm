# ===========================================
# CASE 6 - Divider test (DIVU / REMU)
# Tập trung kiểm tra divider unsigned 8-stage
# ===========================================

# --- Test 1: 100 / 7 = 14 r 2 ---
addi x1, x0, 100      # dividend1 = 100
addi x2, x0, 7        # divisor1  = 7

divu x3, x1, x2       # x3 = 14
remu x4, x1, x2       # x4 = 2

# --- Test 2: 37 / 5 = 7 r 2 ---
addi x5, x0, 37       # dividend2 = 37
addi x6, x0, 5        # divisor2  = 5

divu x7, x5, x6       # x7 = 7
remu x8, x5, x6       # x8 = 2

# --- Test 3: 0 / 10 = 0 r 0 ---
addi x9,  x0, 0       # dividend3 = 0
addi x10, x0, 10      # divisor3  = 10

divu x11, x9, x10     # x11 = 0
remu x12, x9, x10     # x12 = 0

# --- Mixing thêm vài lệnh thường để đảm bảo pipeline ổn ---
addi x13, x0, 1       # x13 = 1
addi x14, x13, 2      # x14 = 3

# Lệnh ECALL/halt sẽ được gen_hex.py chèn tự động (0x00000073)
