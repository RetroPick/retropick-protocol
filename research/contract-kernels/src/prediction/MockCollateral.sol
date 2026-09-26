// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

/// @notice Test collateral. Fee-on-transfer mode is unqualified and must be rejected by the market.
contract MockCollateral is ERC20 {
    uint8 private immutable _decimals;
    bool public feeOnTransfer;

    constructor(uint8 decimals_) ERC20("Collateral", "COLL") {
        _decimals = decimals_;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function setFeeOnTransfer(bool enabled) external {
        feeOnTransfer = enabled;
    }

    function _update(address from, address to, uint256 value) internal override {
        if (feeOnTransfer && from != address(0) && to != address(0) && value > 0) {
            super._update(from, to, value - 1);
            super._update(from, address(0), 1);
            return;
        }
        super._update(from, to, value);
    }
}
