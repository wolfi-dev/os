import asyncio

import pytest
import pytest_asyncio

events = []


@pytest_asyncio.fixture
async def resource():
    events.append("setup")
    await asyncio.sleep(0)
    yield 42
    events.append("teardown")


@pytest.mark.asyncio
async def test_sleep():
    await asyncio.sleep(0)


@pytest.mark.asyncio
async def test_fixture(resource):
    assert resource == 42
    assert asyncio.get_running_loop().is_running()


# Runs after test_fixture in file order, proving the async generator
# fixture's teardown half was driven to completion.
def test_teardown_ran():
    assert events == ["setup", "teardown"]
