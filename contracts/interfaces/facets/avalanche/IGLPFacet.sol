pragma solidity ^0.8.17;

interface IGLPFacet {
    function mintAndStakeGlp(address _token, uint256 _amount, uint256 _minUsdg, uint256 _minGlp) external returns(uint256);

    function unstakeAndRedeemGlp(address _tokenOut, uint256 _glpAmount, uint256 _minOut) external returns(uint256);
}