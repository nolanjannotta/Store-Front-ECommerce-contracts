const StoreReceipt = require("./abi/StoreReceipt")
const { expect } = require("chai");
const { ethers } = require("hardhat");


// const  StoreBack = artifacts.require('StoreBack');

describe("Store Front", () => {

  let storeFront;
  let storeFrontFactory;
  let storeAddress;
  let owner;
  let user1;
  let user2;
  let user3;
  let receiptContract;
  let receiptAddress;
  let order;

  before(async () => {

    storeFrontFactory = await ethers.getContractFactory("StoreFront");
    storeFront = await storeFrontFactory.deploy("Nolans Awesome Store");
    storeAddress = storeFront.address;
    [owner, user1, user2, user3] = await ethers.getSigners();


  });

    describe("deployment", () => {

      it("deploys successfully", () => {
        expect(storeAddress).to.be.properAddress;
      });

      it("tracks store name", async () => {
        expect(await storeFront.storeName()).to.equal("Nolans Awesome Store");
      });

      it("deployer is owner", async () => {
        expect(await storeFront.owner()).to.equal(owner.address);
      });

    });
  
    describe("receipt deployment", () => {
      before(async () => {
        receiptAddress = await storeFront.receiptContract()
        receiptContract = new ethers.Contract(receiptAddress, StoreReceipt, owner)
      })
      
      it("deploys reciept contract", async () => {
        expect(receiptAddress).to.be.properAddress;


      })
      it("tracks main contract address", async () => {
        expect(await receiptContract.storeFront()).to.equal(storeFront.address)
      })
        // COME BACK TO THIS!!!
        // need to make an order and item variables to pass into printReceipt
      // it("reverts is a user tried minting a receipt", async() => {
      //   await expect(receiptContract.connect(user1).printReceipt())
      // })
    })
    
    describe("listing items for sale", async () => {
      let itemName1, itemName2, itemName3
      let maxAmount1, maxAmount2, maxAmount3
      let basePrice1, basePrice2, basePrice3
      let stock1, stock2, stock3
      let waitlistSize
      let beneficiary1, beneficiary2

      before(() => {
        itemName1 = "TV";
        itemName2 = "microwave";
        itemName3 = "watch";
        maxAmount1 = 3;
        maxAmount2 = 5;
        maxAmount3 = 10;
        basePrice1 = ethers.utils.parseEther("1.0");
        basePrice2 = ethers.utils.parseEther("2.0");
        basePrice3 = ethers.utils.parseEther("3.0");
        stock1 = 2;
        stock2 = 2;
        stock3 = 2;
        waitlistSize = 8


      })

      it("allows owner to list items for sale", async () => {
        await expect(storeFront.listItem(itemName1, basePrice1, maxAmount1, stock1, waitlistSize)).to.emit(storeFront, "ListItem");
        await expect(storeFront.listItem(itemName2, basePrice2, maxAmount2, stock2, waitlistSize)).to.emit(storeFront, "ListItem");
        await expect(storeFront.listItem(itemName3, basePrice3, maxAmount3, stock3, waitlistSize)).to.emit(storeFront, "ListItem");
      })

      it("reverts if user tries listing item", async () => {
        await expect(storeFront.connect(user1).listItem(itemName1, basePrice1, maxAmount1, stock1)).to.be.reverted
      })

      it("sets beneficiary as contract, and sets forsale as true", async() => {
        for (let i = 0; i < 3; i++) {
          let item = await storeFront.forSale(i)
          expect(item._beneficiary).to.equal(storeFront.address)
          expect(item._forSale).to.equal(true)

        }
        
      })

    });
  
    describe("setter functions -- allows owner, reverts on user", () => {
      let publicKey
      before(() => {
        publicKey = "8dbc8db70f768abc367ed1cef0e28348953a520aaa18335305717a049407314541afa24de3383d5f68924d576eebb2ffbff6f4b4c482f50359846bf783145a15"
      })
      
      it("sets discount for address", async () => {
        expect(await storeFront.setDiscount(user1.address, 50)).to.emit(storeFront, "SetDiscount");
        expect(await storeFront.addressToDiscountPercent(user1.address)).to.equal(50)
        await expect(storeFront.connect(user2.address).setDiscount(user2.address, 75)).to.be.reverted
      })
      

      // it("reverts if other user tries setting discount", async () => {
      //   await expect(storeFront.connect(user2.address).setDiscount(user2.address, 75)).to.be.reverted
      // })

      it("sets referral discount", async () => {
        expect(await storeFront.setReferralDiscount(20)).to.emit(storeFront, "SetReferralDiscount");
        expect(await storeFront.referralDiscount()).to.equal(20);
        await expect(storeFront.connect(user2.address).setReferralDiscount(50)).to.be.reverted;
      })

      it("sets stock for item", async() => {
        
        for(let i = 0; i< 3; i++) {
          await storeFront.setStock(i, 3)
          await expect(storeFront.connect(user2).setStock(i, 3)).to.be.reverted
        }
        
      })
      // COME BACK TO THIS
      // it("sets encryption public key", async () => {
      //   expect(await storeFront.setPublicKey(publicKey)).to.emit(storeFront, "SetPublicKey");
      //   await expect(storeFront.connect(user2).setPublicKey(publicKey)).to.be.reverted
      // })
      it("toggles store open", async () => {
        let storeStatus = await storeFront.storeOpen()
        console.log("store is open", storeStatus)
        await expect(storeFront.setStoreOpen()).to.emit(storeFront, "SetStoreOpen")
        storeStatus = await storeFront.storeOpen()
        console.log("store is open", storeStatus)
        await expect(storeFront.connect(user2).setStoreOpen()).to.be.reverted
      })

    })
    describe("purchasing", () => {
      let text, bytes32, finalPrice, basePrice, discount
      let item, order, inStock, waitlisting
      let waitlist, maxWaitlist, waitlistBalance
      
      before(async () => {
        text = "Hello World!"
        bytes32 = ethers.utils.formatBytes32String(text)
        receiptContract = new ethers.Contract(receiptAddress, StoreReceipt, owner)
        
        
      })
      it("calculates discounted price for user", async () => {
        finalPrice = await storeFront.fetchFinalPrice(user1.address, 2);
        basePrice = await storeFront.forSale(2);
        discount = await storeFront.addressToDiscountPercent(user1.address);
        // console.log(finalPrice)
        // console.log(basePrice._basePrice)
        // COME BACK TO THIS!!!!!!!

        // console.log(basePrice._basePrice * (discount / 100))
        // expect(finalPrice).to.equal(basePrice._basePrice * (discount / 100))

      })

      it("accepts orders that are in stock", async () => {
        for (let i = 1; i <= 3; i++) {
          finalPrice = await storeFront.fetchFinalPrice(user1.address, 2);

          // calls purchase function and checks for "AcceptOrder" event
          expect(await storeFront.connect(user1).purchase(bytes32, 2, { value: finalPrice })).to.emit(storeFront, "AcceptOrder")

          // makes sure the item tracks the current stock counter
          item = await storeFront.forSale(2)
          expect(item._stockCounter).to.equal(i) 
          // checks if id is incremented
          expect(item._currentId).to.equal(i)
          
          // makes sure a receipt is minted for each order
          expect(await receiptContract.balanceOf(user1.address)).to.equal(i)
          
        }

      })
      it("resets user discount", async () => {
        expect(await storeFront.addressToDiscountPercent(user1.address)).to.equal(0)
      })
      it("should be out of stock, should be waitlisting", async () => {
        expect(await storeFront.isInStock(2)).to.equal(false)
        expect(await storeFront.isWaitlisting(2)).to.equal(true)

      })
      it("when out of stock, orders are waitlisted", async () => {
        item = await storeFront.forSale(2)
        waitlistSize = item._waitlistSize
        console.log(waitlistSize.toString())
        for (let i = 1; i <= waitlistSize; i++) {
          // gets price for the user
          finalPrice = await storeFront.fetchFinalPrice(user2.address, 2);
          // calls purchase function checks for Waitlist event
          expect(await storeFront.connect(user2).purchase(bytes32, 2, { value: finalPrice })).to.emit(storeFront, "WaitlistOrder")
          // // check if orders are added to wailist array
          // waitlist = getWaitlist(2)
          // expect(waitlist.length).to.equal(i)
          // // checks if item id is zero
          // item = await storeFront.forSale(2)
          // expect(item._currentId).to.equal(0)
          // // checks if users in contract balance is increase by item price
          waitlistBalance = await storeFront.waitlistBalance(user2.address)
          console.log(waitlistBalance.toString())
          // expect(waitlistBalance).to.equal(finalPrice * i)

        }
        
        
      })
      it("rejects orders when waitlist is full", async () => {
        finalPrice = await storeFront.fetchFinalPrice(user2.address, 2);
        await expect(storeFront.connect(user2).purchase(bytes32, 2, { value: finalPrice })).to.be.reverted
      })
      it("returns waitlist", async () => {
        waitlist = await storeFront.getWaitlist(2)
        expect(waitlist.length).to.equal(8)
        expect(await storeFront.isWaitlisting(2)).to.equal(false)
        // console.log(waitlist);

      })

    })
    describe("accepting wailisted orders", () => {
      // TO DO!!!
    })
  
});
