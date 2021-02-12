import"./Ownable.sol";
import"./provableAPI.sol";

pragma solidity 0.5.16;

contract coin is Ownable, usingProvable{

   struct player {
     uint amount;                          // amount the player want to bet in ether
     uint bet;                             // what the player want to bet: 0 or 1
     address payable playerAddress;        // address of the player
     string message;                       // message after flip: WIN or LOSE
     uint result;                          // result of the coin flip returned from provable

     uint playerBalance;

     uint games;
     uint moneyBetted;
     uint gamesWon;
     uint moneyWon;
   }

   uint public balance;                                    // updated balance of the contract
   uint public minBet;                                     // minimum bet set by the owner
   uint public TotGames;
   uint public TotMoneyBetted;
   uint public TotGamesWon;
   uint public TotMoneyWon;
   uint public TotUniquePlayers;

   uint public hide;

   uint256 constant NUM_RANDOM_BYTES_REQUESTED = 1;
   bytes32 queryId;

   event logNewProvableQuery(string description);
   event generateRandomNumber(uint256 randomNumber);

   address[] private addresses;
   address[] private addressesFilter;



   function checkOwner() public returns(uint){
       if(msg.sender == owner){
       hide = 1;
       }
       else {
       hide = 0;
       }

       return hide;
    }

   modifier costs(uint cost){
       require(msg.value >= cost);
       _;
   }

// owner send money to the contract at the moment of deployment
   constructor() public payable{
       require(msg.value >= 10000);
       balance += msg.value;
       addresses.push(msg.sender);
       addressesFilter.push(msg.sender);
   }

   function minimumBet(uint minimum) public onlyOwner returns(uint){
      minBet = minimum;
      return minBet;
   }


   mapping (address => player) private players;  // link player to his address
   mapping (bytes32 => player) private playerId; // link player to his queryId
   mapping (address => bool) private waiting;    // link player to his waiting status: true or false



// player set his bet (0 or 1), his bet amount and send that amount to the contract
   function setBet(uint amount, uint bet) public payable costs( (players[msg.sender].amount) ){

       require(waiting[msg.sender] == false);  // player which is waiting for bet result can't bet before to know the result

       waiting[msg.sender] = true;  // once th player set the bet his waiting status is set to true

       balance += msg.value;

       player memory newPlayer;
       newPlayer.amount = amount;
       newPlayer.bet = bet;
       newPlayer.playerAddress = msg.sender;

       newPlayer.playerBalance = players[msg.sender].playerBalance;
       newPlayer.games = players[msg.sender].games;
       newPlayer.moneyBetted = players[msg.sender].moneyBetted;
       newPlayer.gamesWon = players[msg.sender].gamesWon;
       newPlayer.moneyWon = players[msg.sender].moneyWon;

       addresses.push(msg.sender);

       uint i = 0;
       uint counter = 0;

       for(i=0; i<addressesFilter.length; i++){

           if(msg.sender == addressesFilter[i]){

           counter = counter + 1;

           }
       }

       if(counter < 1){

           addressesFilter.push(msg.sender);
           }

       insertPlayer(newPlayer);   // players[msg.sender] = newPlayer

       require((players[msg.sender].amount) >= minBet, "Bet under minimum bet");
// require that the amount bet is lower than half balance
       require((players[msg.sender].amount) <= balance/2, "Bet over contract funds");


       uint256 QUERY_EXECUTION_DELAY = 0;
       uint256 GAS_FOR_CALLBACK = 200000;
       queryId = provable_newRandomDSQuery(
       QUERY_EXECUTION_DELAY,
       NUM_RANDOM_BYTES_REQUESTED,
       GAS_FOR_CALLBACK
       );

       playerId[queryId] = newPlayer;
   }


   function __callback(bytes32 _queryId, string memory _result, bytes memory proof) public {
       require(msg.sender == provable_cbAddress()); //l'address deve essere quello dell'oracle

       uint256 randomNumber = uint256(keccak256(abi.encodePacked(_result))) % 2;

       emit generateRandomNumber(randomNumber);

       if(randomNumber == (playerId[_queryId].bet)){

       balance = balance - (playerId[_queryId].amount)*2;

       players[playerId[_queryId].playerAddress].playerBalance = players[playerId[_queryId].playerAddress].playerBalance + ( (playerId[_queryId].amount)*2 );

       players[playerId[_queryId].playerAddress].message = "WIN";
       players[playerId[_queryId].playerAddress].result = randomNumber;

       players[playerId[_queryId].playerAddress].gamesWon = players[playerId[_queryId].playerAddress].gamesWon + 1;
       players[playerId[_queryId].playerAddress].moneyWon = players[playerId[_queryId].playerAddress].moneyWon + (playerId[_queryId].amount);

      TotGamesWon = 1 + TotGamesWon;
      TotMoneyWon = (playerId[_queryId].amount) + TotMoneyWon;

       }
           else{

           players[playerId[_queryId].playerAddress].message = "LOSE";
           players[playerId[_queryId].playerAddress].result = randomNumber;
           }


       players[playerId[_queryId].playerAddress].games = players[playerId[_queryId].playerAddress].games + 1;
       players[playerId[_queryId].playerAddress].moneyBetted = players[playerId[_queryId].playerAddress].moneyBetted + (playerId[_queryId].amount);
       //maxBet = balance/2;


       TotGames = addresses.length -1;
       TotMoneyBetted = playerId[_queryId].amount + TotMoneyBetted;
       TotUniquePlayers = addressesFilter.length -1;

   waiting[playerId[_queryId].playerAddress] = false;
   }





function getResult() public view returns(uint amount, uint bet, string memory message, uint result, uint playerBalance, uint games, uint moneyBetted, uint gamesWon, uint moneyWon){
        address creator = msg.sender;

        return (players[creator].amount, players[creator].bet, players[creator].message, players[creator].result, players[creator].playerBalance, players[creator].games, players[creator].moneyBetted, players[creator].gamesWon, players[creator].moneyWon );
    }

   function depositFunds(uint deposit) public payable onlyOwner costs( deposit ){

   balance = balance + deposit;

}




// only owner can withdraw money
   function withdrawFunds(uint withdraw) public onlyOwner {

      balance = balance - withdraw;
      msg.sender.transfer(withdraw);
  }


  function withdrawFundsPlayer(uint withdraw) public {
      require(withdraw<players[msg.sender].playerBalance);

      players[msg.sender].playerBalance = players[msg.sender].playerBalance - (withdraw);
      msg.sender.transfer(withdraw);

  }


 function insertPlayer(player memory newPlayer) private {
       address creator = msg.sender;
       players[creator] = newPlayer;
       }


       function getStatistics(address infoaddress) public view onlyOwner returns(uint games, uint moneyBetted, uint gamesWon, uint moneyWon, uint playerBalance){


        return (players[infoaddress].games, players[infoaddress].moneyBetted, players[infoaddress].gamesWon, players[infoaddress].moneyWon, players[infoaddress].playerBalance );
    }

    function getAddress(uint number) public view onlyOwner returns(address infoaddress){

        infoaddress = addressesFilter[number];

        return (infoaddress);
    }


}
