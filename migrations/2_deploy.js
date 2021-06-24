const FundMigrator = artifacts.require('FundMigrator');

module.exports = function (deployer, network, [creator]) {
  // if (network !== 'bsctestnet') return;
  deployer.then(async () => {
    await deployer.deploy(FundMigrator);
    const fundMigrator = await FundMigrator.deployed();
    console.log('deployed success, migrator:', fundMigrator.address); 

    const beforeDesiredRate = await fundMigrator.getDesiredRate();
    console.log('before setting the desiredRate:', beforeDesiredRate.words[0]);  

    await fundMigrator.setDesiredRate('9000000000');
    const afterDesiredRate = await fundMigrator.getDesiredRate();
    console.log('before setting the desiredRate:', afterDesiredRate.words[0]);  
  });
};
