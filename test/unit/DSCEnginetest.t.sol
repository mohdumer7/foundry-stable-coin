//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {DecentralisedStableCoin} from "../../src/DecentralisedStableCoin.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {ERC20Mock} from "@openzeppelin/mocks/ERC20Mock.sol";

contract DSCEngineTest is Test{

    DeployDSC deployer;
    DecentralisedStableCoin dsc;
    DSCEngine engine;
    HelperConfig config;
    address ethUsdPriceFeed;
    address wethUsdPriceFeed;
    address weth;

    address public USER  = makeAddr("user");
    uint256 public constant AMOUNT_COLLATERAL = 10 ether;
    uint256 public constant STARTING_ERC20_BALANCE = 10 ether;

    function setUp() public {
        deployer = new DeployDSC();
        (dsc, engine, config) = deployer.run();
        (ethUsdPriceFeed, , weth, ,) = config.activeNetworkConfig();

        ERC20Mock(weth).mint(USER,STARTING_ERC20_BALANCE);  
    }

    //price tests
    function testGetUsdValue() public {
        uint256 ethAmount = 15e18;

        uint256 expectedUsd = 30000e18;
        uint256 actualUsd = engine.getUsdValue(weth,ethAmount);
        assertEq(expectedUsd,actualUsd);
    }

    function testRevertIfCollaeteralZero() public {
        vm.startPrank(USER);

        //this is like simulating the user approving the engine to spend the collateral
        ERC20Mock(weth).approve(address(engine),AMOUNT_COLLATERAL);

        //expecting the engine to revert because the amount is 0
        vm.expectRevert(DSCEngine.DSCEngine__NeedsMoreThanZero.selector);
        engine.depositCollateral(weth,0);
        vm.stopPrank();
    }

}