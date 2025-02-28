// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {PriceConverter} from "./PriceConverter.sol";

// Outside the contract
error NotOwner();

contract FundMe {

    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 5e18;

    address[] public funders;

    mapping(address funder => uint256 amountFunded) public addressToAmountFunded;

    address public immutable contractOwner;

    constructor() {
        contractOwner = msg.sender;
    }

    function fund() public payable {
        require(msg.value.getConversionRate() >= MINIMUM_USD, "Didn't send enough ETH");
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {
        for(uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++)
        {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }

        // Reset funders array.
        funders = new address[](0);

        // Withdraw funds: 3 methods

        // Transfer method
        //   Will revert the transaction
        // payable(msg.sender).transfer(address(this).balance);

        // Send method
        //   Will return boolean
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");

        // Call method
        (bool callSuccess, /* bytes memory dataReturned */ ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Failed to send Ether");
    }

    modifier onlyOwner() {
        // Less gaz efficient
        // require(contractOwner == msg.sender, NotOwner());
        
        if(contractOwner != msg.sender)
        {
            revert NotOwner();
        }
        _;
    }
}