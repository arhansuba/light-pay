// smart-contracts/scripts/deploy-payment.js

const CryptoPayment = artifacts.require("CryptoPayment");

module.exports = async function (deployer, network, accounts) {
    try {
        // Deploy the CryptoPayment contract
        await deployer.deploy(CryptoPayment);

        // Retrieve the deployed contract instance
        const cryptoPayment = await CryptoPayment.deployed();

        console.log(`CryptoPayment contract deployed at address: ${cryptoPayment.address}`);
    } catch (error) {
        console.error("Error deploying CryptoPayment contract:", error);
    }
};
