// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ExactAssetV2} from "./ExactAssetV2.sol";

/// @notice Permanent, per-executor custody for unsolicited assets, excluded from every launch ledger.
contract ExecutorDonationLockV2 {
    address public immutable executor;

    constructor(address executor_) {
        executor = executor_;
    }
    receive() external payable {}
}

library ExecutorDonationsV2 {
    event UnsolicitedAssetsLocked(address indexed asset, address indexed receiver, uint256 amount);
    error DonationTransferFailed();

    function quarantine(address launchToken, address quoteAsset, uint256 nativeInput, address receiver) internal {
        // Forced native transfers must not make every future completion permanently uncallable.
        uint256 nativeDonation = address(this).balance - nativeInput;
        if (nativeDonation != 0) {
            (bool ok,) = payable(receiver).call{value: nativeDonation}("");
            if (!ok) revert DonationTransferFailed();
            emit UnsolicitedAssetsLocked(address(0), receiver, nativeDonation);
        }
        _token(launchToken, receiver);
        if (quoteAsset != address(0)) _token(quoteAsset, receiver);
    }

    function _token(address asset, address receiver) private {
        uint256 amount = IERC20(asset).balanceOf(address(this));
        if (amount != 0) {
            ExactAssetV2.send(asset, receiver, amount);
            emit UnsolicitedAssetsLocked(asset, receiver, amount);
        }
    }
}
