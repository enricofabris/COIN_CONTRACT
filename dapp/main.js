var web3 = new Web3(Web3.givenProvider);
var contractInstance;

$(document).ready(function() {
    window.ethereum.enable().then(function(accounts){ // collega con metamask e i suoi account
      contractInstance = new web3.eth.Contract(abi, "0x37A166DcD6C2169cbE54466265c897043A1A5A2B", {from: accounts[0]});
      console.log(contractInstance);

      getPlayerBalance()
      getBalance()
      getTotGames()
      getTotMoneyBetted()
      getGamesWon()
      getMoneyWon()
      getMinimumBet()
      getUniquePlayers()
      getUniquePlayers1()
      startCheckOwner()
    });

    $("#bet0").click(function(){bet = 0;})
    $("#bet1").click(function(){bet = 1;})

    $("#confirm").click(inputData)
    $("#get_data_button").click(fetchAndDisplay)

    $("#withdraw").click(startWithdraw)
    $("#withdrawPlayer").click(startWithdrawPlayer)
    $("#deposit").click(startDepositFunds)

    $("#set_minimumBet").click(setMinimumBet)

    $("#getAddress").click(startGetAddress)

    $("#get_data_button").click(showPlayer)



});

function startCheckOwner(){

contractInstance.methods.checkOwner().call().then(function(res){

if(res == 1){
document.getElementById("hide").style.display="block";

}
})

}

function showPlayer() {
document.getElementById("hidePlayer").style.display="block";
}


function getUniquePlayers(){
contractInstance.methods.TotUniquePlayers().call().then(function(res){
$("#TotUniquePlayers").text(res);
})};

function getUniquePlayers1(){
contractInstance.methods.TotUniquePlayers1().call().then(function(res){
$("#TotUniquePlayers1").text(res);
})};

function getTotGames(){
contractInstance.methods.TotGames().call().then(function(res){
$("#TotGames").text(res);
})};
function getTotMoneyBetted(){
contractInstance.methods.TotMoneyBetted().call().then(function(res){
$("#TotmoneyBetted").text(res);
})};
function getGamesWon(){
contractInstance.methods.TotGamesWon().call().then(function(res){
$("#TotGamesWon").text(res);
})};
function getMoneyWon(){
contractInstance.methods.TotMoneyWon().call().then(function(res){
$("#TotMoneyWon").text(res);
})}




function getBalance(){
contractInstance.methods.balance().call().then(function(res){

$("#balance_output").text(res);
$("#max_bet").text(res/2.5);
})};


function getMinimumBet(){
contractInstance.methods.minBet().call().then(function(res){

$("#min_bet").text(res);

})};

function getPlayerBalance(){
  contractInstance.methods.getResult().call().then(function(res){

  $("#playerBalance_output").text(res.playerBalance);

})}




function startDepositFunds(){

var deposit = $("#depositAmount").val();
contractInstance.methods.depositFunds(deposit).send({value: web3.utils.toWei(deposit, "wei")})
.on("transactionHash", function(hash){
  console.log(hash);
})
.on("confirmation", function(confirmationNr){
  console.log(confirmationNr);
})
.on("receipt", function(receipt){
  getBalance();
  console.log(receipt);
})


}


function startWithdraw(){

var withdraw = $("#withdrawAmount").val();

contractInstance.methods.withdrawFunds(withdraw).send()
.on("transactionHash", function(hash){
console.log(hash);
})
.on("confirmation", function(confirmationNr){
})
.on("receipt", function(receipt){
console.log(receipt);
getBalance();
alert("done");

})

};

function startWithdrawPlayer(){

var withdraw = $("#withdrawPlayerAmount").val();

contractInstance.methods.withdrawFundsPlayer(withdraw).send()
.on("transactionHash", function(hash){
console.log(hash);
})
.on("confirmation", function(confirmationNr){
console.log(confirmationNr);
})
.on("receipt", function(receipt){
console.log(receipt);
getPlayerBalance();
alert("done");


})
};


function setMinimumBet(){

var config = {value: web3.utils.toWei("1", "wei")}

var amount = $("#minBetAmount").val();

contractInstance.methods.minimumBet(amount).send()
.on("transactionHash", function(hash){
console.log(hash);
})
.on("confirmation", function(confirmationNr){
})
.on("receipt", function(receipt){
console.log(receipt);
getMinimumBet();
alert("done");
})

getMinimumBet()

}

function startGetAddress(){

  contractInstance.methods.TotUniquePlayers().call().then(function(res){
  $("#unique").text(res)})

var config = {value: web3.utils.toWei("1", "wei")}

var array = $("#address").val();


contractInstance.methods.getAddress(array).call().then(function(res){

$("#addressResult").text(res);



contractInstance.methods.getStatistics(res).call().then(function(res){


$("#playerGames").text(res.games);
$("#playerMoneyBetted").text(res.moneyBetted);
$("#playerGamesWon").text(res.gamesWon);
$("#PlayerMoneyWon").text(res.moneyWon);

})



})
}


function inputData(){


//var config = {
// value: web3.utils.toWei("1", "ether")}

var amount = $("#amount").val();

contractInstance.methods.setBet(amount, bet).send({value: amount})
.on("transactionHash", function(hash){
console.log(hash);
})
.on("confirmation", function(confirmationNr){
console.log(confirmationNr);
})
.on("receipt", function(receipt){
console.log(receipt);
getBalance();
getPlayerBalance();
getTotGames();
getTotMoneyBetted();
getGamesWon();
getMoneyWon();
})
}




  function fetchAndDisplay(){
  contractInstance.methods.getResult().call().then(function(res){


$("#amount_output").text(res.amount);
$("#bet_output").text(res.bet);
$("#message_output").text(res.message);
$("#result_output").text(res.result);


$("#yourGames").text(res.games);
$("#yourMoneyBetted").text(res.moneyBetted);
$("#yourGamesWon").text(res.gamesWon);
$("#YourMoneyWon").text(res.moneyWon);
})
  }
