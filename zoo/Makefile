## Makefile

# Copyright (C) 2019-2023, Gray Research LLC.
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#    http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Requires cocotb cocotb-test pytest-xdist iverilog verilator-5.006+

# FIXME. This will be completely replaced shortly.

all:
	python3 mux_cfu_gen.py -p 1
	python3 mux_cfu_gen.py -p 2
	python3 mux_cfu_gen.py -p 3
	make SIM=icarus tests
	make SIM=verilator tests

tests:
	pytest -n auto popcount_cfu_test.py
	pytest -n auto bnn_cfu_test.py
	pytest -n auto mulacc_cfu_test.py
	pytest -n auto dotprod_cfu_test.py
	pytest -n auto bnn_l1_cfu_test.py
	pytest -n auto bnn_l2_cfu_test.py
	pytest -n auto bnn_l1_l2_cfu_test.py
	pytest -n auto mulacc_l2_cfu_test.py
	pytest -n auto mux_macs_cfu_test.py

clean:
	cocotb-clean
