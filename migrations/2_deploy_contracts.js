const Grader = artifacts.require("Grader");

module.exports = function (deployer) {
  deployer.deploy(Grader);
};
