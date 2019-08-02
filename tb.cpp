// Copyright (C) 2019, Gray Research LLC.

#include "Vtop.h"
#include "verilated.h"

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);
    Vtop* top = new Vtop;
    while (!Verilated::gotFinish()) {
        top->eval();
    }
    delete top;
    return 0;
}
