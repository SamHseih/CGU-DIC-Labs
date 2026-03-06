.PHONY: all run  vcs sim clean

VCS_FLAGS = -full64 -sverilog \
	-P $(VERDI_HOME)/share/PLI/VCS/LINUX64/novas.tab $(VERDI_HOME)/share/PLI/VCS/LINUX64/pli.a \
	-f run.f -l compile.log

SIM_FLAGS = -no_save -l run.log

all: run

run: vcs sim

vcs:
	vcs $(VCS_FLAGS)

sim:
	./simv $(SIM_FLAGS)
clean:
	rm -rf *.log csrc simv* *.key *.vpd DVEfiles coverage *.vdb *.fsdb novas.* nWaveLog BSSLib.lib++
