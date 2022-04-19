const escrow = artifacts.require("Escrow");

module.exports = function (deployer) {
  deployer.deploy(escrow);
};