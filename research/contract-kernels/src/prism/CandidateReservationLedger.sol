// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title Candidate reservation ledger
/// @notice Research kernel of `ReservationLedger.deposit` and `reserve` in
///         `research/prism-model/reservation_ledger.py`.
/// @dev These are research-kernel semantics. This contract is not an accepted oracle,
///      not MATH-1 PASS, not CONTRACT-1, and not a cross-module deposit harness.
///      It does not move tokens and it does not call a prediction market.
///      The same raw units cannot be reserved by two series ids. A reserve that
///      asks for more than the unreserved balance leaves the ledger unchanged.
///      There is no fee, governance, upgrade path, leverage, or negative amount.
contract CandidateReservationLedger {
    mapping(bytes32 asset => uint256) private _balances;
    mapping(bytes32 asset => uint256) private _totalReserved;
    mapping(bytes32 seriesId => mapping(bytes32 asset => uint256)) private _reservedFor;

    error EmptySeries();
    error InsufficientUnreserved(bytes32 asset, uint256 requested, uint256 available);

    function balance(bytes32 asset) external view returns (uint256) {
        return _balances[asset];
    }

    function totalReserved(bytes32 asset) external view returns (uint256) {
        return _totalReserved[asset];
    }

    function reservedFor(bytes32 seriesId, bytes32 asset) external view returns (uint256) {
        return _reservedFor[seriesId][asset];
    }

    function available(bytes32 asset) public view returns (uint256) {
        return _balances[asset] - _totalReserved[asset];
    }

    /// @notice Increase the accounted balance. This does not pull a token.
    function deposit(bytes32 asset, uint256 amount) external {
        _balances[asset] += amount;
    }

    /// @notice Reserve `amount` for `seriesId` when it is still unreserved.
    /// @dev The free-balance check happens before either reservation write.
    function reserve(bytes32 seriesId, bytes32 asset, uint256 amount) external {
        if (seriesId == bytes32(0)) revert EmptySeries();
        uint256 free = available(asset);
        if (amount > free) revert InsufficientUnreserved(asset, amount, free);
        _reservedFor[seriesId][asset] += amount;
        _totalReserved[asset] += amount;
    }
}
