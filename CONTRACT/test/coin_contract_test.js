const coin = artifacts.require("coin");
const truffleAssert = require("truffle-assertions");

contract("coin", async function(accounts){   /


// bet should be 0 or 1
it("SHOULD GET ONLY 0 OR 1 AS BET", async function(){
let instance = await coin.deployed();
await truffleAssert.fails(
  instance.setBet(2, 3, {value: web3.utils.toWei("1", "ether")}), truffleAssert.ErrorType.REVERT)
});
// sending less than the amount defined in the bet revert the tx
it("SHOULD PAY THE AMOUNT TO SET THE BET", async function(){
let instance = await coin.deployed();
await truffleAssert.fails(
  instance.setBet(20, 1, {from: accounts[1], value: 10}), truffleAssert.ErrorType.REVERT);
});

it("balance", async function(){
  let instance = await coin.deployed();
  await truffleAssert.passes(
    instance.balance() > 10);
});






// CHECK ONLYOWNER
it("non owner can't set minimumBet", async function(){
  let instance = await coin.deployed();

  await truffleAssert.fails(
    instance.minimumBet(20, {from: accounts[1]}), truffleAssert.ErrorType.REVERT);
});
it("owner can set minimumBet", async function(){
  let instance = await coin.deployed();

  await truffleAssert.passes(
    instance.minimumBet(20, {from: accounts[0]}));
});

it("non owner can't withdraw from contract", async function(){
  let instance = await coin.deployed();

  await truffleAssert.fails(
    instance.withdrawFunds(10, {from: accounts[1]}), truffleAssert.ErrorType.REVERT);
});
it("owner can withdraw from contract", async function(){
  let instance = await coin.deployed();

  await truffleAssert.passes(
    instance.withdrawFunds(10, {from: accounts[0]}));
});

it("non owner can't deposit in the contract", async function(){
  let instance = await coin.deployed();

  await truffleAssert.fails(
    instance.depositFunds(10, {from: accounts[1], value: web3.utils.toWei("1", "ether")}), truffleAssert.ErrorType.REVERT);
});
it("owner can deposit in the contract", async function(){
  let instance = await coin.deployed();

  await truffleAssert.passes(
    instance.depositFunds(10, {from: accounts[0], value: web3.utils.toWei("1", "ether")}));
});




// bet over minimum bet previously set to 20 wei
it("bet amount has to be over minimum bet", async function(){
let instance = await coin.deployed();
await truffleAssert.fails(
  instance.setBet(10, 0, {value: 10), truffleAssert.ErrorType.REVERT);
});
// bet over over the half of contract balance (10000 wei) can't go through
it("bet amount has to be under maximum bet", async function(){
let instance = await coin.deployed();
await truffleAssert.fails(
  instance.setBet(6000, 0, {value: 6000}), truffleAssert.ErrorType.REVERT);
});
  



});
