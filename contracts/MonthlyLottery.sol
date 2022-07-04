// SPDX-License-Identifier: GNU-GPLv3
pragma solidity ^0.8.0;
// pragma experimental ABIEncoderV2;

/* ToDo : Use Ownable OpenZeppelin */
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";


// import "./LotteryGenerator.sol";

// import "./VRFv2SubscriptionManager.sol";
// import "./VRFv2Consumer.sol";

import "./LotteryCore.sol";

// import "truffle/Console.sol";
// import "hardhat/console.sol";

import "./LotteryInterface.sol";


/**
  * @title Monthly Lottery For BSC Lottery Game 
  * @author Batis Abhari (https://github.com/baties - ContactMe: abhari_Batis@hotmail.com)
  * @notice This SmartContract is responsible for implimentation of Monthly Pot Lottery 
  * @dev MonthlyLottery will be Generated by LotteryGenerator in Next Version
*/
contract MonthlyLottery is Ownable, VRFConsumerBaseV2 {

  VRFCoordinatorV2Interface COORDINATOR;
  LinkTokenInterface LINKTOKEN;
  uint64 s_subscriptionId;

  // Rinkeby coordinator. For other networks,
  // see https://docs.chain.link/docs/vrf-contracts/#configurations
  address vrfCoordinator = 0x6168499c0cFfCaCD319c818142124B7A15E857ab;  // Rinkeby
  // address vrfCoordinator = 0x6A2AAd07396B36Fe02a22b33cf443582f682c82f;  // BSC TestNet coordinator

  // Rinkeby LINK token contract. For other networks,
  // see https://docs.chain.link/docs/vrf-contracts/#configurations
  address link = 0x01BE23585060835E02B77ef475b0Cc51aA1e0709;  // Rinkeby
  // address link = 0x84b9B910527Ad5C03A9Ca831909E21e236EA7b06;  //  BSC TestNet LINK token

  // The gas lane to use, which specifies the maximum gas price to bump to.
  // For a list of available gas lanes on each network,
  // see https://docs.chain.link/docs/vrf-contracts/#configurations
  bytes32 keyHash = 0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;  // Rinkeby
  // bytes32 keyHash = 0xd4bb89654db74673a187bd804519e65e3f71a52bc55f11da7601a13dcf505314;  //  BSC TestNet keyhash

  uint32 callbackGasLimit = 100000;
  uint16 requestConfirmations = 3;
  uint32 numWords =  1;

  uint256[] public s_randomWords;
  uint256 public s_requestId;


  // address private _VRF;
  address private generatorLotteryAddr;
  // address private LiquidityPoolAddress;
  // address private MultiSigWalletAddress;
  address private LotteryOwner;

  address[] private _WeeklyWinnersArray;
  bool private lPotActive;  
  uint private vrfCalledTime = 0;
  bool private lReadySelectWinner; 
  address private potDirector;  
  address private potWinnerAddress;
  uint public potWinnerPrize = 0;
  bool private lWinnerSelected;

  event SelectWinnerIndex(uint winnerIndex, uint potBalance, uint winnerPrize);
  event SelectWinnerAddress(address potWinner, uint winnerPrize);
  event TotalPayment(address receiver, uint TrxValue);
  event ReadyForSelectWinner(bool isReadySelectWinner);
  event StartSelectngWinner(uint vrfCalledTime);
  event LogDepositReceived(address sender, uint value);

  // constructor(address VRF, address generatorLotteryAddress) {  
  constructor(uint64 subscriptionId, address generatorLotteryAddress) VRFConsumerBaseV2(vrfCoordinator) {
    COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    LINKTOKEN = LinkTokenInterface(link);
    s_subscriptionId = subscriptionId;
    LotteryOwner = msg.sender;
    lPotActive = false;
    lReadySelectWinner = false;
    lWinnerSelected = false;
    generatorLotteryAddr = generatorLotteryAddress;
    // _VRF = VRF;
  }

  /* ToDo : Add & Complete Fallback routine */
  fallback() external payable {
  }

  receive() external payable {
  }

  modifier isAllowedManager() {
      require( msg.sender == potDirector || msg.sender == LotteryOwner , "Permission Denied !!" );
      _;
  }

  modifier isGameOn() {
      require(lPotActive , "The Pot has not been Ready to Play yet Or The Game is Over!");  // && !lReadySelectWinner 
      _;
  }

  function balanceInPot() public view returns(uint){
    return address(this).balance;
  }

  function withdraw() external onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
  }

  /**
    * @notice Request Random Words From VRF Coordinator
    * @dev For more Details refer to : https://docs.chain.link/docs/chainlink-vrf-best-practices/#getting-multiple-random-numbers
  */
  function requestRandomWords() internal isAllowedManager {    
    // Will revert if subscription is not set and funded.
    s_requestId = COORDINATOR.requestRandomWords(
      keyHash,
      s_subscriptionId,
      requestConfirmations,
      callbackGasLimit,
      numWords
    );
  }

  /**
    * @notice VRF Coordinator Call Back this Function after generating Random Number
    * @dev For more Details refer to : https://docs.chain.link/docs/chainlink-vrf-best-practices/#getting-multiple-random-numbers
  */
  function fulfillRandomWords(
    uint256, /* requestId */
    uint256[] memory randomWords
  ) internal override {
    s_randomWords = randomWords;
    // select_Winner_Continue();
    lWinnerSelected = true;
    emit ReadyForSelectWinner(lWinnerSelected);
  }

  /* ToDo : Replace This function with OpenZeppelin SafeMath */
  /**
    * @notice Function for deviding two Integer Numbers and return the results.
    * @dev Safe Function for Devision Operation.
    * @param numerator : The Integer Number which is being devided on another Integer Number.
    * @param denominator : The Integer Number which another Int NUmber is devided by this.  
    * @return quotient and remainder of the Devision, Both are Integer Numbers. 
  */
  function getDivided(uint numerator, uint denominator) private pure returns(uint quotient, uint remainder) {
    require( denominator >= 0, "Division is Not Possible , Bug in Numbers !");
    require( numerator > 0, "Division is Not Possible , Bug in Numbers !");
    quotient  = numerator / denominator; 
    remainder = numerator - denominator * quotient;
  }

  /**
    * @notice The Local Random Generator Function.
    * @dev The Local Random Generator Function for Local Development and Running the Tests.
    * @return None. 
  */
  function randomGenerator() private view returns (uint) {
    return uint(
      keccak256(
        abi.encodePacked(
          block.difficulty, block.timestamp, _WeeklyWinnersArray ))) ;
  }

  // function getRandomValue(address _VRFv2) public view onlyOwner returns (uint256 randomWords) {
  //   // uint8 zeroOne = uint8(randomGenerator() % 2);
  //   // randomWords = randomGenerator();
  //   randomWords = VRFv2Consumer(_VRFv2).getlRandomWords();
  // }

  /**
    * @notice Monthly Lottery Pot Initialization.
    * @dev AtFirst each Monthly Pot must be Initialized.
    * @return success Flag 
  */
  function potInitialize() external isAllowedManager returns(bool success) {
    require(lPotActive == false, "The Monthly Pot is started before !");
    _WeeklyWinnersArray = getWeeklyWinnersArray();  
    lPotActive = true ;
    lWinnerSelected = false;
    if (_WeeklyWinnersArray.length > 0) {
        lReadySelectWinner = true;
        success = true;
    } else {
        lReadySelectWinner = false;
        success = false;
    }
}

  /**
    * @notice Hourly Lottery Pot is Pausable, This is the Trigger.
    * @dev THis Function just Pauses the current Pot Play and Select Winner Routines and Use only for Emergency .
    * @return success Flag 
  */
  function potPause() external isAllowedManager returns(bool success) {
    lPotActive = false ;
    lReadySelectWinner = false;
    lWinnerSelected = false;
    success = true;
  }

  /**
    * @notice Monthly Lottery Pot Winner Selection, This Winner is Selected among Weekly Winner List.
    * @dev Monthly Lottery Pot Winner Selection Start Process, This Function Just Called Request Random Number Routine For Communicate with VRF Coordinator. 
    * @return success Flag 
  */
  function select_Winner() public isAllowedManager returns(bool success) {  

    require(lReadySelectWinner == true, "The Pot is not ready for Selecting the Winner");
    require(lWinnerSelected == false, "The Winner has Not been Selected Yet !");

    // lPotActive = false;
    vrfCalledTime = block.timestamp;
    emit StartSelectngWinner(vrfCalledTime);
    
    requestRandomWords();  
    // lWinnerSelected = true;   // For local test with Remix

    success = true;

  }

  /**
    * @notice Monthly Lottery Pot Winner Selection Continue, This Function Selects The Winner With Random Number Generated.
    * @dev Monthly Lottery Pot Winner Selection Continue, This Function Only Call after fulfillRandomWords is Called. 
    * @dev This Function is responsible for Updating Lottery Data, Pay the Winner Prize & then clear and Release the Memory
    * @return success Flag 
  */
  function select_Winner_Continue() public isAllowedManager returns(bool success) {  
    
    require(lReadySelectWinner == true, "The Pot is not ready for Selecting the Winner");
    // if (planB_VRFDelay() == false) {
      require(lWinnerSelected == true, "The Winner has been Selected before !!");
    // }

    // _WeeklyWinnersArray = getWeeklyWinnersArray();  
    // uint256 l_randomWords = getRandomValue(_VRF);
    uint winnerIndex = s_randomWords[0] % _WeeklyWinnersArray.length;   // l_randomWords
    // uint randomWords = randomGenerator();     // For local test with Remix
    // uint winnerIndex = randomWords % _WeeklyWinnersArray.length;     // For local test with Remix   

    uint winnerPrize = address(this).balance; // Calculation();
    potWinnerPrize = address(this).balance;
    
    emit SelectWinnerIndex(winnerIndex, address(this).balance, winnerPrize);
    
    UpdateLotteryData(winnerIndex, address(this).balance, winnerPrize);
    WinnerPrizePayment(winnerIndex, winnerPrize); 
    // FinalPayment();
    ClearDataBase();

    lPotActive = false;
    lReadySelectWinner = false;
    lWinnerSelected = false;
    success = true;

  }

  /**
    * @notice Release Smart Contract Memory .
    * @dev Clear All Storages .
    * @return True
  */
  function ClearDataBase() private returns (bool) {
    bool _success;
    _success = LotteryInterface(generatorLotteryAddr).clearWeeklyWinnersArrayMap(msg.sender);
    return true;
  }

  /**
    * @notice Calculation of Pot Winner Prize.
    * @dev Findout the 5% of the Total Pot and The Winner payment.
  */
  // function Calculation() internal view returns (uint winnerPrize){

  //   uint totalPot = address(this).balance;
  //   // _LotteryWinnersArray = getLotteryWinnersArray();  
  //   // address WinnerAddress = _LotteryWinnersArray[_winnerIndex];
  //   (winnerPrize, ) = getDivided(totalPot, 20);  // winnerPrize

  // }

  /**
    * @notice Pay Pot Prize to the Winner.
    * @dev Transfer Pot Prize to the Winner.
  */
  function WinnerPrizePayment(uint _winnerIndex, uint _winnerPrize) private {

    // _LotteryWinnersArray = getLotteryWinnersArray();  
    address payable potWinner = payable(_WeeklyWinnersArray[_winnerIndex]);  
    potWinner.transfer(_winnerPrize);
    emit SelectWinnerAddress(potWinner, _winnerPrize);
    // _LotteryWinnersArray[winnerIndex].transfer(address(this).balance);

  }

  /**
    * @notice Remaining Pot Money Transfer.
    * @dev Transfer remaining Money to the Liquidity Pool.
  */
  // function FinalPayment() internal {   // onlyOwner 

  //   address payable receiver = payable(LiquidityPoolAddress);
  //   uint TrxValue = address(this).balance;
  //   receiver.transfer(TrxValue);
  //   emit TotalPayment(receiver, TrxValue);

  // }

  /**
    * @notice Save The Winner Address for Monthly Lottery
    * @dev Update Generator Smart Contract For Saving Hourly Winner Address
  */
  function UpdateLotteryData(uint _winnerIndex, uint _balance, uint winnerPrize) private returns(bool) {
    bool _success;
    uint _winnerId;
    // _LotteryWinnersArray = getLotteryWinnersArray();  
    // address _winnerAddress = _WeeklyWinnersArray[_winnerIndex];
    potWinnerAddress = _WeeklyWinnersArray[_winnerIndex];
    _success = LotteryInterface(generatorLotteryAddr).setlotteryStructs(address(this), msg.sender, _balance, potWinnerAddress , 3);  
    _winnerId = LotteryInterface(generatorLotteryAddr).setMonthlyWinnersArrayMap(msg.sender, potWinnerAddress, winnerPrize );  
    return true;
  }

  /**
    * @notice This Function is Only a PLan B for When The VRF Coordinator does not respond in a short time .
    * @dev Only If after 5 min the VRF Coordinator does not respond This function Change the lWinnerSelected to True so the Last Random Word used instead of a new one .
    * @return isActive Flag 
  */
  function planB_VRFDelay() public isAllowedManager returns(bool isActive){ 
    require(lReadySelectWinner == true, "The Pot is not ready for Selecting the Winner");
    require(lWinnerSelected == false, "The Winner has been Selected before !!");
    uint nowTime = block.timestamp;
    uint waitTime = 0;
    if (nowTime > vrfCalledTime) {
      waitTime = nowTime - vrfCalledTime ;
      if (waitTime > 5 minutes) {
          lWinnerSelected = true;
          isActive = true;
      } else {
        isActive = false;
      }
    } else {
      isActive = false;
    }
  }

  /**
    * @notice Get the list of All Weekly Lottery Winners
    * @dev 
    * @return Weekly Winner List
  */
  function getWeeklyWinnersArray() public view returns(address[] memory) {
    return LotteryInterface(generatorLotteryAddr).getWeeklyWinners();
  }

  function set_generatorLotteryAddress(address _contractAddr) external onlyOwner {
    generatorLotteryAddr = _contractAddr;
  }

  // function set_LiquidityPoolAddress(address _LiquidityPoolAddress) external onlyOwner {
  //   require(_LiquidityPoolAddress != address(0) );
  //   LiquidityPoolAddress = _LiquidityPoolAddress;
  // }

  // function set_MultiSigWalletAddress(address _MultiSigWalletAddress) external onlyOwner {
  //   require(_MultiSigWalletAddress != address(0) );
  //   MultiSigWalletAddress = _MultiSigWalletAddress;
  // }

  function setDirector(address _DirectorAddress) external onlyOwner {
    require(_DirectorAddress != address(0) );
    potDirector = _DirectorAddress;
  }

  function listPlayers() external view returns (address[] memory){  
    return _WeeklyWinnersArray;  
  }

  function isPotActive() public view returns(bool) {
    return lPotActive;
  }

  function getPlayersNumber() public view returns(uint) {
    return _WeeklyWinnersArray.length;
  }

  function getWinners() public view returns(address, uint) {
    return ( potWinnerAddress, potWinnerPrize );  
  }  

  function isReadySelectWinner() public view returns(bool) {
    return lReadySelectWinner;
  }

  function isWinnerSelected() public view returns(bool) {
    return lWinnerSelected;
  }

  function getPotDirector() public view returns(address) {
    return potDirector;
  }

  // function getVerifier() public view returns(address) {
  //   return _VRF;
  // }

}

/**
************************************************************************************
************************************************************************************
*/


