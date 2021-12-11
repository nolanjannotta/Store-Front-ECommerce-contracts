// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "./StoreDataTypes.sol";

contract StoreReceipt is ERC721, ERC721Enumerable, ERC721URIStorage {
    using Counters for Counters.Counter;

    using StoreDataTypes for StoreDataTypes.Order;
    using StoreDataTypes for StoreDataTypes.Item;

    mapping(uint => StoreDataTypes.Item) public idToItem;
    mapping(uint => StoreDataTypes.Order) public idToOrder;

    

    modifier onlyStoreFront{
        require(_msgSender() == storeFront, "You can't call this.");
        _;
    }


    address public storeFront;

    Counters.Counter private _orderNumberCounter;



    constructor(address _storeFront) ERC721("Here'sToBeingOnARoll", "OnARollReciept") {
        storeFront = _storeFront;
    }

    // required functions:
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function printReceipt(
        address to, 
        StoreDataTypes.Item memory item, 
        StoreDataTypes.Order memory order) 
        public onlyStoreFront returns (uint)  {
        _orderNumberCounter.increment();
        _safeMint(to, _orderNumberCounter.current());
        idToItem[_orderNumberCounter.current()] = item;
        idToOrder[_orderNumberCounter.current()] = order;
        return _orderNumberCounter.current();
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }


    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
}


