# 05_pipelined/Makefile
# Makefile cho RISC-V pipelined: nhiều testcase + nhiều testbench

# ========================
# 0) Cấu hình chung
# ========================
CASE ?= case1          # mặc định chạy case1 (sim/testcases/case1.asm)

ASM  := sim/testcases/$(CASE).asm
HEX  := mem_initial_contents.hex

IVERILOG      ?= iverilog
VVP           ?= vvp
PYTHON        ?= python3
IVERILOG_FLAGS = -g2012

# Lấy số case từ chuỗi "case1" -> "1", "case5" -> "5"
CASE_NUM := $(patsubst case%,%,$(CASE))

CASES = case1 case2 case3 case4 case5 case6 case7 case8 case9 case10 case11 case12 case13 case14 case15 case16 case17

.PHONY: all sim_py run_proc run_all_cases \
        run_case1 run_case2 run_case3 run_case4 run_case5 \
        wave clean

# ========================
# 1) Mặc định: chạy processor với CASE hiện tại
# ========================
all: run_proc

# ========================
# 2) Assemble ASM -> mem_initial_contents.hex (chỉ dùng Python)
# ========================
sim_py:
	@echo "============================================"
	@echo "  Assemble $(ASM) -> $(HEX)"
	@echo "============================================"
	cd sim && $(PYTHON) gen_hex.py \
		--input testcases/$(CASE).asm \
		--output ../$(HEX) \
		--no-sim

# ========================
# 3) Verilog: Processor pipelined
#    (dùng tb/tb_processor_$(CASE_NUM).v tương ứng)
# ========================
run_proc: sim_py
	@echo "============================================"
	@echo "  Compile Verilog với tb_processor_$(CASE_NUM).v"
	@echo "============================================"
	$(IVERILOG) $(IVERILOG_FLAGS) -o sim_proc \
		DatapathPipelined.v tb/tb_processor_$(CASE_NUM).v
	@echo "============================================"
	@echo "  Run sim_proc (CASE = $(CASE))"
	@echo "============================================"
	$(VVP) sim_proc

# ========================
# 4) Shortcut: chạy từng case trực tiếp
#    Ví dụ: make run_case1 hoặc make run_case3
# ========================
run_case1:
	$(MAKE) run_proc CASE=case1

run_case2:
	$(MAKE) run_proc CASE=case2

run_case3:
	$(MAKE) run_proc CASE=case3

run_case4:
	$(MAKE) run_proc CASE=case4

run_case5:
	$(MAKE) run_proc CASE=case5
run_case6:
	$(MAKE) run_proc CASE=case6

run_case7:
	$(MAKE) run_proc CASE=case7

run_case8:
	$(MAKE) run_proc CASE=case8

run_case9:
	$(MAKE) run_proc CASE=case9

run_case10:
	$(MAKE) run_proc CASE=case10

run_case11:	
	$(MAKE) run_proc CASE=case11

run_case12:
	$(MAKE) run_proc CASE=case12

run_case13:
	$(MAKE) run_proc CASE=case13
run_case14:
	$(MAKE) run_proc CASE=case14
run_case15:
	$(MAKE) run_proc CASE=case15
run_case16:
	$(MAKE) run_proc CASE=case16
run_case17:
	$(MAKE) run_proc CASE=case17	
# ========================
# 5) Chạy tất cả testcase (case1..case5)
#    Python gen_hex + Verilog cho từng case
# ========================
run_all_cases:
	@for c in $(CASES); do \
		echo "============================================"; \
		echo ">>> RUNNING $$c (Python gen_hex + Verilog)"; \
		echo "============================================"; \
		$(MAKE) run_proc CASE=$$c; \
		echo ""; \
	done

# ========================
# 6) Waveform (sau khi vừa chạy 1 case)
# ========================
wave:
	gtkwave pipelined_processor.vcd &

# ========================
# 7) Dọn dẹp
# ========================
clean:
	rm -f sim_proc pipelined_processor.vcd $(HEX)
