import brownie
from brownie.test import given, strategy


@given(amount=strategy('uint', max_value=10**19, min_value=1))
def test_buy_bus_ticket_success(accounts, unlockedBusStation, amount):
    unlockedBusStation.buyBusTicket({'from': accounts[3], 'amount': amount})
    assert unlockedBusStation._ticketTotal() == amount

def test_buy_bus_ticket_no_money_sent(accounts, unlockedBusStation):
    with brownie.reverts("Need to pay something for the ticket."):
        unlockedBusStation.buyBusTicket({'from': accounts[3], 'amount': 0})

def test_buy_bus_ticket_bus_already_left(accounts, unlockedBusStation):
    riderOneAmount = 10**18 - 1
    riderTwoAmount = 5
    unlockedBusStation.buyBusTicket({'from': accounts[1], 'amount': riderOneAmount})
    unlockedBusStation.buyBusTicket({'from': accounts[2], 'amount': riderTwoAmount})
    unlockedBusStation.triggerBusRide()

    with brownie.reverts("The bus already left."):
        unlockedBusStation.buyBusTicket({'from': accounts[3], 'amount': 0})

