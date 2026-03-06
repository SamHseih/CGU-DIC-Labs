.PHONY: all run sim cleanall 

# 專案名（xxx），預設你可以改
DESIGN ?= LBP
# Gate-level 需要的檔案
CELL_LIB    = /cad/CBDK/CBDK_UMC018_ITRI_v0.8/CIC/Verilog/UDVS_u018mm.v
# Netlist / SDF 位置（實際檔名仍可覆寫）
GATE_SDF ?= ./$(DESIGN)_syn.sdf

# testbench
TB := ../00_TESTBED/testfixture_018_postsim.v
TOP ?= testfixture

VCS_FLAGS = -full64 -sverilog \
	-override_timescale=1ns/1fs \
	+define+GATE \
	+incdir+../00_TESTBED \
	+incdir+../05_Post_Sim_UMC018 \
	+define+SDF \
	-debug_access+all \
	+v2k \
	+neg_tchk \
	-v $(CELL_LIB) \
	-P $(VERDI_HOME)/share/PLI/VCS/LINUX64/novas.tab $(VERDI_HOME)/share/PLI/VCS/LINUX64/pli.a \
	-l compile.log 

SIM_FLAGS = -no_save -l run.log

all: run
run: vcs sim
# 重要：不要再把 $(GATE_V) 放進 command line
# 因為 TESTBED.v 已經 `include "CC_SYN.v"` 了，避免重複編譯造成 redefinition
vcs:
	@echo "[INFO] TB       : $(TB)"
	@echo "[INFO] NETLIST  : ./05_Post_Sim_UMC018/$(DESIGN)_syn.v  (included by TESTBED.v)"
	@echo "[INFO] SDF      : $(GATE_SDF)"
	vcs $(VCS_FLAGS) -top $(TOP) $(TB) 

sim: 
	./simv $(SIM_FLAGS)

cleanall:
	rm -rf INCA_libs nWaveLog *.fsdb *.log *~ *.sdf* *.key *.conf simv csrc simv.daidir
