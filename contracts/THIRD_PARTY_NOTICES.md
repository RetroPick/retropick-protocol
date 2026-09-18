# Third Party Notices

This project incorporates code from several open source projects under their respective licenses.

## OpenZeppelin Contracts

**License:** MIT  
**Source:** https://github.com/OpenZeppelin/openzeppelin-contracts  
**Files:** 20 files under `lib/openzeppelin-contracts/contracts/`

Used contracts include:
- `access/Ownable.sol`, `access/Ownable2Step.sol`
- `token/ERC20/ERC20.sol`, `token/ERC20/IERC20.sol`, `token/ERC20/extensions/ERC20Burnable.sol`, `token/ERC20/extensions/IERC20Metadata.sol`, `token/ERC20/utils/SafeERC20.sol`
- `token/ERC721/IERC721.sol`
- `utils/ReentrancyGuard.sol`, `utils/Context.sol`, `utils/StorageSlot.sol`, `utils/Panic.sol`
- `utils/math/Math.sol`, `utils/math/SafeCast.sol`
- `utils/introspection/IERC165.sol`
- `interfaces/IERC20.sol`, `interfaces/IERC20Metadata.sol`, `interfaces/IERC165.sol`, `interfaces/IERC1363.sol`, `interfaces/draft-IERC6093.sol`

See `licenses/OPENZEPPELIN-MIT.txt` for full license text.

## Uniswap V4 Core

**License:** MIT + BUSL-1.1  
**Source:** https://github.com/Uniswap/v4-core  
**Files:** 34 files under `lib/v4-core/src/`

**MIT Licensed files include:**
- All interfaces under `interfaces/`
- Most libraries under `libraries/`  
- All types under `types/`

**BUSL-1.1 Licensed files:**
- `libraries/Pool.sol`
- `libraries/Position.sol`

See `licenses/UNISWAP-V4-MIT.txt` and `licenses/UNISWAP-V4-BUSL-1.1.txt` for full license texts.

**⚠️ BUSL-1.1 Deployment Notice:** The `Pool.sol` and `Position.sol` files are licensed under BUSL-1.1 with Additional Use Grant. Production deployment rights require separate legal review.

## Uniswap V4 Periphery

**License:** MIT  
**Source:** https://github.com/Uniswap/v4-periphery  
**Files:** 15 files under `lib/v4-periphery/src/`

Used components:
- Interfaces: `IPositionManager.sol`, `INotifier.sol`, `ISubscriber.sol`, etc.
- Libraries: `Actions.sol`, `LiquidityAmounts.sol`, `PositionInfoLibrary.sol`
- Base contracts: `ImmutableState.sol`

See `licenses/UNISWAP-V4-MIT.txt` for full license text.

## Permit2

**License:** MIT  
**Source:** https://github.com/Uniswap/permit2  
**Files:** 1 file under `lib/v4-periphery/lib/permit2/src/`

Used interfaces:
- `interfaces/IAllowanceTransfer.sol`
- `interfaces/IEIP712.sol`

See `licenses/PERMIT2-MIT.txt` for full license text.

## v4-hooks-public

**License:** MIT (assumed)  
**Source:** Unknown upstream project  
**Files:** 1 file under `lib/v4-hooks-public/src/`

Used components:
- `base/BaseHook.sol`

**Note:** Exact upstream project for v4-hooks-public could not be determined. SPDX header indicates MIT license.

See `licenses/V4-HOOKS-PUBLIC-MIT.txt` for preserved license text.

## License Compliance

All SPDX license headers in source files have been preserved unchanged. Required license texts are provided in the `licenses/` directory.

**Deployment Rights:** Production deployment requires separate legal review, particularly for BUSL-1.1 licensed components.