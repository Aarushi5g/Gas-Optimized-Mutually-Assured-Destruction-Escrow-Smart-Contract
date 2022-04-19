const escrow_gas = artifacts.require("Escrow_gas");

module.exports = function (deployer) {
  deployer.deploy(escrow_gas);
};