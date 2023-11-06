// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.21 <0.9.0;

import { console2 } from "forge-std/console2.sol";
import { StdCheats } from "forge-std/StdCheats.sol";

import { ERC20, IJoin, IFYToken, ILadle, Unwind } from "../src/Unwind.sol";

/// @dev If this is your first time with Forge, read this tutorial in the Foundry Book:
/// https://book.getfoundry.sh/forge/writing-tests
contract UnwindTest is StdCheats {
    error UnknownChain(uint256 chainId);
    error UnknownAddress(address target);
    error MustUpgradeStrategy(address strategy);
    error NotEnoughAllowance(address target);
    error StuckStrategy(address strategy);
    error NotLiquidityAddress(address target);
    error NotLendingAddress(address target);
    error VaultDoesNotExist(bytes12 vaultId);

    Unwind internal unwind;

    /// @dev A function invoked before each test case is run.
    function setUp() public virtual {
        // Instantiate the contract-under-test.
        unwind = new Unwind();
    }

    /// @dev Test that the total supply of all fyToken can be redeemed, or give a reason of why not
    function test_closeLend() external {
        for (uint i = 0; i < unwind.knownContractsLength(); i++) {
            address target = unwind.knownContracts(i);
            if (unwind.contractTypes(target) == Unwind.Type.FYTOKEN) {
                uint256 totalSupply = ERC20(target).totalSupply();
                
                // Check the join can redeem the fyTokens
                IJoin baseJoin = IFYToken(target).join();
                uint256 joinBalance = baseJoin.storedBalance();
                if (joinBalance < totalSupply) {
                    console2.log("%s: Not enough join balance to redeem %s", ERC20(target).name(), totalSupply);
                } else if (IFYToken(target).maturity() > block.timestamp) {
                    console2.log("%s: Not mature yet, wait until %s", ERC20(target).name(), IFYToken(target).maturity());
                } else {
                    deal(target, address(this), totalSupply);
                    ERC20(target).approve(address(unwind), type(uint256).max);
                    unwind.closeLend(target);
                    console2.log("%s: Redeemed %s", ERC20(target).name(), totalSupply);
                }
            }
        }
    }



    /// @dev Test that the total supply of all pools can be burned, or give a reason of why not
    function test_removePoolLiquidity() external {
        for (uint i = 0; i < unwind.knownContractsLength(); i++) {
            address target = unwind.knownContracts(i);
            if (unwind.contractTypes(target) == Unwind.Type.POOL) {
                uint256 totalSupply = ERC20(target).totalSupply();
                
                deal(target, address(this), totalSupply);
                ERC20(target).approve(address(unwind), type(uint256).max);
                unwind.removeLiquidity(target);
                console2.log("%s: Burned %s", ERC20(target).name(), totalSupply);
            }
        }
    }
// 
//     /// @dev Fuzz test that provides random values for an unsigned integer, but which rejects zero as an input.
//     /// If you need more sophisticated input validation, you should use the `bound` utility instead.
//     /// See https://twitter.com/PaulRBerg/status/1622558791685242880
//     function testFuzz_Example(uint256 x) external {
//         vm.assume(x != 0); // or x = bound(x, 1, 100)
//         assertEq(foo.id(x), x, "value mismatch");
//     }
// 
//     /// @dev Fork test that runs against an Ethereum Mainnet fork. For this to work, you need to set `API_KEY_ALCHEMY`
//     /// in your environment You can get an API key for free at https://alchemy.com.
//     function testFork_Example() external {
//         // Silently pass this test if there is no API key.
//         string memory alchemyApiKey = vm.envOr("API_KEY_ALCHEMY", string(""));
//         if (bytes(alchemyApiKey).length == 0) {
//             return;
//         }
// 
//         // Otherwise, run the test against the mainnet fork.
//         vm.createSelectFork({ urlOrAlias: "mainnet", blockNumber: 16_428_000 });
//         address usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
//         address holder = 0x7713974908Be4BEd47172370115e8b1219F4A5f0;
//         uint256 actualBalance = ERC20(usdc).balanceOf(holder);
//         uint256 expectedBalance = 196_307_713.810457e6;
//         assertEq(actualBalance, expectedBalance);
//     }
}
