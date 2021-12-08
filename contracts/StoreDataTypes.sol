// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

library StoreDataTypes {

    enum STATUS{Accepted, Waitlist, Cancelled, Shipped}


    struct Order {
        STATUS _status;
        uint _id;
        uint _price;
        uint _collection;
        bytes32 _orderData;
        address _purchaser;
        address _owner;
        address _referral;
        uint _timestamp;
    }

    struct Item {
        uint _basePrice;
        string _name;
        address _beneficiary;
        bool _forSale; 
        uint _maxAmount;
        uint _stock; //amount that can be accepted, after theyre waitlisted
        
    }


}