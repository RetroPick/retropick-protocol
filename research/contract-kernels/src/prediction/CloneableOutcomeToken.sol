// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @notice Storage-based outcome token used only to measure ERC-1167 gas.
/// @dev PredictionMarket does not deploy this. OutcomeToken keeps market, index,
///      and decimals immutable. A clone of that token would share those values.
contract CloneableOutcomeToken {
    address public market;
    uint8 public outcomeIndex;
    uint8 private _decimals;
    string public name;
    string public symbol;
    uint256 public totalSupply;
    bool private _initialized;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    error AlreadyInitialized();
    error NotMarket();

    function initialize(
        address market_,
        uint8 outcomeIndex_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) external {
        if (_initialized) revert AlreadyInitialized();
        _initialized = true;
        market = market_;
        outcomeIndex = outcomeIndex_;
        name = name_;
        symbol = symbol_;
        _decimals = decimals_;
    }

    function decimals() external view returns (uint8) {
        return _decimals;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        allowance[from][msg.sender] -= amount;
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        return true;
    }

    function mint(address to, uint256 amount) external {
        if (msg.sender != market) revert NotMarket();
        totalSupply += amount;
        balanceOf[to] += amount;
    }

    function burn(address from, uint256 amount) external {
        if (msg.sender != market) revert NotMarket();
        totalSupply -= amount;
        balanceOf[from] -= amount;
    }
}
