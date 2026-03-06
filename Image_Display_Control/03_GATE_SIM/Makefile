.PHONY: all run sim clean run_all

# 預設跑 tb1，你也可以在命令列覆寫：make run TEST_NAME=tb2
TEST_NAME ?= tb1

# 專案名（xxx），預設你可以改
DESIGN ?= LCD_CTRL
# Gate-level 需要的檔案
CELL_LIB    = /cad/CBDK/CBDK_IC_Contest_v2.5/Verilog/tsmc13_neg.v
# Netlist / SDF 位置（實際檔名仍可覆寫）
GATE_SDF ?= ../02_SYN/Netlist/$(DESIGN)_syn.sdf

# testbench
TB := ../00_TESTBED/testfixture.v
TOP ?= test

VCS_FLAGS = -full64 -sverilog \
	-override_timescale=1ns/10ps \
	+define+GATE \
	+define+$(TEST_NAME) \
	+incdir+../00_TESTBED \
	+incdir+../02_SYN/Netlist \
	+define+SDF \
	-debug_access+all \
	+v2k \
	+neg_tchk \
	-v $(CELL_LIB) \
	-P $(VERDI_HOME)/share/PLI/VCS/LINUX64/novas.tab $(VERDI_HOME)/share/PLI/VCS/LINUX64/pli.a \
	-l compile_$(TEST_NAME).log \
	-o simv_$(TEST_NAME)

SIM_FLAGS = -no_save  -l run_$(TEST_NAME).log

all: run

run: vcs sim
# 重要：不要再把 $(GATE_V) 放進 command line
# 因為 TESTBED.v 已經 `include "CC_SYN.v"` 了，避免重複編譯造成 redefinition
vcs:
	@echo "[INFO] TB       : $(TB)"
	@echo "[INFO] NETLIST  : ../02_SYN/Netlist/$(DESIGN)_syn.v  (included by TESTBED.v)"
	@echo "[INFO] SDF      : $(GATE_SDF)"
	vcs $(VCS_FLAGS) -top $(TOP) $(TB) 

sim: 
	./simv_$(TEST_NAME) $(SIM_FLAGS)

# 修改點 6: 新增 run_all，用迴圈一次跑完
run_all:
	make run TEST_NAME=tb1
	make run TEST_NAME=tb2
	make run TEST_NAME=tb3

cleanall:
	rm -rf INCA_libs nWaveLog *.fsdb *.log *~ *.sdf* *.key *.conf simv csrc simv.daidir
