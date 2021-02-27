pragma solidity 0.5.17;


contract BusStation {
    
    /* ==== Variables ===== */
    
    mapping(address => uint256) public _seats;
    bool _bus_has_left;
    uint256 _ticketTotal;
    uint256 _min_value;
    address payable _destination;
    
    /* ==== Events ===== */
    event TicketPurchased(address indexed _from, uint _value);
    event BusDeparts(uint _value);

    /* ==== Constructor ===== */
    constructor(
        address payable destination,
        uint256 min_value    
    ) public {
        _bus_has_left = false;
        _min_value = min_value;
        _destination = destination;
    }

    
    /* ==== Views ===== */
   function ticketTotal() public view returns(uint256) {
       return _ticketTotal;
   }
   
   function hasBusLeft() public view returns(bool) {
       return _bus_has_left;
   }

    /* ==== Functions ===== */
   function buyBusTicket() public payable {
       require(_bus_has_left == false);
       _seats[msg.sender] += msg.value;
       _ticketTotal += msg.value;
       emit TicketPurchased(msg.sender, msg.value);
    }  

   function triggerBusRide() external {
        require(_ticketTotal > _min_value);
        _destination.transfer(_ticketTotal); 
        _bus_has_left = true;
        emit BusDeparts(_ticketTotal);
        
   }
    
}
