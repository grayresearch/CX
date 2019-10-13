# Copyright (C) 2019, Gray Research LLC
#
HDRS=cfu.vh
SRCS=tb.v cfu.v popcount.v bnn.v mulacc.v

v/tb: $(HDRS) $(SRCS)
	verilator -Wall --cc $(SRCS) --top-module TB --Mdir v --exe tb.cpp
	make -j -C v -f VTB.mk VTB

clean:
	rm -r v
