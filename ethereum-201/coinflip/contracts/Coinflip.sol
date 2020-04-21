import "./Ownable.sol";
import "./provableAPI.sol";

pragma solidity 0.5.8;

contract Coinflip is Ownable, usingProvable{

  struct Results {
    string coinside;
    string betresult;
  }

  mapping (address => Results) private res;

  uint public balance;
  uint public balance_available;

  uint256 constant MAX_INT_FROM_BYTE = 256;
  uint256 constant NUM_RANDOM_BYTES_REQUESTED = 1;

  struct Bet{
    address player;
    uint256 value;
    string sidepick;
    }

  mapping (bytes32 => Bet) private waiting;
  mapping (address => uint) private pot;
  mapping (address => bool) private isWaiting;

  event FlipResult(address player, string  coinside, string  betresult);

  modifier bettingcap(){
      require(msg.value <= balance_available);
      _;
  }


  function flip(string memory sidepick) public payable bettingcap {
    require(keccak256(abi.encodePacked(sidepick)) == keccak256(abi.encodePacked("Tails")) ||
    keccak256(abi.encodePacked(sidepick)) == keccak256(abi.encodePacked("Heads")) );
    require(!isWaiting[msg.sender]);
    isWaiting[msg.sender] = true;

    uint256 QUERY_EXECUTION_DELAY = 0;
    uint256 GAS_FOR_CALLBACK = 200000;

    bytes32 queryId = provable_newRandomDSQuery(
        QUERY_EXECUTION_DELAY,
        NUM_RANDOM_BYTES_REQUESTED,
        GAS_FOR_CALLBACK
    );

    waiting[queryId].player = msg.sender;
    waiting[queryId].value = msg.value;
    waiting[queryId].sidepick = sidepick;


  }


  function __callback(bytes32 _queryId,string memory _result,bytes memory _proof) public {
      require(msg.sender == provable_cbAddress());

      uint256 randomNumber = uint256(keccak256(abi.encodePacked(_result))) % 2;
      string memory coinResult;
      if(randomNumber == 0){
        coinResult = "Tails";
      } else{
        coinResult = "Heads";
      }

      balance += waiting[_queryId].value;
      res[waiting[_queryId].player].coinside = coinResult;

      if (keccak256(abi.encodePacked(waiting[_queryId].sidepick)) == keccak256(abi.encodePacked(coinResult))){
        balance_available -=  waiting[_queryId].value;
        pot[waiting[_queryId].player] += 2 * waiting[_queryId].value;
        res[waiting[_queryId].player].betresult = "win";
        emit FlipResult(waiting[_queryId].player, coinResult, "win");
      } else {
        balance_available +=  waiting[_queryId].value;
        res[waiting[_queryId].player].betresult = "lose";
        emit FlipResult(waiting[_queryId].player, coinResult, "lose");
      }
      isWaiting[waiting[_queryId].player] = false;

  }




  function getResult() public view returns(string memory, string memory){
      address player = msg.sender;
      return (res[player].coinside, res[player].betresult);
  }

  function fund() public payable onlyOwner {
      balance += msg.value;
      balance_available += msg.value;
  }

  function withdrawAll() public onlyOwner returns(uint) {
      uint toTransfer = balance;
      balance = 0;
      msg.sender.transfer(toTransfer);
      return toTransfer;
  }

  function getPotBalance() public view returns(uint)  {
      return pot[msg.sender];
  }

  function withdrawFromPot(uint amount) public   {
      require(amount <= pot[msg.sender]);
      balance -= amount;
      pot[msg.sender] -= amount;
      msg.sender.transfer(amount);
  }




constructor()
    public
{
    firstQuery();
}

function firstQuery()
    payable
    public
{

    uint256 QUERY_EXECUTION_DELAY = 0;
    uint256 GAS_FOR_CALLBACK = 200000;

    bytes32 queryId = provable_newRandomDSQuery(
        QUERY_EXECUTION_DELAY,
        NUM_RANDOM_BYTES_REQUESTED,
        GAS_FOR_CALLBACK
    );

    isWaiting[msg.sender] = true;
    waiting[queryId].player = msg.sender;
    waiting[queryId].value = 0;
    waiting[queryId].sidepick = "Heads";

}



}
