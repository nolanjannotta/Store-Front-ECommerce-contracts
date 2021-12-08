// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "./StoreDataTypes.sol";
 

contract BeneficiarySplit is PaymentSplitter {

    using StoreDataTypes for StoreDataTypes.Item;

    address public owner;

    modifier onlyOwner{
        require(_msgSender() == owner, "You can't call this");
        _;
    }


    StoreDataTypes.Item public details;

    constructor(StoreDataTypes.Item memory _details, address _owner, address[] memory payees, uint256[] memory shares_) PaymentSplitter(payees, shares_) {
        details = _details;
        owner = _owner;
        details._beneficiary = address(this);

    }

    function pushPayment(address _payee) public onlyOwner {
        release(payable(_payee));

    }

    function withdraw() public {
        release(payable(_msgSender()));
    }

    function contractBalance() public view returns (uint) {
        return address(this).balance;
    }

    function individualBalance() internal view returns (uint256) {
        uint256 totalReceived = address(this).balance + totalReleased();
        return (totalReceived * shares(_msgSender())) / totalShares() - released(_msgSender());
    }







}
