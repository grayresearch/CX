# Copyright (C) 2019, Gray Research LLC
#
SRCS=tb.v cfu.v popcount.v bnn.v mulacc.v

v/tb: $(SRCS)
    verilator -Wall --cc $(SRCS) --top-module TB --Mdir v --exe tb.cpp
    make -j -C v -f VTB.mk VTB

clean:
    rm -r v
