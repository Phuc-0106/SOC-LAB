##################################################################################################
#This file created by Huy Nguyen
#Updated date: 6/30/2019
#Example run string: make TESTNAME={name_of_testcase} {optional}
#		     make TESTNAME=counter_test all 
##################################################################################################
#Define variables
TESTNAME 		?= 
TB_NAME 		?= test_bench_processor
RADIX			?= decimal
REGRESS_LIST	?= pat.list

#==============================
QUESTA_PATH=/mnt/c/questasim64_10.2c/win64
VLIB=$(QUESTA_PATH)/vlib.exe
VMAP=$(QUESTA_PATH)/vmap.exe
VLOG=$(QUESTA_PATH)/vlog.exe
VSIM=$(QUESTA_PATH)/vsim.exe
VCOVER=$(QUESTA_PATH)/vcover.exe

all: build run

all_wave: build run wave

all_cov: build_cov run_cov

build:
	mkdir -p log
	$(call copy_test,$(TESTNAME))
	$(VLIB) work
	$(VMAP) work work
	$(VLOG)  -f compile.f | tee compile.log
build_cov:
	mkdir -p log
	$(call copy_test,$(TESTNAME))
	$(VLIB) work
	$(VMAP) work work
	$(VLOG) +cover=bcesft -f compile.f
run:
# 	$(VSIM) -debugDB -l $(TESTNAME).log -voptargs=+access -assertdebug -c $(TB_NAME) -do "log -r /*;run -all;"
	$(VSIM) -debugDB -l $(TESTNAME).log -voptargs=+acc -assertdebug -c $(TB_NAME) -do "log -r /*;run -all;"
	cp $(TESTNAME).log ./log
	mv $(TESTNAME).log sim.log
run_cov:
	$(VSIM) -debugDB -coverage -l $(TESTNAME).log -c $(TB_NAME) -voptargs="+access+cover=bcesft" -assertdebug -do "coverage save -onexit $(TESTNAME).ucdb; log -r /*;run -all"
	cp $(TESTNAME).log ./log
	mv $(TESTNAME).log sim.log
wave:
	$(VSIM) -i -view vsim.wlf -do "add wave vsim:/$(TB_NAME)/*; radix -$(RADIX)" &
gen_cov:
	mkdir -p coverage
	$(VCOVER) merge IP.ucdb *.ucdb
	$(VCOVER) report IP.ucdb -output coverage/summary_report.txt
	$(VCOVER) report -zeros -details -code bcesft  -all -codeAll IP.ucdb -output coverage/detail_report.txt
	#$(VCOVER) report -zeros -details -code bcesft -all -codeAll IP.ucdb -output coverage/detail_report.txt
gen_html:
	mkdir -p coverage
	$(VCOVER) merge IP.ucdb *.ucdb
	$(VCOVER) report -zeros -details -code bcesft  -testhitdataAll -html IP.ucdb 
view_cov:
	$(VCOVER) -gui -viewcov IP.ucdb &
clean:
	rm -rf work
	rm -rf vsim.dbg
	rm -rf *.ini
	rm -rf *.log
	rm -rf *.wlf
	rm -rf transcript
	rm -rf *.ucdb
	rm -rf run_test.v
	rm -rf log
	rm -rf *.vcd
help:
	@echo ""
	@echo "****************************************"
	@echo "** make clean    : clean all compiled data"
	@echo "** make build    : build the design"
	@echo "** make build_cov: build the design in coverage mode"
	@echo "** make run      : run simulation"
	@echo "** make run_cov  : run simulation in coverage mode"
	@echo "** make all      : build and run simulation"
	@echo "** make all_cov  : build and run simulation in coverage mode"
	@echo "** make wave     : open waveform"
	@echo "** make gen_cov  : merge, generate coverage data base and text coverage report"
	@echo "** make gen_cov  : merge, gemerate coverage data base and html coverage report"
	@echo "****************************************"
	@echo ""

#============
# Function: copy_test
define copy_test
	@if [ -n "$(1)" ] && [ -f "../testcases/$(1).v" ]; then \
		cp -rf ../testcases/$(1).v run_test.v; \
	else \
		cp -rf ../testcases/testcase_sample.v run_test.v; \
	fi
endef
