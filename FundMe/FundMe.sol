//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./PriceConverter.sol"; // Library

// custom errors
error NotOwner();
error NotEnoughMoneySent();
error TransferFailed();

contract FundMe {

    using PriceConverter for uint256; // using library.

    uint256 public constant MINIMUM_USD = 50 * 1e18;

    address payable public immutable i_owner;

    constructor() {
        i_owner = payable(msg.sender); // setting owner of the contract.
    }

    address[] public funders; // holds address of account who calls fund function.

    mapping(address => uint256) public addressToAmount;

    function fund() public payable {
        //require(msg.value.getConversionRate() >= MINIMUM_USD, "not enough money");
        if (msg.value.getConversionRate() < MINIMUM_USD) {
            revert NotEnoughMoneySent();
        }

        funders.push(msg.sender);
        addressToAmount[msg.sender] += msg.value; // mapping address to amount sent. 
    }

    function withdraw() public onlyOwner {
        // resetting map
        for (uint256 i = 0; i < funders.length; i++) {
            addressToAmount[funders[i]] = 0;
        }

        // resetting array
        funders = new address[](0);

        // withdraw fund
        (bool callSuccess, ) = i_owner.call{value: address(this).balance}("");
        //require(callSuccess, "Failed");
        if (!callSuccess) {
            revert TransferFailed();
        }
    }

    // only owner modifier
    modifier onlyOwner {
        //require(msg.sender == i_owner, "Not Owner");
        if (msg.sender != i_owner) {
            revert NotOwner();
        }
        _;
    }

    // these functions catch the eth which is sent not using fund function and redirect to fund function
    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

}