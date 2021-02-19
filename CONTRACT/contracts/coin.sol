import"./Ownable.sol";
import"./provableAPI.sol";

pragma solidity 0.5.16;

contract coin is Ownable, usingProvable{

   struct player {
     uint amount;                          // amount the player want to bet in WEI
     uint bet;                             // what the player want to bet: 0 HEAD or 1 TAIL
     address payable playerAddress;        // address of the player
     string message;                       // message after flip: WIN or LOSE
     uint result;                          // result of the coin flip returned from provable

     uint playerBalance;                   // each win increase the player balance in the contract.
                                           // The player has to withdraw from his balance to his address

       uint games;                          // total games of the single player
     uint moneyBetted;                      // total money betted by the single player
     uint gamesWon;                         // total games won by the single player
     uint moneyWon;                         // total money won by the single player
   }

   uint public balance;                                    // updated balance of the contract
   uint public minBet;                                     // minimum bet set by the owner
   uint public TotGames;                                   // total games made in the contract
   uint public TotMoneyBetted;                             // total money betted in the contract
   uint public TotGamesWon;                                // total games won in the contract
   uint public TotMoneyWon;                                // total money won in the contract
   uint public TotUniquePlayers;                           // total unique players who played in the contract

   uint public hide;                                       // status of the playing address (Owner or not)

   uint256 constant NUM_RANDOM_BYTES_REQUESTED = 1;        // provable
   bytes32 queryId;

   event logNewProvableQuery(string description);
   event generateRandomNumber(uint256 randomNumber);

   address[] private addresses;                            // array of all players
   address[] private addressesFilter;                      // array filters only unique players



   function checkOwner() public returns(uint){             // function set HIDE variable to 1 if address playing is owner otherwise to 0.
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


   constructor() public payable{                        // owner send 10000 WEI to the contract at the moment of deployment
       require(msg.value >= 10000);
       balance += msg.value;
       addresses.push(msg.sender);
       addressesFilter.push(msg.sender);
   }

   function minimumBet(uint minimum) public onlyOwner returns(uint){  // owner can set minimum bet
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

       for(i=0; i<addressesFilter.length; i++){        // filter only unique players

           if(msg.sender == addressesFilter[i]){

           counter = counter + 1;

           }
       }

       if(counter < 1){

           addressesFilter.push(msg.sender);
           }

       insertPlayer(newPlayer);   // players[msg.sender] = newPlayer

       // require that the amount bet is over the minimum bet set by the owner

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

       if(randomNumber == (playerId[_queryId].bet)){      // if random number is equal to the bet of the player he wins otherwise he lose

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



// return the statistic of one player

function getResult() public view returns(uint amount, uint bet, string memory message, uint result, uint playerBalance, uint games, uint moneyBetted, uint gamesWon, uint moneyWon){
        address creator = msg.sender;

        return (players[creator].amount, players[creator].bet, players[creator].message, players[creator].result, players[creator].playerBalance, players[creator].games, players[creator].moneyBetted, players[creator].gamesWon, players[creator].moneyWon );
    }


// owner can deposit funds into the contract

   function depositFunds(uint deposit) public payable onlyOwner costs( deposit ){

   balance = balance + deposit;

}



// only owner can withdraw money from the contract

   function withdrawFunds(uint withdraw) public onlyOwner {

      balance = balance - withdraw;
      msg.sender.transfer(withdraw);
  }


// player can withdraw funds from his balance in the contract

  function withdrawFundsPlayer(uint withdraw) public {
      require(withdraw<players[msg.sender].playerBalance);

      players[msg.sender].playerBalance = players[msg.sender].playerBalance - (withdraw);
      msg.sender.transfer(withdraw);

  }





 function insertPlayer(player memory newPlayer) private {
       address creator = msg.sender;
       players[creator] = newPlayer;
       }




// given the address of a player the owner can check his playing statistics

  function getStatistics(address infoaddress) public view onlyOwner returns(uint games, uint moneyBetted, uint gamesWon, uint moneyWon, uint playerBalance){


        return (players[infoaddress].games, players[infoaddress].moneyBetted, players[infoaddress].gamesWon, players[infoaddress].moneyWon, players[infoaddress].playerBalance );
    }



// owner can get the address of the player by giving his position into the array collecting all the unique players

function getAddress(uint number) public view onlyOwner returns(address infoaddress){

        infoaddress = addressesFilter[number];

        return (infoaddress);
    }


}
