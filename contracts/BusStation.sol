// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BusStation{
    
    /* ==== Variables ===== */
    
    mapping(address => uint256) public _seats;
    bool public _hasBusLeft;
    uint256 public _ticketTotal;
    uint256 public _minTicketValue = 0;
    uint256 public _minWeiToLeave;
    address payable private _destination;
    
    uint256 public _timelockDuration;
    uint256 public _endOfTimelock;
    
    /* ==== Events ===== */
    event TicketPurchased(address indexed _from, uint _value);
    event BusDeparts(uint _value);

    /* ==== Constructor ===== */
    constructor(
        address payable destination,
        uint256 minWeiToLeave,
        uint256 timelockSeconds
    ) {
        super;
        _hasBusLeft = false;
        _minWeiToLeave = minWeiToLeave;
        _destination = destination;
        _timelockDuration = timelockSeconds;
        _endOfTimelock = block.timestamp + _timelockDuration;
    }

    /* ==== Functions ===== */
    function buyBusTicket() external payable canPurchaseTicket {
        _seats[msg.sender] += msg.value;
        _ticketTotal += msg.value;
        emit TicketPurchased(msg.sender, msg.value);
    }  

    function triggerBusRide() external isReadyToRide {
        uint256 amount = _ticketTotal;
        _ticketTotal = 0;
        _hasBusLeft = true;
        _destination.transfer(amount); 
        emit BusDeparts(amount);
    }

    function withdraw() external {
        require(_seats[msg.sender] > 0, "Address does not have a ticket.");
        uint256 amount = _seats[msg.sender];
        _seats[msg.sender] = 0;
        _ticketTotal -= amount;
        payable(msg.sender).transfer(amount);
    }
   
    /* === Modifiers === */
   
    modifier canPurchaseTicket() {
        require(_hasBusLeft == false, "The bus already left.");
        require(msg.value > _minTicketValue, "Need to pay more for ticket.");
        _;
    }
    
    modifier isReadyToRide() {
        require(_endOfTimelock <= block.timestamp, "Function is timelocked.");
        require(_ticketTotal >= _minWeiToLeave, "Not enough wei to leave.");
        _;
    }
}
