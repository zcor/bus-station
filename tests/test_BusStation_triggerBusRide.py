import brownie

def test_trigger_bus_ride_locked(accounts, lockedBusStation):
    with brownie.reverts("Function is timelocked."):
        lockedBusStation.triggerBusRide()

def test_trigger_bus_ride_unlocked_no_tickets(accounts, unlockedBusStation):
    with brownie.reverts("Not enough wei to leave."):
        unlockedBusStation.triggerBusRide()

def test_trigger_bus_ride_success(accounts, unlockedBusStation):
    # arrange
    riderOneAmount = 10**18 - 1
    riderTwoAmount = 5
    startingDestinationBalance = accounts[0].balance()
    startingRiderOneBalance = accounts[1].balance()
    startingRiderTwoBalance = accounts[2].balance()

    # act
    unlockedBusStation.buyBusTicket({'from': accounts[1], 'amount': riderOneAmount})
    unlockedBusStation.buyBusTicket({'from': accounts[2], 'amount': riderTwoAmount})
    tx = unlockedBusStation.triggerBusRide()

    # assert
    assert unlockedBusStation._hasBusLeft() == True
    assert unlockedBusStation._ticketTotal() == 0
    assert accounts[0].balance() == startingDestinationBalance + riderOneAmount + riderTwoAmount
    assert accounts[1].balance() == startingRiderOneBalance - riderOneAmount
    assert accounts[2].balance() == startingRiderTwoBalance - riderTwoAmount
    assert tx.events['BusDeparts']['_value'] > 0
    
