//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

contract AuctionHouse {
    address public owner;
    string public item;
    uint public auctionEndTime;
    address private highestBidder;
    uint private highestBid;
    bool public ended;

    mapping(address => uint) public bids;
    mapping(address => uint) public pendingReturns;
    address[] public biddersList;

    event NewBid(address indexed bidder, uint amount);
    event AuctionEnded(address indexed winner, uint amount);
    event Withdrawal(address indexed bidder, uint amount);

    constructor(string memory _item, uint _duration) {
        owner = msg.sender;
        item = _item;
        auctionEndTime = block.timestamp + _duration;
    }

    function bid() external payable {
        require(block.timestamp < auctionEndTime, "auction already ended");
        require(msg.value > 0, "amount must be greater than 0");
        
        uint newBid = bids[msg.sender] + msg.value;
        require(newBid > highestBid, "need to place higher bid");

        if(bids[msg.sender] == 0) {
            biddersList.push(msg.sender);
        }

        // Update the bidder's total bid
        bids[msg.sender] = newBid;

        // If this is a new highest bid, update the highest bidder
        if(newBid > highestBid) {
            // If there was a previous highest bidder, add their bid to pending returns
            if(highestBidder != address(0)) {
                pendingReturns[highestBidder] += highestBid;
            }
            
            highestBidder = msg.sender;
            highestBid = newBid;
        } else {
            // If this bid didn't become the highest, add it to pending returns
            pendingReturns[msg.sender] += msg.value;
        }

        emit NewBid(msg.sender, newBid);
    }

    function withdraw() external {
        uint amount = pendingReturns[msg.sender];
        require(amount > 0, "no funds to withdraw");
        
        pendingReturns[msg.sender] = 0;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "withdrawal failed");
        
        emit Withdrawal(msg.sender, amount);
    }

    function endAuction() external {
        require(block.timestamp >= auctionEndTime, "auction not yet ended");
        require(!ended, "auction already ended");

        ended = true;
        
        // Transfer the highest bid to the owner
        if(highestBidder != address(0)) {
            (bool success, ) = owner.call{value: highestBid}("");
            require(success, "transfer to owner failed");
        }

        emit AuctionEnded(highestBidder, highestBid);
    }

    function getBiddersList() external view returns(address[] memory) {
        return biddersList;
    }

    function getWinner() external view returns(address, uint) {
        require(ended, "auction not ended yet");
        return (highestBidder, highestBid);
    }

    function getPendingReturns(address bidder) external view returns(uint) {
        return pendingReturns[bidder];
    }
}