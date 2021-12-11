// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");
const { ethers } = require("hardhat");

async function main() {
    [owner, user1, user2, user3] = await ethers.getSigners();

  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
    // await hre.run('compile');

    // We get the contract to deploy
    const StoreFront = await hre.ethers.getContractFactory("StoreFront")
    const storeFront = await StoreFront.deploy("HeresToBeingOnARoll");

    await storeFront.deployed();

    console.log("storeFront deployed to:", storeFront.address);

    console.log(owner.address)

    const itemName = "bob"
    const basePrice = ethers.utils.parseEther("2.0")
    const maxAmount = 10
    const stock = 5
    const waitlist = 5

    const text = "Hello World!"
    const bytes32 = ethers.utils.formatBytes32String(text)





    await storeFront.setStoreOpen()


    await storeFront.listItem(itemName, basePrice, maxAmount, stock, waitlist)
    let item = await storeFront.forSale(0)
    console.log("itemIndex 0 stock,", item._stock.toString())
    console.log("itemIndex 0 waitlist", item._waitlistSize.toString())
    console.log("itemIndex 0 maxAmount", item._maxAmount.toString())

    let isInStock = await storeFront.isInStock(0)
    let isWaitlisting = await storeFront.isWaitlisting(0)
    console.log("itemIndex 0 in stock:", isInStock)
    console.log("itemIndex 0 is waitlisting:", isWaitlisting)


    
    // await storeFront.connect(user1).purchase(bytes32, 0, { value: ethers.utils.parseEther("2.0") })


    for (let i = 1; i <= 5; i++) {
        await storeFront.connect(user1).purchase(bytes32, 0, { value: ethers.utils.parseEther("2.0") })
        let item = await storeFront.forSale(0)
        console.log("stock:", item._stock.toString())
        console.log("stockCounter:", item._stockCounter.toString())
        let isInStock = await storeFront.isInStock(0)
        let isWaitlisting = await storeFront.isWaitlisting(0)
        console.log("itemIndex 0 in stock:", isInStock)
        console.log("itemIndex 0 is waitlisting:", isWaitlisting)
        
        
    }
  
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
