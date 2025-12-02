# 04_multicycle/Makefile

# ========================
# Cấu hình chung
# ========================
CASE ?= case5

ASM  := mem/testcases/$(CASE).asm
HEX  := mem_initial_contents.hex

IVERILOG_FLAGS = -g2012

.PHONY: all sim_py run_proc run_all_cases \
        test_divider run_divider_proc clean

all: run_proc

# ========================
# 1) Assemble + Python simulator
# ========================
sim_py:
	cd mem && python3 gen_hex.py \
		--input testcases/$(CASE).asm \
		--output ../$(HEX)

# ========================
# 2) Verilog: Processor Multi-cycle
#    (dùng tb_ProcessorMultiCycle.v hiện tại)
# ========================
run_proc: sim_py
	iverilog $(IVERILOG_FLAGS) -o sim_proc \
		DatapathMultiCycle.v sim/tb_ProcessorMultiCycle.v
	vvp sim_proc

# ========================
# 3) Chạy tất cả test case cho DatapathMultiCycle
#    (case0, case1, case2, case4, case5, case6)
# ========================
run_all_cases:
	@for c in case0 case1 case2 case4 case5 case6 case7; do \
		echo "===================================="; \
		echo ">>> RUNNING $$c (Python + Verilog)"; \
		echo "===================================="; \
		$(MAKE) run_proc CASE=$$c; \
		echo ""; \
	done

# ========================
# 4) Test divider riêng (case6 + tb divider)
# ========================
# a) Python + hex for case6
test_divider:
	$(MAKE) sim_py CASE=case6

# b) Verilog tb mới chỉ cho divider
run_divider_proc: test_divider
	iverilog $(IVERILOG_FLAGS) -o sim_proc_div \
		DatapathMultiCycle.v sim/tb_ProcessorMultiCycle_divider.v
	vvp sim_proc_div

# ========================
# 5) Test divider module đơn lẻ (đã có sẵn)
# ========================
test_divider_module:
	iverilog $(IVERILOG_FLAGS) -o sim_divider \
		DividerUnsignedPipelined.v sim/tb_DividerUnsignedPipelined.v
	vvp sim_divider
# ========================
# 6) Test divider 8-stage (đã có sẵn)
# ========================
test_divider_case7:
	$(MAKE) sim_py CASE=case7

run_divider_proc_case7: test_divider_case7
	iverilog $(IVERILOG_FLAGS) -o sim_proc_div_case7 \
		DatapathMultiCycle.v sim/tb_ProcessorMultiCycle_divider_case7.v
	vvp sim_proc_div_case7


# ========================
# 6) Dọn dẹp
# ========================
clean:
	rm -f sim_proc sim_proc_div sim_divider \
	      processor_mc.vcd divider.vcd \
	      $(HEX)
