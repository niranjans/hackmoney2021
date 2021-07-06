pragma solidity ^0.8.0;

import './IBalancerVault.sol';
import './IWeth.sol';
// import "./IERC20.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import './ITranche.sol';
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract SteadyEarn is Ownable {
  using SafeMath for uint256;
  using SafeMath for uint8;

  IBalancerVault balancerVault;
  IERC20 currentPToken;
  IERC20 earnToken;
  ITranche currentTranche;
  IAsset assetWeth;
  IAsset assetPT; // Current PT token
  bytes32 balancerPoolId; // Current term PT pool ID
  uint256 totalPTCount;

  event NewMinting(bytes32 message, uint amount, address receiver);

  IWeth public iWeth;

  constructor (address _balancerVault, address _iWeth, address _currentPToken, address _earnToken, address _currentTranche, IAsset _assetWeth, IAsset _assetPT, bytes32 _balancerPoolId) {
    currentPToken = IERC20(_currentPToken);
    earnToken = IERC20(_earnToken);
    balancerVault = IBalancerVault(_balancerVault);
    iWeth = IWeth(_iWeth);
    currentTranche = ITranche(_currentTranche);
    assetWeth = _assetWeth;
    assetPT = _assetPT;
    balancerPoolId = _balancerPoolId;
  }

  /**
    * @dev Redeems the matured Principal Token back into the underlying (Weth in this case)
    * and swaps the underlying token to the new term PT token.
    * 
    * Eg - Weth PT, Aug 6, 2021 has matured. Get back the Weth and then swap it out for Dec-6-2021 PT tokens
    * 
    */
  function migrateToNewTerm(IAsset _newTermPTAsset, address _newTranche, bytes32 _newPoolId, uint _deadline) external onlyOwner {

    uint releasedWeth = currentTranche.withdrawPrincipal(currentPToken.balanceOf(address(this)), address(this));

    IBalancerVault.SingleSwap memory singleSwap = IBalancerVault.SingleSwap({
        poolId: _newPoolId,
        kind: IBalancerVault.SwapKind.GIVEN_IN, 
        assetIn: assetWeth,
        assetOut: _newTermPTAsset, 
        amount: releasedWeth,
        userData: '0x00'
      });

      IBalancerVault.FundManagement memory funds = IBalancerVault.FundManagement(address(this), false, payable(address(this)), false);

      uint limit = _calcLimit(releasedWeth);

      iWeth.approve(address(balancerVault), releasedWeth);

      totalPTCount = balancerVault.swap(singleSwap, funds, limit, _deadline);

      // Set new values
      assetPT = _newTermPTAsset;
      currentTranche = ITranche(_newTranche);
      balancerPoolId = _newPoolId;
  }

  function deposit(uint _deadline) external payable {
    iWeth.deposit{ value: msg.value }();

    IBalancerVault.SingleSwap memory singleSwap = IBalancerVault.SingleSwap({
      poolId: balancerPoolId,
      kind: IBalancerVault.SwapKind.GIVEN_IN, 
      assetIn: assetWeth,
      assetOut: assetPT, 
      amount: msg.value,
      userData: '0x00'
    });

    IBalancerVault.FundManagement memory funds = IBalancerVault.FundManagement(address(this), false, payable(address(this)), false);

    uint limit = _calcLimit(msg.value);

    iWeth.approve(address(balancerVault), msg.value);

    uint userPT = balancerVault.swap(singleSwap, funds, limit, _deadline);

    totalPTCount += userPT;

    // Calculate user share and mint tokens and transfer to user
    uint percentagePoints = userPT.div(totalPTCount).mul(10000);
    uint tokensToMint = SafeMath.div(earnToken.totalSupply().mul(percentagePoints), 10000);
    
    // Mint new tokens to user
    earnToken.mint(msg.sender, tokensToMint);
  }

  function testWrapEth() external payable {

    iWeth.deposit{ value: msg.value }();

  }

  function testMinting(uint _amount) external {

    earnToken.mint(msg.sender, _amount);
    emit NewMinting('ikoooss', _amount, msg.sender);

  }


  function withdrawAllBalance(uint amount) external {
    require(amount <= address(this).balance);

    payable(msg.sender).transfer(amount);
  }

  function withdrawWeth(uint amaount) external {
    iWeth.withdraw(amaount);
  }

  function balanceOfContract() external view returns (uint){
    return address(this).balance;
  }

  function _calcLimit(uint _amount) private pure returns (uint) {
    // 100 basis point => 1% 
    // return _amount.sub(_calcPercentage(_amount, 100));
    return _amount - _amount*100/10000;
  }

    function _calcPercentage(uint _amount, uint _percentage) private pure returns (uint) {
    // 100 basis point => 1% 
    return _percentage.mul(100).div(10000);
  }
}

// https://raw.githubusercontent.com/element-fi/elf-deploy/main/addresses/goerli.json

// ******* swap -  {
//   poolId: '0x40bf8a2ecb62c6b880302b55a5552a4e315b5827000200000000000000000062',
//   kind: 0, --- GIVEN_IN
//   assetIn: '0x78dEca24CBa286C0f8d56370f5406B48cFCE2f86', - USDC?
//   assetOut: '0x80272c960b862B4d6542CDB7338Ad1f727E0D18d', - PUsdc
//   amount: BigNumber { _hex: '0x0186a0', _isBigNumber: true },
//   userData: '0x00'
// }

  // // address constant BALANCER_ETH_SENTINEL = 0x0000000000000000000000000000000000000000;
  // struct SingleSwap {
  //     bytes32 poolId;
  //     SwapKind kind;
  //     IAsset assetIn;
  //     IAsset assetOut;
  //     uint256 amount;
  //     bytes userData;
  // }

  // struct FundManagement {
  //     address sender;
  //     bool fromInternalBalance;
  //     address payable recipient;
  //     bool toInternalBalance;
  // }

// Weth Aug 6 expiration:
// poolId: 0x9eb7f54c0ecc4d0d2dff28a1276e36d598f2b0d1000200000000000000000066
//  assetIn: 0x00000
// assetOut: 0x89d66Ad25F3A723D606B78170366d8da9870A879
// kind: 0
// 

	// "tokens": {
	// 	"usdc": "0x78dEca24CBa286C0f8d56370f5406B48cFCE2f86",
	// 	"weth": "0x9A1000D492d40bfccbc03f413A48F5B6516Ec0Fd",
	// 	"dai": "0x5bD768CCE8C529CDF23B136bB486a81f64985B92"
  // sentinel; 0x0000000000000000000000000000000000000000
	// },

  // Current wallet balance of PT - 5025847279373551505 (5.025)

  // Balancer vault - 0x65748E8287Ce4B9E6D83EE853431958851550311

  // 0x9eb7f54c0ecc4d0d2dff28a1276e36d598f2b0d1000200000000000000000066,0,0x9A1000D492d40bfccbc03f413A48F5B6516Ec0Fd,0x89d66Ad25F3A723D606B78170366d8da9870A879,5000,1625316216


// Tranche Weth address - 0x89d66Ad25F3A723D606B78170366d8da9870A879

// swap(0x9eb7f54c0ecc4d0d2dff28a1276e36d598f2b0d1000200000000000000000066,0,0x9A1000D492d40bfccbc03f413A48F5B6516Ec0Fd,

  // function swap(bytes32 _poolId, IBalancerVault.SwapKind _kind, IAsset _assetIn, IAsset _assetOut, uint256 _amount, uint _deadline) public payable {
  //   require(msg.value == _amount, 'Amount does not match what was sent');

  //   IBalancerVault.SingleSwap memory singleSwap = IBalancerVault.SingleSwap({
  //       poolId: _poolId,
  //       kind: _kind, 
  //       assetIn: assetWeth,
  //       assetOut: assetPT, 
  //       amount: _amount,
  //       userData: '0x00'
  //     });

  //   IBalancerVault.FundManagement memory funds = IBalancerVault.FundManagement(address(this), false, payable(address(this)), false);

  //   uint limit = _calcLimit(_amount);

  //   iWeth.deposit{ value: msg.value }();

  //   iWeth.approve(address(balancerVault), _amount);

  //   balancerVault.swap(singleSwap, funds, limit, _deadline);
  // }

// constructor (address _balancerVault, address _iWeth, address _currentPToken, address _earnToken, address _currentTranche, IAsset _assetWeth, IAsset _assetPT, bytes32 _balancerPoolId) {

  // 0x65748E8287Ce4B9E6D83EE853431958851550311,0x9A1000D492d40bfccbc03f413A48F5B6516Ec0Fd,0x9eB7F54C0eCc4d0D2dfF28a1276e36d598F2B0D1,0xf7DAF6458BE3E28551D5ed8F068f0a5A3DCb28a2,0x89d66Ad25F3A723D606B78170366d8da9870A879,0x9A1000D492d40bfccbc03f413A48F5B6516Ec0Fd,0x9eB7F54C0eCc4d0D2dfF28a1276e36d598F2B0D1,0x9eb7f54c0ecc4d0d2dff28a1276e36d598f2b0d1000200000000000000000066
  
  // 0x9eb7f54c0ecc4d0d2dff28a1276e36d598f2b0d1000200000000000000000066

  // 0x65748E8287Ce4B9E6D83EE853431958851550311,0x9A1000D492d40bfccbc03f413A48F5B6516Ec0Fd,0x9eB7F54C0eCc4d0D2dfF28a1276e36d598F2B0D1,0xe2de509a6cB7C5fed9937627BF06A76A2DB7Bb70,0x89d66Ad25F3A723D606B78170366d8da9870A879,0x9A1000D492d40bfccbc03f413A48F5B6516Ec0Fd,0x89d66Ad25F3A723D606B78170366d8da9870A879,0x9eb7f54c0ecc4d0d2dff28a1276e36d598f2b0d1000200000000000000000066