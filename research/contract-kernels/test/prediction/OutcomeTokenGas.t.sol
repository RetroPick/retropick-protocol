// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

import {CloneableOutcomeToken} from "../../src/prediction/CloneableOutcomeToken.sol";
import {ERC1167} from "../../src/prediction/ERC1167.sol";
import {OutcomeToken} from "../../src/prediction/OutcomeToken.sol";

/// @notice External deployer so Forge's last-call gas meter sees each creation.
contract OutcomeTokenDeployer {
    function deployFull(address market, uint8 index, string memory name_, string memory symbol_, uint8 decimals_)
        external
        returns (address token, uint256 gasUsed, uint256 runtimeBytes)
    {
        bytes memory code =
            abi.encodePacked(type(OutcomeToken).creationCode, abi.encode(market, index, name_, symbol_, decimals_));
        (token, gasUsed) = _create(code);
        runtimeBytes = token.code.length;
    }

    function deployImplementation() external returns (address token, uint256 gasUsed, uint256 runtimeBytes) {
        (token, gasUsed) = _create(type(CloneableOutcomeToken).creationCode);
        runtimeBytes = token.code.length;
    }

    function deployClone(address implementation) external returns (address instance, uint256 gasUsed, uint256 runtimeBytes) {
        bytes memory code = abi.encodePacked(
            hex"3d602d80600a3d3981f3363d3d373d3d3d363d73", implementation, hex"5af43d82803e903d91602b57fd5bf3"
        );
        (instance, gasUsed) = _create(code);
        runtimeBytes = instance.code.length;
    }

    function initializeClone(
        address clone_,
        address market,
        uint8 index,
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) external returns (uint256 gasUsed) {
        bytes memory data =
            abi.encodeCall(CloneableOutcomeToken.initialize, (market, index, name_, symbol_, decimals_));
        uint256 gasBefore;
        uint256 gasAfter;
        bool ok;
        assembly {
            gasBefore := gas()
            ok := call(gas(), clone_, 0, add(data, 0x20), mload(data), 0, 0)
            gasAfter := gas()
        }
        require(ok);
        gasUsed = gasBefore - gasAfter;
    }

    function _create(bytes memory code) private returns (address deployed, uint256 gasUsed) {
        uint256 gasBefore;
        uint256 gasAfter;
        assembly {
            gasBefore := gas()
            deployed := create(0, add(code, 0x20), mload(code))
            gasAfter := gas()
        }
        require(deployed != address(0));
        gasUsed = gasBefore - gasAfter;
    }
}

/// @notice Deployment-gas comparison. Does not change PredictionMarket's token choice.
contract OutcomeTokenGasTest is Test {
    OutcomeTokenDeployer internal deployer;
    uint256 internal fullYes;
    uint256 internal fullNo;
    uint256 internal implementationGas;
    uint256 internal cloneYes;
    uint256 internal initYes;
    uint256 internal cloneNo;
    uint256 internal initNo;

    function setUp() public {
        deployer = new OutcomeTokenDeployer();
    }

    function test_full_deployment_versus_erc1167() public {
        address implementation;
        address yesClone;
        address noClone;
        uint256 fullYesBytes;
        uint256 fullNoBytes;
        uint256 implementationBytes;
        uint256 cloneYesBytes;
        (, fullYes, fullYesBytes) = deployer.deployFull(address(this), 0, "Yes", "YES", 6);
        (, fullNo, fullNoBytes) = deployer.deployFull(address(this), 1, "No", "NO", 6);
        (implementation, implementationGas, implementationBytes) = deployer.deployImplementation();
        (yesClone, cloneYes, cloneYesBytes) = deployer.deployClone(implementation);
        initYes = deployer.initializeClone(yesClone, address(this), 0, "Yes", "YES", 6);
        (noClone, cloneNo, cloneYesBytes) = deployer.deployClone(implementation);
        initNo = deployer.initializeClone(noClone, address(this), 1, "No", "NO", 18);

        emit log_named_uint("full_yes_gas", fullYes);
        emit log_named_uint("full_no_gas", fullNo);
        emit log_named_uint("clone_implementation_gas", implementationGas);
        emit log_named_uint("clone_yes_create_gas", cloneYes);
        emit log_named_uint("clone_yes_initialize_gas", initYes);
        emit log_named_uint("clone_no_create_gas", cloneNo);
        emit log_named_uint("clone_no_initialize_gas", initNo);
        emit log_named_uint("full_yes_runtime_bytes", fullYesBytes);
        emit log_named_uint("full_no_runtime_bytes", fullNoBytes);
        emit log_named_uint("clone_implementation_runtime_bytes", implementationBytes);
        emit log_named_uint("clone_runtime_bytes", cloneYesBytes);
        emit log_named_uint("outcome_token_creation_code_bytes", type(OutcomeToken).creationCode.length);
        emit log_named_uint("cloneable_creation_code_bytes", type(CloneableOutcomeToken).creationCode.length);
        emit log_named_uint("full_pair_gas", fullYes + fullNo);
        emit log_named_uint("clone_pair_gas", implementationGas + cloneYes + initYes + cloneNo + initNo);

        assertGt(fullYes, 30_000);
        assertLt(cloneYes + initYes, fullYes);
        assertLt(cloneNo + initNo, fullNo);
        assertLt(implementationGas + cloneYes + initYes + cloneNo + initNo, fullYes + fullNo);
        assertEq(CloneableOutcomeToken(yesClone).decimals(), 6);
        assertEq(CloneableOutcomeToken(noClone).decimals(), 18);
        assertEq(CloneableOutcomeToken(yesClone).outcomeIndex(), 0);
        assertEq(CloneableOutcomeToken(noClone).outcomeIndex(), 1);
        assertEq(cloneYesBytes, 45);
    }

    function test_immutable_outcome_token_clone_shares_identity() public {
        OutcomeToken implementation = new OutcomeToken(address(this), 0, "Yes", "YES", 6);
        OutcomeToken cloned = OutcomeToken(ERC1167.clone(address(implementation)));
        assertEq(cloned.market(), implementation.market());
        assertEq(cloned.outcomeIndex(), implementation.outcomeIndex());
        assertEq(cloned.decimals(), implementation.decimals());
        assertEq(cloned.name(), "");
        assertEq(cloned.symbol(), "");
        emit log_named_uint("immutable_clone_runtime_bytes", address(cloned).code.length);
        assertEq(address(cloned).code.length, 45);
        assertEq(cloned.outcomeIndex(), 0);
    }

    function test_storage_clone_initializer_cannot_replay() public {
        CloneableOutcomeToken implementation = new CloneableOutcomeToken();
        CloneableOutcomeToken cloned = CloneableOutcomeToken(ERC1167.clone(address(implementation)));
        cloned.initialize(address(0xA11CE), 1, "No", "NO", 18);
        assertEq(cloned.market(), address(0xA11CE));
        assertEq(cloned.outcomeIndex(), 1);
        assertEq(cloned.decimals(), 18);
        vm.expectRevert(CloneableOutcomeToken.AlreadyInitialized.selector);
        cloned.initialize(address(0xBEEF), 0, "Yes", "YES", 6);
        assertEq(cloned.market(), address(0xA11CE));
        assertEq(cloned.outcomeIndex(), 1);
    }

    function test_storage_clone_moves_balances_only_through_its_market() public {
        CloneableOutcomeToken implementation = new CloneableOutcomeToken();
        CloneableOutcomeToken cloned = CloneableOutcomeToken(ERC1167.clone(address(implementation)));
        address market = address(0xA11CE);
        cloned.initialize(market, 1, "No", "NO", 18);
        vm.prank(address(0xBEEF));
        vm.expectRevert(CloneableOutcomeToken.NotMarket.selector);
        cloned.mint(market, 5);
        vm.prank(market);
        cloned.mint(market, 5);
        vm.prank(market);
        assertTrue(cloned.transfer(address(0xBEEF), 2));
        vm.prank(address(0xBEEF));
        assertTrue(cloned.approve(market, 1));
        vm.prank(market);
        assertTrue(cloned.transferFrom(address(0xBEEF), address(0xCAFE), 1));
        vm.prank(address(0xBEEF));
        vm.expectRevert(CloneableOutcomeToken.NotMarket.selector);
        cloned.burn(market, 1);
        vm.prank(market);
        cloned.burn(market, 3);
        assertEq(cloned.balanceOf(market), 0);
        assertEq(cloned.balanceOf(address(0xBEEF)), 1);
        assertEq(cloned.balanceOf(address(0xCAFE)), 1);
        assertEq(cloned.totalSupply(), 2);
    }
}
