import brownie

def test_trigger_bus_ride_locked(accounts, lockedBusStation):
    with brownie.reverts("Function is timelocked"):
        lockedBusStation.triggerBusRide()

def test_trigger_bus_ride_unlocked_no_tickets(accounts, unlockedBusStation):
    with brownie.reverts("Not enough money to leave."):
        unlockedBusStation.triggerBusRide()
        