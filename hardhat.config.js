require("@nomicfoundation/hardhat-toolbox");
require("hardhat-gas-reporter");


/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.16",
  gasReporter: {
    enabled: true,
    currency: 'USD',
    coinmarketcap: '2cee659c-20dc-4896-8015-b75cb6383150',
    // gasPrice: 17
  }
};
