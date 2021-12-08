// pragma solidity 0.8.6;


// import "./StoreReceipt.sol";
// import "./BeneficiarySplit.sol";

// contract AuxContractFactory{ 



//     function deployReceipt() private {
//         StoreReceipt receipt = new StoreReceipt(address(this));
//         receiptContract = receipt;
//     }
//     // beneficiary address defaults to address(this) 
//     function beneficiarySplitFactory(uint itemIndex, address[] memory payees, uint256[] memory shares_) public {
//         // StoreDataTypes.Item memory itemStruct = forSale[itemIndex];
        
//         BeneficiarySplit _beneficiary = new BeneficiarySplit(itemStruct, _msgSender(), payees, shares_);
//         forSale[itemIndex]._beneficiary = address(_beneficiary);
//     }
// }