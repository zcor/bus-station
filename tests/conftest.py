#!/usr/bin/python3

import pytest

@pytest.fixture(scope="function", autouse=True)
def isolate(fn_isolation):
    # perform a chain rewind after completing each test, to ensure proper isolation
    # https://eth-brownie.readthedocs.io/en/stable/tests-pytest-intro.html#isolation-fixtures
    pass

@pytest.fixture(scope="module")
def lockedBusStation(BusStation, accounts):
    return BusStation.deploy(accounts[0], 2, 4, {'from': accounts[1]})

@pytest.fixture(scope="module")
def unlockedBusStation(BusStation, accounts):
    return BusStation.deploy(accounts[0], 2, 0, {'from': accounts[1]})
