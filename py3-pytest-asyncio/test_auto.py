import asyncio

import pytest


@pytest.fixture
async def value():
    await asyncio.sleep(0)
    return "ok"


async def test_unmarked(value):
    assert value == "ok"


async def test_gather():
    assert await asyncio.gather(asyncio.sleep(0, 1), asyncio.sleep(0, 2)) == [1, 2]
