const coin = artifacts.require("coin");

module.exports = function(deployer) {
  deployer.deploy(coin,{value:1000000});
};
