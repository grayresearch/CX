// Copyright (C) 2019, Gray Research LLC.

#include "VTB.h"
#include "verilated.h"

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);
    VTB* tb = new VTB;
    tb->rst = 1;
    while (!Verilated::gotFinish()) {
        tb->clk = 1;
        tb->eval();
        tb->clk = 0;
        tb->eval();

        tb->rst = 0;
    }
    delete tb;
    return 0;
}
