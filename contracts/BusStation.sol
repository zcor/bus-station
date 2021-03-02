// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

contract BusStation is Ownable {
    
    /* ==== Variables ===== */
    
    mapping(address => uint256) public _seats;
    bool public _hasBusLeft;
    uint256 public _ticketTotal;
    uint256 _minTicketValue = 0;
    uint256 _minAmountToLeave;
    address payable _destination;
    
    uint256 private constant _daysMultiplier = 60 * 60 * 24; // seconds in a day
    uint256 public _timelockDuration;
    uint256 public _endOfTimelock;
    
    /* ==== Events ===== */
    event TicketPurchased(address indexed _from, uint _value);
    event BusDeparts(uint _value);

    /* ==== Constructor ===== */
    constructor(
        address payable destination,
        uint256 minAmountToLeave,
        uint256 timelockDays
    ) {
        super;
        _hasBusLeft = false;
        _minAmountToLeave = minAmountToLeave;
        _destination = destination;
        _timelockDuration = timelockDays * _daysMultiplier;
        _endOfTimelock = block.timestamp + _timelockDuration;
    }

    /* ==== Functions ===== */
    function buyBusTicket() public payable canPurchaseTicket{
        _seats[msg.sender] += msg.value;
        _ticketTotal += msg.value;
        emit TicketPurchased(msg.sender, msg.value);
    }  

   function triggerBusRide() external isReadyToRide{
        _destination.transfer(_ticketTotal); 
        _hasBusLeft = true;
        emit BusDeparts(_ticketTotal);
   }
   
   /* === Modifiers === */
   
    modifier canPurchaseTicket() {
        require(_hasBusLeft == false, "The bus already left!");
        require(msg.value > _minTicketValue, "Need to pay something for the ticket.");
        _;
    }
    
    modifier isReadyToRide() {
        require(_endOfTimelock <= block.timestamp, "Function is timelocked");
        require(_ticketTotal >= _minAmountToLeave, "Not enough money to leave.");
        _;
    }

   /* === Locking ==== */

    function lockFunction() external onlyOwner {
        _endOfTimelock = block.timestamp + _timelockDuration;
    }
  
    function unlockFunction() external onlyOwner {
        _endOfTimelock = 0;
    }
}
