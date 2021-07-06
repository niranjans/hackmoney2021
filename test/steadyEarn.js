const { expect } = require('chai');
const { ethers } = require('hardhat');

describe('Earn Contract', () => {
  let SteadyEarn, EarnToken, steadyEarn, earnToken, owner, addr1, addr2;
  const BALANCER_VAULT = '0x65748E8287Ce4B9E6D83EE853431958851550311';
  const IWETH_ADDR = '0x9A1000D492d40bfccbc03f413A48F5B6516Ec0Fd';
  const CURRENT_PT_TOKEN_ADDR = '0x9eB7F54C0eCc4d0D2dfF28a1276e36d598F2B0D1';
  const EARN_TOKEN_ADDR = '0xe2de509a6cB7C5fed9937627BF06A76A2DB7Bb70';
  const CURRENT_TRANCHE_ADDR = '0x89d66Ad25F3A723D606B78170366d8da9870A879';
  const ASSET_WETH = '0x9A1000D492d40bfccbc03f413A48F5B6516Ec0Fd';
  const ASSET_PT = '0x89d66Ad25F3A723D606B78170366d8da9870A879';
  const BALANCER_POOL_ID = '0x9eb7f54c0ecc4d0d2dff28a1276e36d598f2b0d1000200000000000000000066';

  // constructor (address _balancerVault, address _iWeth, address _currentPToken, address _earnToken, address _currentTranche, IAsset _assetWeth, IAsset _assetPT, bytes32 _balancerPoolId) {

  beforeEach(async () => {
    SteadyEarn = await ethers.getContractFactory('SteadyEarn');
    EarnToken = await ethers.getContractFactory('EarnToken');

    // steadyEarn = await SteadyEarn.deploy(
    //   BALANCER_VAULT,
    //   IWETH_ADDR,
    //   CURRENT_PT_TOKEN_ADDR,
    //   EARN_TOKEN_ADDR,
    //   CURRENT_TRANCHE_ADDR,
    //   ASSET_WETH,
    //   ASSET_PT,
    //   BALANCER_POOL_ID
    //   );

//      console.log('steadyEarn address - ', steadyEarn.address);

      steadyEarn = await SteadyEarn.attach('0x25D14e5d8857007bffeE6d892525bcbC11eFd830');

      earnToken = await EarnToken.attach(
        EARN_TOKEN_ADDR
      );

    [owner, addr1, addr2, _] = await ethers.getSigners();
  });

  describe('Deployment', () => {
    it('Should set the right owner', async () => {
      expect(await steadyEarn.owner()).to.equal(owner.address);
    })
  });

  describe('Transactions', () => {
    it('Should be able to mint', async () => {
      let balanceBefore = await earnToken.balanceOf(owner.address);

      const mintTx = await steadyEarn.testMinting(9000000);

      await mintTx.wait();

      let balanceAfter = await earnToken.balanceOf(owner.address);
      
      console.log('*** Balance before and after - ', balanceBefore.toString(), balanceAfter.toString(), mintTx);

      expect(balanceBefore.lt(balanceAfter)).to.be.true;
    })
  });

});