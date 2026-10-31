import asyncio

import pytest

loops = []


@pytest.mark.asyncio(loop_scope="module")
async def test_first():
    loops.append(asyncio.get_running_loop())


@pytest.mark.asyncio(loop_scope="module")
async def test_second():
    assert asyncio.get_running_loop() is loops[0]
