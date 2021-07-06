/**
 * @type import('hardhat/config').HardhatUserConfig
 */
require('@nomiclabs/hardhat-waffle');
require('hardhat-tracer');


// private key from the pre-funded account
const { privateKey1, privateKey2 } = require('./secrets.json');

module.exports = {
  solidity: {
    version: "0.8.0",
    settings: {
      optimizer: {
        enabled: false
      }
    }
  },
  defaultNetwork: "goerli",
  networks: {
    hardhat: {
    },
    goerli: {
      url: "https://eth-goerli.alchemyapi.io/v2/GfcseLxG87obEYjhy3VzUh8BOOIugm8Y",
      accounts: [privateKey1, privateKey2]
    }
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    artifacts: "./artifacts"
  },
  mocha: {
    timeout: 60000
  }
};
