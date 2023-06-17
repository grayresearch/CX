## monitors.py: testbench bus monitoring

'''
Copyright (C) 2019-2023, Gray Research LLC.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
'''

import cocotb
from cocotb.handle import SimHandleBase
from cocotb.queue import Queue
from cocotb.triggers import RisingEdge, Timer

from enum import IntEnum
from typing import Any, Dict

# Monitor: collect bus signals when valid, and ready (if not None), are asserted on posedge(clk).
class Monitor:
    def __init__(self, clk:SimHandleBase, valid: SimHandleBase, ready: SimHandleBase, datas: Dict[str, SimHandleBase]):
        self.values = Queue[Dict[str,int]]()
        self._clk = clk
        self._datas = datas
        self._valid = valid
        self._ready = ready
        self._coro = None

    def start(self) -> None:
        if self._coro is not None:
            raise RuntimeError("monitor started")
        self._coro = cocotb.start_soon(self._run())

    def stop(self) -> None:
        if self._coro is None:
            raise RuntimeError("monitor not started")
        self._coro.kill()
        self._coro = None

    async def _run(self) -> None:
        while True:
            await RisingEdge(self._clk)
            if self._valid == 1 and (self._ready is None or self._ready == 1):
                self.values.put_nowait(self._sample())

    def _sample(self) -> Dict[str, Any]:
        return { name: handle.value for name, handle in self._datas.items() }
