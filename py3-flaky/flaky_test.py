import random
from flaky import flaky
import pytest
import unittest


@flaky(max_runs=5, min_passes=5)
def test_always_passes():
    assert True, "This test will always pass."