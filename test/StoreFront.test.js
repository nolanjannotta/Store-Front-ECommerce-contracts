const StoreReceipt = require("../artifacts/contracts/StoreReceipt.sol/StoreReceipt.json")
const BeneficiarySplit = require("../artifacts/contracts/BeneficiarySplit.sol/BeneficiarySplit.json")

const { expect } = require("chai");
const { ethers } = require("hardhat");

// console.log(StoreReceipt.abi)


// const  StoreBack = artifacts.require('StoreBack');

describe("Store Front", () => {

  let storeFront;
  let storeFrontFactory;
  let storeAddress;
  let owner;
  let user1;
  let user2;
  let user3;
  let artist1, artist2;
  let receiptContract;
  let receiptAddress;
  let order;
  let item;

  before(async () => {

    storeFrontFactory = await ethers.getContractFactory("StoreFront");
    storeFront = await storeFrontFactory.deploy("Nolans Awesome Store");
    storeAddress = storeFront.address;
    [owner, user1, user2, user3, artist1, artist2] = await ethers.getSigners();


  });
  // beforeEach(async () => {
  //   item = await storeFront.getItem(2);

  // })

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
        // receiptAbi = StoreReceipt.abi
        receiptAddress = await storeFront.receiptContract()
        receiptContract = new ethers.Contract(receiptAddress, StoreReceipt.abi, owner)
      })
      
      it("deploys reciept contract", async () => {
        expect(receiptAddress).to.be.properAddress;


      })

      it("deploys beneficiary splitter implentation contract", async () => {
        expect(await storeFront.beneficiarySplitImplementation()).to.be.properAddress;
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
      let beneficiarySplitter, beneficiaryDetails

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

      it("sets default beneficiary as contract, and sets forsale as true", async() => {
        for (let i = 0; i < 3; i++) {
          let item = await storeFront.getItem(i)
          expect(item._beneficiary).to.equal(storeFront.address)
          expect(item._forSale).to.equal(true)

        }
        
      })
      it("deploys beneficiary split contract for item 2 by owner only", async () => {
        
        await storeFront.beneficiarySplitCloner(2, [artist1.address, artist2.address], [70, 30]);
      })
      it("beneficiary tracks owner and item", async () => {
        item = await storeFront.getItem(2);
        // console.log(item)

        beneficiarySplitter = new ethers.Contract(item._beneficiary, BeneficiarySplit.abi, owner);
        beneficiaryDetails = await beneficiarySplitter.details()
        expect(await beneficiarySplitter.owner()).to.equal(owner.address);
        expect(beneficiaryDetails._name).to.equal(item._name);
        expect(beneficiaryDetails._beneficiary).to.equal(item._beneficiary);
        // expect(item).to.equal(beneficiaryDetails)
        // console.log(beneficiaryDetails)
        // expect(beneficiaryDetails._name).to.equal(item._name);
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
      let beneficiaryBalance, artist1Balance, artist2Balance;
      
      before(async () => {
        text = "Hello World!"
        bytes32 = ethers.utils.formatBytes32String(text)
        receiptContract = new ethers.Contract(receiptAddress, StoreReceipt.abi, owner)
        
        
      })
      it("calculates discounted price for user", async () => {
        finalPrice = await storeFront.fetchFinalPrice(user1.address, 2);
        basePrice = await storeFront.getItem(2);
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
          item = await storeFront.getItem(2)
          expect(item._stockCounter).to.equal(i) 
          // checks if id is incremented
          expect(item._currentId).to.equal(i)
          
          // makes sure a receipt is minted for each order
          expect(await receiptContract.balanceOf(user1.address)).to.equal(i)
          
        }

      })

      it("computes split amount and transfers to payee", async () => {
        item = await storeFront.getItem(2);
        beneficiarySplitter = new ethers.Contract(item._beneficiary, BeneficiarySplit.abi, owner);
        beneficiaryBalance = await beneficiarySplitter.contractBalance();
        artist1Balance = await beneficiarySplitter.connect(artist1).individualBalance();
        artist2Balance = await beneficiarySplitter.connect(artist2).individualBalance();
        console.log(beneficiaryBalance.toString())
        console.log(artist1Balance.toString())
        console.log(artist2Balance.toString())
        await beneficiarySplitter.connect(artist1).withdraw()
        await beneficiarySplitter.connect(artist2).withdraw()
        artist1Balance = await beneficiarySplitter.connect(artist1).individualBalance();
        artist2Balance = await beneficiarySplitter.connect(artist2).individualBalance();
        console.log(artist1Balance.toString())
        console.log(artist2Balance.toString())

        // await expect( ()=>  beneficiarySplitter.pushPayment(artist1.address)).to.changeEtherBalance(artist1.address, artist1Balance)

        // console.log(artist1)



      })
      it("resets user discount", async () => {
        expect(await storeFront.addressToDiscountPercent(user1.address)).to.equal(0)
      })
      it("should be out of stock, should be waitlisting", async () => {
        expect(await storeFront.isInStock(2)).to.be.false
        expect(await storeFront.isWaitlisting(2)).to.be.true

      })
      it("when out of stock, orders are waitlisted", async () => {
        item = await storeFront.getItem(2)
        waitlistSize = item._waitlistSize
        console.log(waitlistSize.toString())
        for (let i = 1; i <= waitlistSize; i++) {
          // gets price for the user
          finalPrice = await storeFront.fetchFinalPrice(user2.address, 2);
          // calls purchase function checks for Waitlist event
          expect(await storeFront.connect(user2).purchase(bytes32, 2, { value: finalPrice })).to.emit(storeFront, "WaitlistOrder")
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
      let waitlistListBefore, waitlistAfter, receipt, item
      before(async () => {
      })
      it("accepts order, and remove first index of waitlist", async () => {
        
        waitlistListBefore = await storeFront.getWaitlist(2)
        for (i = 0; i <= waitlistListBefore.length - 1; i++) {
          // console.log(waitlistListBefore.length)
          waitlistBalance = await storeFront.waitlistBalance(user2.address)
          waitlistListAfter = await storeFront.getWaitlist(2)

          console.log("waitlist balance:", waitlistBalance.toString())
          console.log("waitlist length: ", waitlistListAfter.length)

          console.log("accepts order....")
          expect(await storeFront.acceptOrder(2)).to.emit(storeFront, "AcceptOrder")

          
          
        }


      })
      it("tracks total supply", async () => {
        let item = await storeFront.getItem(2)
        console.log("waitlist size ", item._waitlistSize.toString())
        console.log("stock", item._stock.toString())
        console.log("stock counter", item._stockCounter.toString())
        await storeFront.receiptContract().then(result => {
          receipt = new ethers.Contract(result, StoreReceipt.abi, owner)
          
        })
        await receipt.balanceOf(user2.address).then(result => {
          console.log("user 2 balance", result.toString())
        })
        await receipt.balanceOf(user1.address).then(result => {
          console.log("user 1 balance", result.toString())
        })
      })


    })
  it("sets 2 referrals per order", async () => {
      expect(await storeFront.connect(user1).refer(2, 1, user2.address)).to.emit(StoreFront, "Referall")
    })
    
    describe("cancelling orders", () => {
      let item
      before(async () => {
        item = await storeFront.getItem(0)
      })
      it("item index 0", async () => {
        console.log("item index 0", item._name)
        console.log("item index 0 stock ", item._stock.toString())
        console.log("item index 0 waitlistsize", item._waitlistSize.toString())
      })
      
    })
  
  
});
