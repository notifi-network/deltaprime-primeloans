import {embedCommitHash} from "../../tools/scripts/embed-commit-hash";

const {ethers} = require("hardhat");
import addresses from "../../common/addresses/avax/token_addresses.json";
import {toBytes32} from "../../test/_helpers";
import verifyContract from "../../tools/scripts/verify-contract";
import hre from "hardhat";

const supportedAssets = [
    asset('AVAX'),
    asset('USDC'),
    asset('BTC'),
    asset('ETH'),
    asset('USDT'),
    asset('LINK'),
    asset('QI'),
    asset('SAVAX')
]

function asset(symbol) {
    return { asset: toBytes32(symbol), assetAddress: addresses[symbol] }
}

function pool(symbol, address) {
    return { asset: toBytes32(symbol), poolAddress: address }
}

module.exports = async ({
                            getNamedAccounts,
                            deployments
                        }) => {
    const {deploy} = deployments;
    const {deployer} = await getNamedAccounts();

    embedCommitHash('RedstoneConfigManager');
    embedCommitHash('TokenManager');

    const wavaxPoolTUP = await ethers.getContract("WavaxPoolTUP");
    const usdcPoolTUP = await ethers.getContract("UsdcPoolTUP");

    let lendingPools = [
        pool("AVAX", wavaxPoolTUP.address),
        pool("USDC", usdcPoolTUP.address)
    ];

    let tokenManager = await deploy('TokenManager', {
        from: deployer,
        gasLimit: 8000000,
        args:
            [
                supportedAssets,
                lendingPools
            ],
    });

    await verifyContract(hre, {
        address: tokenManager.address
    });

    console.log(`Deployed tokenManager at address: ${tokenManager.address}`);

    //TODO: check before the production deploy
    let redstoneConfigManager = await deploy('RedstoneConfigManager', {
        from: deployer,
        gasLimit: 8000000,
        args:
        [
            [
                "0x981bdA8276ae93F567922497153de7A5683708d3",
                "0x3BEFDd935b50F172e696A5187DBaCfEf0D208e48",
                "0x1Cd8F9627a2838a7DAE6b98CF71c08B9CbF5174a",
                "0xbC5a06815ee80dE7d20071703C1F1B8fC511c7d4",
                "0xe9Fa2869C5f6fC3A0933981825564FD90573A86D",
                "0xDf6b1cA313beE470D0142279791Fa760ABF5C537",
                "0xa50abc5D76dAb99d5fe59FD32f239Bd37d55025f",
                "0x496f4E8aC11076350A59b88D2ad62bc20d410EA3",
                "0x41FB6b8d0f586E73d575bC57CFD29142B3214A47",
                "0xC1068312a6333e6601f937c4773065B70D38A5bF",
                "0xAE9D49Ea64DF38B9fcbC238bc7004a1421f7eeE8",
                "0x2BC37a0368E86cA0d14Bc8788D45c75deabaC064",
                "0x9277491f485460575918B43f5d6D5b2BB8c5A62d",
                "0x91dC1fe6472e18Fd2C9407e438dD022f22891a4f",
                "0x4bbb86992E94AA209c52ecfd38897A18bde8E39D",
                "0x9456dd79c3608cF463d975F76f7658f87a41Cd6C",
                "0x4C6f83Faa74106139FcB08d4E49568e0Df222815",
                "0x4CF8310ABAe9CA2ACD85f460B509eE495F36eFAF",
                "0x2D0645D863a4eE15664761ea1d99fF2bae8aAe35",
                "0xF5c14165fb10Ac4926d52504a9B45550411A3C0F",
                "0x11D23F3dbf8B8e1cf61AeF77A2ea0592Bc9860E0",
                "0x60930D9f74811B525356E68D23977baEAb7706d0",
                "0xc1D5b940659e57b7bDF8870CDfC43f41Ca699460"
            ]
        ]
    });

    await verifyContract(hre, {
        address: redstoneConfigManager.address
    });

    console.log(`Deployed redstoneConfigManager at address: ${redstoneConfigManager.address}`);


};

module.exports.tags = ['avalanche'];