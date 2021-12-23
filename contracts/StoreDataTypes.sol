// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

library StoreDataTypes {

    enum STATUS{Accepted, Waitlist, Cancelled, Shipped}


    struct Order {
        STATUS _status;
        uint _id;
        uint _price;
        uint _collection;
        uint _timestamp;
        bytes32 _orderData;
        address _purchaser;
        address _owner;
        address[] _referrals;
    }

    struct Item {
        uint _currentId;
        uint _basePrice;
        uint _totalSupply;
        uint _stock; //amount that can be accepted, after they're waitlisted
        uint _stockCounter; // keeps track of current stock number, when _currentCounter == _stock, items are waitlisted
        uint _waitlistSize;
        string _name;
        address _beneficiary;
        bool _forSale; 
    }


}