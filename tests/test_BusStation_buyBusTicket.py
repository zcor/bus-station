import brownie
from brownie.test import given, strategy


@given(amount=strategy("uint", max_value=10 ** 19, min_value=1))
def test_buy_bus_ticket_success(accounts, unlockedBusStation, amount):
    tx = unlockedBusStation.buyBusTicket({"from": accounts[3], "amount": amount})
    assert unlockedBusStation._ticketTotal() == amount
    assert tx.events["TicketPurchased"][0]["_from"] == accounts[3]
    assert tx.events["TicketPurchased"][0]["_value"] == amount


@given(amount=strategy("uint", min_value=10 ** 10, max_value=10 ** 18))
def test_cannot_overpay(accounts, discountBusStation, amount):
    with brownie.reverts("Cannot exceed max ticket value."):
        tx = discountBusStation.buyBusTicket({"from": accounts[3], "amount": amount})


@given(amount=strategy("uint", max_value=10 ** 18, min_value=1))
def test_can_double_ticket(accounts, unlockedBusStation, amount):
    tx = unlockedBusStation.buyBusTicket({"from": accounts[3], "amount": amount})
    tx = unlockedBusStation.buyBusTicket({"from": accounts[3], "amount": amount})
    assert unlockedBusStation._ticketTotal() == amount * 2


def test_second_purchase_cannot_overpay(accounts, discountBusStation):
    amount = 10 ** 10 - 100000
    tx = discountBusStation.buyBusTicket({"from": accounts[3], "amount": amount})
    with brownie.reverts("Cannot exceed max ticket value."):
        tx = discountBusStation.buyBusTicket({"from": accounts[3], "amount": amount})


def test_buy_bus_ticket_no_money_sent(accounts, unlockedBusStation):
    with brownie.reverts("Need to pay more for ticket."):
        unlockedBusStation.buyBusTicket({"from": accounts[3], "amount": 0})


def test_buy_bus_ticket_bus_already_left(accounts, unlockedBusStation):
    riderOneAmount = 10 ** 18 - 1
    riderTwoAmount = 5
    unlockedBusStation.buyBusTicket({"from": accounts[1], "amount": riderOneAmount})
    unlockedBusStation.buyBusTicket({"from": accounts[2], "amount": riderTwoAmount})
    unlockedBusStation.triggerBusRide()

    with brownie.reverts("The bus already left."):
        unlockedBusStation.buyBusTicket({"from": accounts[3], "amount": 0})
