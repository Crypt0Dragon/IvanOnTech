const Ownable = artifacts.require("Ownable");
const Coinflip = artifacts.require("Coinflip");


module.exports = function(deployer) {
  deployer.deploy(Coinflip).then(function(instance){
      instance.fund({value: web3.utils.toWei("4", "ether")});
    });
  deployer.deploy(Ownable);
};
