// SPDX-License-Identifier: MIT
// Pool Party proof of concept, a one-way bus trip

/*-+++++++--\                                                                         
     /    :####:   \                                                   
    /     .####.    \                                                     
   /==-    .##.   -==\                                                          
   +#####++.##.++####+                                                                  
   +#####++.##.++####+........................................................             
   \==-    .##.   -==/.-----------------------------------------------------+.             
    \     .####.    / ~:.:~:.:~:.:~:.:~:.:~:.:~:.:~:.:~:.:~:.:~:.:~:.:~:.:~:|.             
     \    :####:   /~:.:~:.:~:.:~:.:~:.:~:.:~:.:~:.:~:.:~:.:~:.:~:.:~:.:~:.:|.
      \--+++++++--/~:.:~:.:~:.:~:.:~:.:~:.:~:.:~:.:~:.:~:.:~:.:~:.:~:.:~:.::|.
                .|~:.:~:.::      ~::  \   / ~:.:~:.:~:.:~::  ~::~:.:~:.:~:~.|.
                :|::~:.:~~:   :  ~:    .:.   ~:   |    ~:.:  ~:.:~:.:~:.:~::|.
                :|~:.:~:.::      ~:---=:::=--: \ .::./  ~::  ::~:.:~~:.:~:~.|.
                :|:~.~:.~:.   ~:.::     .    :   ::::   ~::  ~:.:~:.:~:.:~::|.
                :|~:.:~:.:.   ~:.:~::  / \  .: /  .. \  ~::      :.:~:.:~::~|.
                :|:~:.:~:.:~:.:~:.:~:.:~:.:~:.::.  |  .~:.:~:.:~::~:.:~:.:~:|.
                :|~:.:~:.::.:~:.:~:.:~:.:~:.:~:.:~:.:~:.:~:.:~:.:~:.:~:.:~:~|.
                :|~::~:.:~:      ~::   ~::      :       :  :  ~:.:~:.:~:.:~:|.
                :|~:.:~:.:~   :  ~:     ~:   :  ~::   ~::  .  ~:.:~:.:~:.:~:|.
                :|:~:.:~:.:      ~:  :  ~:     .~::   ~:.:   ~:.:~:.:~:.:~::|.
                :|~:.:~:.:~   ~:.::     ~:  .   ~::   ~:~:   ~:.:~:/--+++++++--\  
                :|:.:~:.:~:   ~:..:  :  ~:  ~:  ~::   ~:.:. .~:.::/    :####:   \    
                :|~:~.:~:.:~:.:~:.:~:.:~:.:~:.:~:.:~:.:~:.:~:.:~:/     .####.    \  
                :|:.:~:.:~:.:~:.:.~:.:~:.:~:.:~:.:~:.:~:.:~:.:~:/=-     .##.    -=\  
                :|~:.:~:.:~:.:~:.:~::~:.:~:.:~:.:~:.:~:.:~~:.:~:+#####++.##.++####+      
                :+----------------------------------------------+#####++.##.++####+      
                ................................................\=-     .##.    -=/      
                                                                 \     .####.    /       
                                                                  \    :####:   /        
                                                                   \--+++++++-*/

pragma solidity ^0.8.0;

contract BusStation {
    /* ==== Variables ===== */

    mapping(address => uint256) public _seats;
    bool public _hasBusLeft;
    uint256 public _ticketTotal;
    uint256 public _minTicketValue = 0;
    uint256 public _maxTicketValue;
    uint256 public _minWeiToLeave;
    address payable private _destination;

    uint256 public _timelockDuration;
    uint256 public _endOfTimelock;

    /* ==== Events ===== */

    event TicketPurchased(address indexed _from, uint256 _value);
    event Withdrawal(address indexed _from, uint256 _value);
    event BusDeparts(uint256 _value);

    /* ==== Constructor ===== */

    // Set up a one-way bus ride to a destination, with reserve price, time of departure, and cap on ticket prices for fairness
    constructor(
        address payable destination,
        uint256 minWeiToLeave,
        uint256 timelockSeconds,
        uint256 maxTicketValue
    ) {
        super;
        _hasBusLeft = false;
        _minWeiToLeave = minWeiToLeave;
        _maxTicketValue = maxTicketValue;
        _destination = destination;
        _timelockDuration = timelockSeconds;
        _endOfTimelock = block.timestamp + _timelockDuration;
    }

    /* ==== Functions ===== */

    // Purchase a bus ticket if eligible
    function buyBusTicket() external payable canPurchaseTicket {
        _seats[msg.sender] += msg.value;
        _ticketTotal += msg.value;
        emit TicketPurchased(msg.sender, msg.value);
    }

    // If bus is eligible, anybody can trigger the bus ride
    function triggerBusRide() external isReadyToRide {
        uint256 amount = _ticketTotal;
        _ticketTotal = 0;
        _hasBusLeft = true;
        _destination.transfer(amount);
        emit BusDeparts(amount);
    }

    // If eligible to withdraw, then pull money out
    function withdraw() external {
        // Cannot withdraw after bus departs
        require(_hasBusLeft == false, "Bus has already left.");

        // Retrieve user balance
        uint256 amount = _seats[msg.sender];
        require(amount > 0, "Address does not have a ticket.");

        // Write data before transfer to guard against re-entrancy
        _seats[msg.sender] = 0;
        _ticketTotal -= amount;
        payable(msg.sender).transfer(amount);
        emit Withdrawal(msg.sender, amount);
    }

    /* === Modifiers === */

    // Can only purchase ticket if bus has not left and ticket purchase amount is small
    modifier canPurchaseTicket() {
        require(_hasBusLeft == false, "The bus already left.");
        require(msg.value > _minTicketValue, "Need to pay more for ticket.");
        require(
            msg.value + _seats[msg.sender] < _maxTicketValue,
            "Cannot exceed max ticket value."
        );
        _;
    }

    // Bus can ride if timelock is passed and tickets exceed reserve price
    modifier isReadyToRide() {
        require(_endOfTimelock <= block.timestamp, "Function is timelocked.");
        require(_hasBusLeft == false, "Bus is already gone.");
        require(_ticketTotal >= _minWeiToLeave, "Not enough wei to leave.");
        _;
    }
}
