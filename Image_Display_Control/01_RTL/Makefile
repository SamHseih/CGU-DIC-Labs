.PHONY: all run sim clean run_all

# 預設跑 tb1，你也可以在命令列覆寫：make run TEST_NAME=tb2
TEST_NAME ?= tb1

TOP ?= test
TB_FILE ?= ../00_TESTBED/testfixture.v

# 修改點 1: 將寫死的 tb2 改成變數 $(TEST_NAME)
# 修改點 2: 將 log 檔名加入 $(TEST_NAME) 避免覆蓋
VCS_FLAGS = -full64 -sverilog \
	+incdir+../00_TESTBED \
	+define+$(TEST_NAME) \
	+define+RTL \
	-P $(VERDI_HOME)/share/PLI/VCS/LINUX64/novas.tab $(VERDI_HOME)/share/PLI/VCS/LINUX64/pli.a \
	-l compile_$(TEST_NAME).log \
	-o simv_$(TEST_NAME)

# 修改點 3: 執行檔與 log 也加入變數
SIM_FLAGS = -no_save -l run_$(TEST_NAME).log

all: run

# 單獨跑一個 (預設 tb1)
run: vcs sim

# 修改點 4: 編譯時產生專屬的執行檔 (simv_tb1, simv_tb2...)
vcs:
	vcs $(VCS_FLAGS) -top $(TOP) $(TB_FILE)

# 修改點 5: 執行對應的執行檔
sim:
	./simv_$(TEST_NAME) $(SIM_FLAGS)

# 修改點 6: 新增 run_all，用迴圈一次跑完
run_all:
	make run TEST_NAME=tb1
	make run TEST_NAME=tb2
	make run TEST_NAME=tb3

clean:
	rm -rf *.log csrc simv* *.key *.vpd DVEfiles coverage *.vdb *.fsdb novas.* nWaveLog BSSLib.lib++ ucli.key