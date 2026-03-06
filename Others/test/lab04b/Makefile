.PHONY: all vcs sim dve clean
VCS_FLAGS = -full64 -sverilog -P $(VERDI_HOME)/share/PLI/VCS/LINUX64/novas.tab $(VERDI_HOME)/share/PLI/VCS/LINUX64/pli.a -lca  -f run.f -l compile.log
SIM_FLAGS = -l run.log

all:	run

run:	vcs sim

vcs:
	vcs $(VCS_FLAGS)

sim:
	./simv $(SIM_FLAGS)

dve:
	dve -ssf wave.fsdb &

clean:
	rm -rf *.log csrc simv* *.key *.vpd DVEfiles coverage *.vdb *.fsdb novas.* nWaveLog BSSLib.lib++
