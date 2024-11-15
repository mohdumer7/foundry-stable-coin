//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

/*
*This is a DSC Engine for Decentalised Logic
*This contract is responsible for maintaining the peg of DSC.
*@author @Mohammed Umer
*/

import {DecentralisedStableCoin} from "./DecentralisedStableCoin.sol";
import {ReentrancyGuard} from "@openzeppelin/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract DSCEngine is ReentrancyGuard{
    error DSCEngine__NeedsMoreThanZero();
    error DSCEngine__TokenAddressesAndPriceFeedAddressesLengthMustBeSame();
    error DSCEngine__TokenNotAllowed();
    error DSCEngine__TransferFailed();
    error DSCEngine__HealthFactorIsBroken(uint256 healthFactorValue);
    error DSCEngine__MintFailed();

    uint256 private constant ADDITIONAL_FEED_PRECISION = 1e10;
    uint256 private constant PRECISION = 1e18;
    uint256 private constant LIQUIDATION_THRESHOLD = 50;
    uint256 private constant LIQUIDATION_PRECISION = 100;
    uint256 private constant MIN_HEALTH_FACTOR = 1;
    

    mapping(address token => address priceFeed) public s_priceFeeds;
    mapping(address user => mapping(address token => uint256 amount)) private s_collateralDeposited;
    mapping(address user => uint256 amountDscMinted) private s_DscMinted;
    DecentralisedStableCoin private immutable i_dsc;

    address[] private s_collateralTokens;

    constructor(address[] memory tokenAddresses, address[] memory priceFeedAddresses,address dscAddress){
        if(tokenAddresses.length != priceFeedAddresses.length){
            revert DSCEngine__TokenAddressesAndPriceFeedAddressesLengthMustBeSame();
        }
        for(uint256 i = 0; i < tokenAddresses.length; i++){
            s_priceFeeds[tokenAddresses[i]] = priceFeedAddresses[i];
            s_collateralTokens.push(tokenAddresses[i]);
        }
        i_dsc = DecentralisedStableCoin(dscAddress);
    }

    event CollateralDeposited(address indexed user, address indexed token, uint256 indexed amount);

    modifier moreThanZero(uint256 amount){
        if(amount == 0){
            revert DSCEngine__NeedsMoreThanZero();
        }
        _;
    }

    modifier isAllowedToken(address token){
        if(s_priceFeeds[token] == address(0)){
            revert DSCEngine__TokenNotAllowed();
        }
        _;
    }

    function depositCollateralAndMintDsc(address tokenCollateralAddress,uint256 amountCollateral,uint256 amountDscToMint) external {
        depositCollateral(tokenCollateralAddress,amountCollateral);
        mintDsc(amountDscToMint);
    }

    function depositCollateral(address tokenCollateralAddress,uint256 amountCollateral) public moreThanZero(amountCollateral) isAllowedToken(tokenCollateralAddress) nonReentrant{
        s_collateralDeposited[msg.sender][tokenCollateralAddress] += amountCollateral;
        emit CollateralDeposited(msg.sender, tokenCollateralAddress, amountCollateral);
        bool success = IERC20(tokenCollateralAddress).transferFrom(msg.sender, address(this), amountCollateral);
        if(!success){
            revert DSCEngine__TransferFailed();
        }
    }

    function redeemCollateralForDsc() external {
        
    }

    function redeemCollateral() external {

    }

    function mintDsc(uint256 amountDscToMint) public
     moreThanZero(amountDscToMint) {
        s_DscMinted[msg.sender] += amountDscToMint;
        //if they minted too much dsc
        _revertIfHealthFactorIsBroken(msg.sender);
        bool minted = i_dsc.mint(msg.sender, amountDscToMint);
        if(!minted){
            revert DSCEngine__TransferFailed();
        }
    }

    function burnDsc() external {

    }

    function liquidateDsc() external {

    }

    function getHealthFactor() external view returns (uint256) {
        
    }

    //internal and private functions

    function _getAccountInformation(address user) private view returns (uint256 totalDscMinted, uint256 colalateralvalueInUsd) {
        totalDscMinted = s_DscMinted[user];
        colalateralvalueInUsd = getAccountCollateralvalue(user);
        return (totalDscMinted, colalateralvalueInUsd);
    }

    function _healthFactor(address user) private view returns (uint256){
        //get the amount of collateral
        //get the amount of dsc minted
        //calculate the health factor
        (uint256 totalDscMinted, uint256 colalateralvalueInUsd) = _getAccountInformation(user);
        uint256 collateralAdjustedForThreshold = (colalateralvalueInUsd * LIQUIDATION_THRESHOLD) / LIQUIDATION_PRECISION;
        return (collateralAdjustedForThreshold * PRECISION ) / totalDscMinted;
    }

    function _revertIfHealthFactorIsBroken(address user)internal view{
        //check health factor
        uint256 userHealthFactor = _healthFactor(user);
        //revert if they dont
        if(userHealthFactor < MIN_HEALTH_FACTOR){
            revert DSCEngine__HealthFactorIsBroken(userHealthFactor);
        }
    }

    function getAccountCollateralvalue(address user) public view returns(uint256 totalCollateralValue){
        for(uint256 i=0; i < s_collateralTokens.length; i++){
            address token = s_collateralTokens[i];
            uint256 amount = s_collateralDeposited[user][token];
            totalCollateralValue += getUsdValue(token, amount);
        }
        return totalCollateralValue;
    }

    function getUsdValue(address token, uint256 amount) public view returns(uint256)  {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[token]);
        (,int256 price,,,) = priceFeed.latestRoundData();
        return ((uint256(price) * ADDITIONAL_FEED_PRECISION) * amount) / PRECISION;
    }
}
