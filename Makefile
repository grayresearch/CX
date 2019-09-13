# Copyright (C) 2019, Gray Research LLC
#
SRCS=cfu.v 

v/top: $(SRCS)
	verilator -Wall --cc $(SRCS) --top-module top --Mdir v --exe tb.cpp
	make -j -C v -f Vtop.mk Vtop

clean:
	rm -r v
