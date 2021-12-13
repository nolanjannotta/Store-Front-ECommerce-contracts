// pragma solidity 0.8.6;


// import "./StoreDataTypes.sol";
// // import "./StoreReceipt.sol";
// import "./BeneficiarySplit.sol";

// // import "@openzeppelin/contracts/utils/Context.sol";

// interface StoreFront {

//     // using StoreDataTypes for StoreDataTypes.Item;

//     function getItem(uint itemIndex) external view returns(StoreDataTypes.Item memory);

// }
// contract BeneficiarySplitFactory{ 

//     using StoreDataTypes for StoreDataTypes.Item;

//     StoreFront public parentStore;

//     constructor(address _parentStore) {
//         parentStore =  StoreFront(_parentStore);

//     }
//     // beneficiary address defaults to address(this) 
//     function beneficiarySplitFactory(uint itemIndex, address owner, address[] memory payees, uint256[] memory shares_) public {
//         StoreDataTypes.Item memory itemStruct = parentStore.getItem(itemIndex);
        
//         BeneficiarySplit _beneficiary = new BeneficiarySplit(itemStruct, owner, payees, shares_);
//         parentStore.getItem(itemIndex)._beneficiary = address(_beneficiary);
//     }
// }