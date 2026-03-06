.PHONY: all run sim clean

# 你可以在命令列覆寫：make TOP=xxx run
TOP ?= tb
TB_FILE ?= ../00_TESTBED/encoder_tb.v


VCS_FLAGS = -full64 -sverilog \
	+incdir+../00_TESTBED \
	+define+RTL \
	-P $(VERDI_HOME)/share/PLI/VCS/LINUX64/novas.tab $(VERDI_HOME)/share/PLI/VCS/LINUX64/pli.a \
	-l compile.log

SIM_FLAGS = -no_save -l run.log

all: run

run: vcs sim

vcs:
	vcs $(VCS_FLAGS) -top $(TOP) $(TB_FILE)

sim:
	./simv $(SIM_FLAGS)
clean:
	rm -rf *.log csrc simv* *.key *.vpd DVEfiles coverage *.vdb *.fsdb novas.* nWaveLog BSSLib.lib++ simv* ucli.key csrc
