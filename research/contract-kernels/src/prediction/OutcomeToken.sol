// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

/// @notice Immutable ERC-20 outcome balance. The market is the only minter and burner.
/// @dev Financial state other than supply lives on the market. This token stores the
///      market address and the outcome index so holders can identify the claim.
contract OutcomeToken is ERC20 {
    address public immutable market;
    uint8 public immutable outcomeIndex;
    uint8 private immutable _decimals;

    error NotMarket();

    constructor(address market_, uint8 outcomeIndex_, string memory name_, string memory symbol_, uint8 decimals_)
        ERC20(name_, symbol_)
    {
        market = market_;
        outcomeIndex = outcomeIndex_;
        _decimals = decimals_;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function mint(address to, uint256 amount) external {
        if (msg.sender != market) revert NotMarket();
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external {
        if (msg.sender != market) revert NotMarket();
        _burn(from, amount);
    }
}
