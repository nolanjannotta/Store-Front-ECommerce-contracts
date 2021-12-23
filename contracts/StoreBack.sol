// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
// import "@openzeppelin/contracts/utils/math/SafeMath.sol";
// import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
// import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "./StoreReceipt.sol";
import "./BeneficiarySplit.sol";

import "./StoreDataTypes.sol";


contract StoreBack is Ownable {
    using SafeMath for uint;

    using StoreDataTypes for StoreDataTypes.Order;
    using StoreDataTypes for StoreDataTypes.Item;
    using StoreDataTypes for StoreDataTypes.STATUS;

    StoreReceipt public receiptContract;
    


    string public storeName;

    
    bool public storeOpen;

    uint public referralDiscount;
    
    mapping(address => uint) public addressToDiscountPercent;
    mapping(address => bool) public addressToReferred;
    mapping(uint => uint) public itemIndexToId; //id is the item id
    mapping(uint => mapping(uint => StoreDataTypes.Order)) public itemIndexToOrder;
    mapping(address => uint) public waitlistBalance;
    mapping(uint => StoreDataTypes.Order[]) public itemIndexToWaitlist; //tracks list of waitlisted items
    
     address public immutable beneficiarySplitImplementation;
    // address public immutable storeReceiptImplementation;




    bytes public orderDataPublicKey; // public key that order info is encrypted against off chain
    

   
    
    
    
    
    // list of items for sale by store
    StoreDataTypes.Item[] internal forSale;
    
    event SetDiscount(address account, uint discount);
    event SetPublicKey(bytes publicKey);
    event SetStoreOpen(bool open);
    event SetItemForSale(bool forSale);
    event MaxWaitlist(uint itemId, uint max);
    event SetReferralDiscount(uint discount);
    event ListItem(uint itemIndex, StoreDataTypes.Item item);
    event AcceptOrder(string msg);
    event Cancelled();
    event Referall(uint itemIndex, address[] _referrals);
    event WaitlistOrder(string msg);



    


    constructor(string memory _storeName) {
        deployReceipt();
        beneficiarySplitImplementation = address(new BeneficiarySplit());
        storeName = _storeName;

   
    }
        
    // SETTERS

    function setDiscount(address _receiver, uint _percent) public onlyOwner {
        addressToDiscountPercent[_receiver] = _percent;
        emit SetDiscount(_receiver, _percent);
    }

    function setStock(uint _itemId, uint _stock) public onlyOwner {
        forSale[_itemId]._stock = _stock;
    }

    function resetCurrentCounter(uint _itemId) public onlyOwner {
        forSale[_itemId]._stockCounter = 0;
    }
    
    function setPublicKey(bytes memory _publicKey) public onlyOwner {
        orderDataPublicKey = _publicKey;
        emit SetPublicKey(_publicKey);
    }
    
    function setStoreOpen() public onlyOwner {
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


    function setWaitlistSize(uint itemId, uint _waitlistSize) public onlyOwner { 
        forSale[itemId]._waitlistSize = _waitlistSize;
        emit MaxWaitlist(itemId, _waitlistSize);
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
    function beneficiarySplitCloner(uint itemIndex, address[] memory payees, uint256[] memory shares_) public onlyOwner {
        StoreDataTypes.Item storage itemStruct = forSale[itemIndex];
        address beneficiarySplitClone = Clones.clone(beneficiarySplitImplementation);
        BeneficiarySplit(payable(beneficiarySplitClone)).initialize(itemStruct, msg.sender, payees, shares_);
        itemStruct._beneficiary = beneficiarySplitClone;
    }

    


    function listItem(string memory _name, 
                        uint _basePriceinEth, 
                        uint _totalSupply, 
                        uint _stock, 
                        uint _waitlistSize) public onlyOwner  {
        
        StoreDataTypes.Item memory item = StoreDataTypes.Item({
            
            _currentId: 0,
            _basePrice: _basePriceinEth,
            _totalSupply: _totalSupply,
            _stock: _stock,
            _stockCounter: 0,
            _waitlistSize: _waitlistSize,
            _name: _name,
            _beneficiary: payable(address(this)), // default beneficiary set as this contract, to be later withdrawn by owner.
           _forSale: true
            
            
            
            
        });
        
        forSale.push(item);

        uint index = forSale.length;
        emit ListItem(index, item);
        
        
        
    }

    function deleteWaitlistZeroIndex(uint itemIndex) private onlyOwner {

        StoreDataTypes.Order[] storage newWaitlist = itemIndexToWaitlist[itemIndex];

        for(uint i = 0; i < newWaitlist.length - 1; i++) {
            newWaitlist[i] = newWaitlist[i + 1];
        }

        newWaitlist.pop();
        
        

    }
    
    function acceptOrder(uint itemIndex) public onlyOwner {
        StoreDataTypes.Order memory order = itemIndexToWaitlist[itemIndex][0];
        StoreDataTypes.Item storage item = forSale[itemIndex];

        require(order._status == StoreDataTypes.STATUS.Waitlist);
        
        order._status = StoreDataTypes.STATUS.Accepted;
        item._currentId +=1;

        address purchaser = order._purchaser;
        uint finalPrice = fetchFinalPrice(purchaser, itemIndex);
        address beneficiary = item._beneficiary;

        addressToDiscountPercent[purchaser] = 0;
        waitlistBalance[purchaser] -= finalPrice;
        receiptContract.printReceipt(purchaser, order);

        if(beneficiary != address(this)) {
            Address.sendValue(payable(beneficiary), finalPrice);
        }

        deleteWaitlistZeroIndex(itemIndex);

        emit AcceptOrder("acceptedddddddd");
        
    }

    function withdraw() public onlyOwner {
        Address.sendValue(payable(_msgSender()), address(this).balance);
    }

    function fetchFinalPrice(address _account, uint _itemIndex) public view returns(uint){
        uint basePrice = forSale[_itemIndex]._basePrice;
        uint percent = addressToDiscountPercent[_account];
        return basePrice - (basePrice.mul(percent).div(100));

        // return basePrice - basePrice.mul(addressToDiscountPercent[_account].div(100));

        
        
    }
    function getWaitlist(uint itemIndex) public view returns(StoreDataTypes.Order[] memory) {
        return itemIndexToWaitlist[itemIndex];
    }




}