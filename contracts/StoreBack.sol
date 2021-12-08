// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
// import "@openzeppelin/contracts/utils/math/SafeMath.sol";
// import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
// import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "./StoreReceipt.sol";
import "./BeneficiarySplit.sol";
import "./StoreDataTypes.sol";


contract StoreBack is Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint;

    using StoreDataTypes for StoreDataTypes.Order;
    using StoreDataTypes for StoreDataTypes.Item;
    using StoreDataTypes for StoreDataTypes.STATUS;

    StoreReceipt public receiptContract;
    

    Counters.Counter internal counter;

    bool public storeOpen;

    uint public referralDiscount;
    uint public maxWaitlist;
    uint public batchSize;
    
    mapping(address => uint) public addressToDiscountPercent;
    mapping(uint => uint) public itemToWaitlist;
    mapping(address => bool) public addressToReferred;
    mapping(uint => uint) public itemIndexToId; //id is the item id
    mapping(uint => mapping(uint => StoreDataTypes.Order)) public itemIndexToOrder;
    mapping(address => uint) public waitlistBalance;

    struct OrderWaitlist {
        uint waitlistSize;
        StoreDataTypes.Order[] waitlistOrders;

    }

    mapping(uint => OrderWaitlist) public itemIndexToWaitlist; //tracks list of waitlisted items
    



    bytes public orderDataPublicKey;
    

   
    
    
    
    
    // list of items for sale by store
    StoreDataTypes.Item[] public forSale;
    
    event SetDiscount(address account, uint discount);
    event SetPublicKey(bytes publicKey);
    event SetStoreOpen(bool open);
    event SetItemForSale(bool forSale);
    event MaxWaitlist(uint itemId, uint max);
    event SetReferralDiscount(uint discount);
    event ListItem(uint itemIndex, StoreDataTypes.Item item);
    event AcceptOrder(string msg);


    


    constructor() {
        deployReceipt();
   
    }
        
    // SETTERS

    function setDiscount(address _receiver, uint _percent) public onlyOwner {
        addressToDiscountPercent[_receiver] = _percent;
        emit SetDiscount(_receiver, _percent);
    }

    function setStock(uint _itemId, uint _stock) public onlyOwner {
        forSale[_itemId]._stock = _stock;
    }
    
    function setPublicKey(bytes memory _publicKey) public onlyOwner {
        orderDataPublicKey = _publicKey;
        emit SetPublicKey(_publicKey);
    }
    
    function setStoreOpen() public onlyOwner returns(bool) {
        storeOpen = !storeOpen;
        emit SetStoreOpen(storeOpen);
        
    }

    // call this to register an existing beneficiary to a new item
    function setExistingBeneficiary(uint itemIndex, address beneficiary) public onlyOwner {
        forSale[itemIndex]._beneficiary = beneficiary;
    }

    function setItemForSale(bool _forSale, uint itemIndex) public onlyOwner returns(bool) {
        forSale[itemIndex]._forSale = _forSale;
        emit SetItemForSale(_forSale);
        return forSale[itemIndex]._forSale;    
    }
    
    
    function setMaxWaitlist(uint itemId, uint _maxWaitlist) public onlyOwner { 
        itemToWaitlist[itemId] = _maxWaitlist;
        emit MaxWaitlist(itemId, _maxWaitlist);
    }
    
    function updateStock(uint itemIndex, uint _stock) public onlyOwner {
        forSale[itemIndex]._stock = _stock;
    }
    
    function setReferralDiscount(uint _referralDiscount) public onlyOwner {
        referralDiscount = _referralDiscount;
        emit SetReferralDiscount(_referralDiscount);
    }


    // naive factories, try cloning


    // this function is called in the constructor to ensure a receipt is deployed for a store
    function deployReceipt() private {
        StoreReceipt receipt = new StoreReceipt(address(this));
        receiptContract = receipt;
    }
    // beneficiary address defaults to address(this) 
    function beneficiarySplitFactory(uint itemIndex, address[] memory payees, uint256[] memory shares_) internal {
        StoreDataTypes.Item memory itemStruct = forSale[itemIndex];
        
        BeneficiarySplit _beneficiary = new BeneficiarySplit(itemStruct, _msgSender(), payees, shares_);
        forSale[itemIndex]._beneficiary = address(_beneficiary);
    }

    


    function listItem(string memory _name, uint _basePriceinEth, uint _maxAmount, uint _stock) public onlyOwner  {
        
        StoreDataTypes.Item memory item = StoreDataTypes.Item({
            _name: _name,
            _beneficiary: payable(address(this)), // default beneficiary set as this contract, to be later withdrawn by owner.
            _basePrice: _basePriceinEth,
            _forSale: true,
            _maxAmount: _maxAmount,
            _stock: _stock
            
        });
        
        forSale.push(item);

        uint index = forSale.length;
        emit ListItem(index, item);
        
        
        
    }

    // function acceptOrder(uint waitlistIndex) public onlyOwner {
    //     StoreDataTypes.Order memory order = waitlist[waitlistIndex];
    //     require(order._status == StoreDataTypes.STATUS.Waitlist);

    //     uint collection = order._collection;
    //     address purchaser = order._purchaser;
    //     address beneficiary = forSale[collection]._beneficiary;
    //     uint itemId = itemIndexToId[collection] += 1;
    //     order._id = itemId;

    //     // address beneficiary = order._beneficiary;
    //     uint finalPrice = fetchFinalPrice(purchaser, collection);
    //     Address.sendValue(payable(beneficiary), finalPrice);

    // }
    
    function acceptOrder(uint waitlistIndex, uint itemIndex) public onlyOwner {
        StoreDataTypes.Order memory order = itemIndexToWaitlist[itemIndex].waitlistOrders[waitlistIndex];
        require(order._status == StoreDataTypes.STATUS.Waitlist);
        
        order._status = StoreDataTypes.STATUS.Accepted;

        address purchaser = order._purchaser;
        StoreDataTypes.Item memory item = forSale[itemIndex];
        uint finalPrice = fetchFinalPrice(purchaser, itemIndex);
        addressToDiscountPercent[purchaser] = 0;
        waitlistBalance[purchaser] -= finalPrice;
        receiptContract.printReceipt(_msgSender(), item, order);

        
        payable(owner()).transfer(finalPrice);
        // addressToDiscountPercent[_receiver] = 0;
        // mintReceipt(purchaser);
        emit AcceptOrder("acceptedddddddd");
        
    }

    function withdraw() public onlyOwner {
        Address.sendValue(payable(_msgSender()), address(this).balance);
    }

    // function mintReceipt(address purchaser) internal {
    //      safeMint(purchaser);
        
    // }

    function fetchFinalPrice(address _account, uint _itemIndex) public view returns(uint){
        uint basePrice = forSale[_itemIndex]._basePrice;
        uint percent = addressToDiscountPercent[_account];
        return basePrice - (basePrice.mul(percent).div(100));

        // return basePrice - basePrice.mul(addressToDiscountPercent[_account].div(100));

        
        
    }

    // function deleteIndex(uint index, StoreDataTypes.Order[] memory orders) internal {

    // for(uint i = index; i < orders.length - 1; i++) {
    //     orders[i] = orders[i + 1];
    // }
    // orders.pop();
    // }





}