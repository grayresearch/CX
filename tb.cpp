// Copyright (C) 2019, Gray Research LLC.

#include "VTB.h"
#include "verilated.h"

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);
    VTB* tb = new VTB;
	tb->reset = 1;
	while (!Verilated::gotFinish()) {
		tb->clock = 1;
        tb->eval();
		tb->clock = 0;
        tb->eval();

		tb->reset = 0;
    }
    delete tb;
    return 0;
}
