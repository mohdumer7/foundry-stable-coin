//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC20Burnable, ERC20} from "@openzeppelin/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/access/Ownable.sol";

/*
 *@title DecentralisedStableCoin
 *@author @Mohammed Umer
 *@notice This is a decentralised stablecoin with a 1:1 dollar peg.
 *@dev This is a decentralised stablecoin with a 1:1 dollar peg.
 * We are using the ERC20BURNABLE because we peg the token and burn it when out of circulation.
 */

contract DecentralisedStableCoin is ERC20Burnable, Ownable {
    error DecentralisedStableCoin__AmountMustBeMoreThanZero();
    error DecentralisedStableCoin__BurnAmountExceedsBalance();
    error DecentralisedStableCoin__AddressCannotBeZero();

    constructor() ERC20("Decentralised Stable Coin", "DSC") Ownable() {}

    function burn(uint256 _amount) public override onlyOwner {
        uint256 balance = balanceOf(msg.sender);
        if (_amount <= 0) {
            revert DecentralisedStableCoin__AmountMustBeMoreThanZero();
        }
        if (balance < _amount) {
            revert DecentralisedStableCoin__BurnAmountExceedsBalance();
        }
        super.burn(_amount);
    }

    function mint(
        address _to,
        uint256 _amount
    ) external onlyOwner returns (bool) {
        if (_to == address(0)) {
            revert DecentralisedStableCoin__AddressCannotBeZero();
        }
        if (_amount <= 0) {
            revert DecentralisedStableCoin__AmountMustBeMoreThanZero();
        }
        _mint(_to, _amount);
        return true;
    }
}
