import brownie


def test_withdraw_has_no_ticket(accounts, unlockedBusStation):
    with brownie.reverts("Address does not have a ticket."):
        unlockedBusStation.withdraw({"from": accounts[1]})


def test_withdraw_success(accounts, unlockedBusStation):
    # arrange
    riderOneAmount = 10 ** 18 - 1
    riderTwoAmount = 5
    startingRiderOneBalance = accounts[1].balance()
    startingRiderTwoBalance = accounts[2].balance()

    # act
    unlockedBusStation.buyBusTicket({"from": accounts[1], "amount": riderOneAmount})
    unlockedBusStation.buyBusTicket({"from": accounts[2], "amount": riderTwoAmount})
    unlockedBusStation.withdraw({"from": accounts[1]})
    unlockedBusStation.withdraw({"from": accounts[2]})

    # assert
    assert unlockedBusStation._ticketTotal() == 0
    assert accounts[1].balance() == startingRiderOneBalance
    assert accounts[2].balance() == startingRiderTwoBalance


def test_withdraw_can_not_withdraw_twice(accounts, unlockedBusStation):
    # arrange
    riderOneAmount = 10 ** 18 - 1

    # act
    unlockedBusStation.buyBusTicket({"from": accounts[1], "amount": riderOneAmount})
    unlockedBusStation.withdraw({"from": accounts[1]})

    with brownie.reverts("Address does not have a ticket."):
        unlockedBusStation.withdraw({"from": accounts[1]})


def test_withdraw_only_depositers_can_withdraw(accounts, unlockedBusStation):
    # arrange
    riderOneAmount = 10 ** 18 - 1

    # act
    unlockedBusStation.buyBusTicket({"from": accounts[1], "amount": riderOneAmount})

    with brownie.reverts("Address does not have a ticket."):
        unlockedBusStation.withdraw({"from": accounts[2]})


def test_cannot_withdraw_after_bus_departs(accounts, departedBus):
    with brownie.reverts("Bus has already left."):
        departedBus.withdraw({"from": accounts[1]})
