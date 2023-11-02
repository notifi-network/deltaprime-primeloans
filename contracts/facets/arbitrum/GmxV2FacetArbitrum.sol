// SPDX-License-Identifier: BUSL-1.1
// Last deployed from commit: 799a1765b64edc5c158198ef84f785af79e234ae;
pragma solidity 0.8.17;

//This path is updated during deployment
import "../GmxV2Facet.sol";

abstract contract GmxV2FacetArbitrum is GmxV2Facet {
    using TransferHelper for address;

    // https://github.com/gmx-io/gmx-synthetics/blob/main/deployments/arbitrum/
    // GMX contracts
    function getGMX_V2_ROUTER() internal pure virtual override returns (address) {
        return 0x820F5FfC5b525cD4d88Cd91aCf2c28F16530Cc68;
    }

    function getGMX_V2_EXCHANGE_ROUTER() internal pure virtual override returns (address) {
        return 0x7C68C7866A64FA2160F78EEaE12217FFbf871fa8;
    }

    function getGMX_V2_DEPOSIT_VAULT() internal pure virtual override returns (address) {
        return 0xF89e77e8Dc11691C9e8757e84aaFbCD8A67d7A55;
    }

    function getGMX_V2_WITHDRAWAL_VAULT() internal pure virtual override returns (address) {
        return 0x0628D46b5D145f183AdB6Ef1f2c97eD1C4701C55;
    }

    // TODO: Dynamically source whitelisted keepers?
    function getGMX_V2_KEEPER() internal pure virtual override returns (address) {
        return 0xE47b36382DC50b90bCF6176Ddb159C4b9333A7AB;
    }

    // Markets
    address constant GM_ETH_USDC = 0x70d95587d40A2caf56bd97485aB3Eec10Bee6336;

    // Tokens
    address constant ETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address constant USDC = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;

    // Mappings
    function marketToLongToken(address market) internal override pure returns (address){
        if(market == GM_ETH_USDC){
            return ETH;
        } else {
            revert("Market not supported");
        }
    }

    function marketToShortToken(address market) internal override pure returns (address){
        if(market == GM_ETH_USDC){
            return USDC;
        } else {
            revert("Market not supported");
        }
    }

    function depositEthUsdcGmxV2(bool isLongToken, uint256 tokenAmount, uint256 minGmAmount, uint256 executionFee) external payable onlyWhitelistedAccounts {
        address _depositedToken = isLongToken ? ETH : USDC;

        _deposit(GM_ETH_USDC, _depositedToken, tokenAmount, minGmAmount, executionFee);
    }

    function withdrawEthUsdcGmxV2(uint256 gmAmount, uint256 minLongTokenAmount, uint256 minShortTokenAmount, uint256 executionFee) external payable onlyWhitelistedAccounts {
        _withdraw(GM_ETH_USDC, gmAmount, minLongTokenAmount, minShortTokenAmount, executionFee);
    }

    // MODIFIERS
    modifier onlyWhitelistedAccounts {
        if(
            msg.sender == 0x0E5Bad4108a6A5a8b06820f98026a7f3A77466b2 ||
            msg.sender == 0x2fFA7E9624B923fA811d9B9995Aa34b715Db1945 ||
            msg.sender == 0x0d7137feA34BC97819f05544Ec7DE5c98617989C ||
            msg.sender == 0xC6ba6BB819f1Be84EFeB2E3f2697AD9818151e5D ||
            msg.sender == 0x14f69F9C351b798dF31fC53E33c09dD29bFAb547 ||
            msg.sender == 0x5C23Bd1BD272D22766eB3708B8f874CB93B75248 ||
            msg.sender == 0x000000F406CA147030BE7069149e4a7423E3A264 ||
            msg.sender == 0x5D80a1c0a5084163F1D2620c1B1F43209cd4dB12 ||
            msg.sender == 0xb79c2A75cd9073d68E75ddF71D53C07747Df7933 ||
            msg.sender == 0x6C21A841d6f029243AF87EF01f6772F05832144b
        ){
            _;
        } else {
            revert("Not whitelisted");
        }
    }
}
