// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

import "./StoreReceipt.sol";
import "./StoreBack.sol";

contract StoreFront is StoreBack {

    string public storeName;

    event Cancelled();
    event Referrall(uint itemIndex, address _referral);
    event WaitlistOrder(string msg);

    constructor(string memory _storeName)  {
        storeName = _storeName;
        batchSize = 2;
        
        
    }

    // CHECKERS
    function isAccepting(uint itemIndex) public view returns (bool) {
        return isWaitlisting(itemIndex) || isInStock(itemIndex);
        
    }

    function isWaitlisting(uint itemIndex) public view returns (bool) {
        uint waitlistSize = forSale[itemIndex]._waitlistSize;
        uint stockAmount = forSale[itemIndex]._stock;
        uint stockCounter = forSale[itemIndex]._stockCounter;
        return stockCounter >= stockAmount && stockCounter < (waitlistSize + stockAmount);
    }

    function isInStock(uint itemIndex) public view returns (bool) {
        return forSale[itemIndex]._stockCounter < forSale[itemIndex]._stock;
        // return forSale[itemId]._stock >= getAcceptedOrders().length;
        
    }
    function isInRange(uint itemId) public view returns(bool) {
        return forSale[itemId]._currentId <= forSale[itemId]._maxAmount;
    }
    
    function isStoreOpen() public view returns (bool) {
        return storeOpen;
        
    }
    
    function waitlistDeposit() public view returns (uint) {
        return waitlistBalance[msg.sender];
        
    }
    

    // THIS MIGHT RUN OUT OF GAS

    function listAllOrders() public view returns (StoreDataTypes.Order[] memory) {
        uint lastIndex = forSale.length;
        uint itemCount;
        uint index = 0;
        
        
        for(uint i = 0; i < lastIndex; i++) {
            itemCount += itemIndexToId[i];
        }
        
        StoreDataTypes.Order[] memory allOrders = new StoreDataTypes.Order[](itemCount);
        
        for(uint i = 0; i < lastIndex; i++) {
            for(uint u = 1; u <= itemIndexToId[i]; u++) {
                StoreDataTypes.Order memory currentOrder = itemIndexToOrder[i][u];
                allOrders[index] = currentOrder;
                index ++;
            }
        }
        
        return allOrders;
        
        
    }
    
    function getMyOrders() public view returns (StoreDataTypes.Order[] memory) {
        uint userPurchase = 0;
        uint index = 0;
        StoreDataTypes.Order[] memory totalItems = listAllOrders();
        
        
        for(uint i = 0; i < totalItems.length; i++) {
            if(totalItems[i]._owner == msg.sender) {
                userPurchase += 1;
            }
        }
        StoreDataTypes.Order[] memory myOrders = new StoreDataTypes.Order[](userPurchase);
        for(uint i = 0; i < totalItems.length; i++) {
            if(totalItems[i]._owner == msg.sender) {
                myOrders[index] = totalItems[i];
                index ++;
                
            }
        }
        
        return myOrders;

    
    }
    
    function getAcceptedOrders() public view returns (StoreDataTypes.Order[] memory) {
        uint acceptedLength = 0;
        uint index = 0;
        StoreDataTypes.Order[] memory totalItems = listAllOrders();
        
        
        for(uint i = 0; i < totalItems.length; i++) {
            if(totalItems[i]._status == StoreDataTypes.STATUS(0)) {
                acceptedLength += 1;
            }
        }
        StoreDataTypes.Order[] memory acceptedOrders = new StoreDataTypes.Order[](acceptedLength);
        for(uint i = 0; i < totalItems.length; i++) {
            if(totalItems[i]._status == StoreDataTypes.STATUS(0)) {
                acceptedOrders[index] = totalItems[i];
                index ++;
            }
        }
        
        return acceptedOrders;
    }

    function getWaitlist(uint itemIndex) public view returns(StoreDataTypes.Order[] memory) {
        uint length = forSale[itemIndex]._stockCounter - forSale[itemIndex]._stock;
        StoreDataTypes.Order[] memory waitlist = new StoreDataTypes.Order[](length);
        for(uint i = 0; i < length; i++) {
            waitlist[i] = (itemIndexToWaitlist[itemIndex][i]);

        }
        return waitlist;
    }
           
    
    function refer(uint itemIndex, uint id, address _referral) public {
        require(addressToReferred[_referral] == false);
        require(itemIndexToOrder[itemIndex][id]._owner == msg.sender);
        require(itemIndexToOrder[itemIndex][id]._referral == address(0));
        addressToDiscountPercent[_referral] = referralDiscount;
        addressToReferred[_referral] = true;
        itemIndexToOrder[itemIndex][id]._referral = _referral;
        emit Referrall(itemIndex, _referral);

    }

    function composeOrder(StoreDataTypes.STATUS status, uint8 itemIndex, uint id, address purchaser, bytes32 dataHash) internal view returns (StoreDataTypes.Order memory ) {
        uint finalPrice = fetchFinalPrice(purchaser, itemIndex);

        StoreDataTypes.Order memory order = StoreDataTypes.Order({
            _status: status,
            _id: id,
            _price: finalPrice,
            _collection: itemIndex,
            _timestamp: block.timestamp,
            _orderData: dataHash,
            _purchaser: purchaser,
            _owner: purchaser,
            _referral: address(0)
            
            
        });
        return order;
    }
    
    
    
    function purchase(bytes32 dataHash, uint8 itemIndex) public payable  {
        require(storeOpen, "store is closed");
        require(forSale[itemIndex]._forSale, "item is not for sale");
        require(isInRange(itemIndex), "item is out of range"); //checks if current itemId is less than or equal to its max amount. 
        require(isAccepting(itemIndex), "waitlist full");

        uint finalPrice = fetchFinalPrice(msg.sender, itemIndex);
        require(msg.value == finalPrice, "send correct amount");

        StoreDataTypes.STATUS status;
        StoreDataTypes.Item storage item = forSale[itemIndex];
        address beneficiary = item._beneficiary;

        if(isInStock(itemIndex)) {
            item._currentId += 1;
            status = StoreDataTypes.STATUS.Accepted;
            addressToDiscountPercent[msg.sender] = 0;
            item._stockCounter += 1;
            
            if(beneficiary != address(this)) {
                Address.sendValue(payable(beneficiary), msg.value);
            }
            
            StoreDataTypes.Order memory order = composeOrder(status, itemIndex, item._currentId,  _msgSender(), dataHash);

            receiptContract.printReceipt(_msgSender(), item, order);
            emit AcceptOrder("acceptedddddddd");


        } else if(isWaitlisting(itemIndex)) {
            status = StoreDataTypes.STATUS.Waitlist;
            waitlistBalance[msg.sender] += msg.value;
            addressToDiscountPercent[msg.sender] = 0;
            item._stockCounter += 1;
            // for orders in the waitlist, item ID is temporarily set to zero. Id is assigned when accepted
            StoreDataTypes.Order memory order = composeOrder(status, itemIndex, 0, msg.sender, dataHash);
            itemIndexToWaitlist[itemIndex].push(order);
            emit WaitlistOrder("waitlist yooooo");
            
        }
        
    }
    
    function cancel(uint id, uint itemIndex ) public {
        
        require(itemIndexToOrder[itemIndex][id]._status == StoreDataTypes.STATUS.Waitlist &&
        itemIndexToOrder[itemIndex][id]._owner == msg.sender);
        uint _paidPrice = fetchFinalPrice(msg.sender, itemIndex);
        assert(waitlistBalance[msg.sender] >= _paidPrice);
        itemIndexToOrder[itemIndex][id]._status = StoreDataTypes.STATUS.Cancelled;
        waitlistBalance[msg.sender] -= _paidPrice;
        Address.sendValue(payable(msg.sender), _paidPrice);
        emit Cancelled();
       
        
        
        
    }
    
}
