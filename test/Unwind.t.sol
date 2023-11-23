// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.21 <0.9.0;

import { console2 } from "forge-std/console2.sol";
import { StdCheats } from "forge-std/StdCheats.sol";
import { PRBTest } from "lib/prb-test/src/PRBTest.sol";
import { ERC20, IJoin, IPool, IStrategy, IStrategyV1, ICauldron, ILadle, DataTypes, Unwind } from "../src/Unwind.sol";

/// @dev If this is your first time with Forge, read this tutorial in the Foundry Book:
/// https://book.getfoundry.sh/forge/writing-tests
contract UnwindTest is PRBTest, StdCheats {
    error UnknownChain(uint256 chainId);
    error UnknownAddress(address target);
    error MustUpgradeStrategy(address strategy);
    error NotEnoughAllowance(address target);
    error StuckStrategy(address strategy);
    error NotLiquidityAddress(address target);

    Unwind internal unwind;

    /// @dev A function invoked before each test case is run.
    function setUp() public virtual {
        // Instantiate the contract-under-test.
        unwind = new Unwind();
    }


    /// @dev Test that we tell the users what to do with their tokens
    function test_WhatNext() external {
        for (uint i = 0; i < unwind.knownContractsLength(); i++) {
            address target = unwind.knownContracts(i);

            deal(target, address(this), 1);
            (string memory action, address targetOut) = unwind.whatNext();
            ERC20(target).transfer(address(0),1);
                
            assertEq(target, targetOut);
            console2.log("%s (%s): %s", target, ERC20(target).name(), action);
        }

        // Test that we don't tell users to do anything with the tokens that are not in the list
        address target = address(0);
        (string memory action, address targetOut) = unwind.whatNext();
        assertEq(target, targetOut);
        console2.log("%s: %s", target, action);
    }

    /// @dev Test that the total supply of all pools can be burned, or give a reason of why not
    function test_removePoolLiquidity() external {
        for (uint i = 0; i < unwind.knownContractsLength(); i++) {
            address target = unwind.knownContracts(i);
            if (unwind.contractTypes(target) == Unwind.Type.POOL) {

                // We test burning the entire supply of the pool, and then we check we obtained all the reserves.
                // We don't need to test that the pool calculates amounts correctly, because that's already tested in the pool tests.
                uint256 totalSupply = ERC20(target).totalSupply();
                if (totalSupply == 0) continue; // Skip empty pools

                ERC20 base = ERC20(address(IPool(target).base()));
                ERC20 fyToken = ERC20(address(IPool(target).fyToken()));
                uint256 baseBalance = base.balanceOf(address(this));
                uint256 fyTokenBalance = fyToken.balanceOf(address(this));
                uint256 baseInPool = base.balanceOf(address(target));
                uint256 fyTokenInPool = fyToken.balanceOf(address(target));
                
                deal(target, address(this), totalSupply);
                ERC20(target).approve(address(unwind), type(uint256).max);
                unwind.removeLiquidity(target);
                
                assertEq(base.balanceOf(address(this)), baseBalance + baseInPool);
                assertEq(fyToken.balanceOf(address(this)), fyTokenBalance + fyTokenInPool);
                console2.log("%s: Burned %s", ERC20(target).name(), totalSupply);
                console2.log("%s: Obtained %s %s", ERC20(target).name(), base.balanceOf(address(this)) - baseBalance, base.name());
                console2.log("%s: Obtained %s %s", ERC20(target).name(), fyToken.balanceOf(address(this)) - fyTokenBalance, fyToken.name());
            }
        }
    }

    /// @dev Test that the total supply of all v2 strategies can be burned, or give a reason of why not
    function test_removeStrategyV2Liquidity() external {
        for (uint i = 0; i < unwind.knownContractsLength(); i++) {
            address target = unwind.knownContracts(i);
            if (unwind.contractTypes(target) == Unwind.Type.STRATEGYV2) {

                // We test burning the entire supply of the strategy, and then we check we obtained all the reserves.
                // We don't need to test that the strategy calculates amounts correctly, because that's already tested in the strategy tests.
                uint256 totalSupply = ERC20(target).totalSupply();
                ERC20 base = ERC20(address(IStrategy(target).pool()));
                if (address(base) == address(0)) base = ERC20(address(IStrategy(target).base())); // In case the strategy is divested
                uint256 baseBalance = base.balanceOf(address(this));
                uint256 baseInStrategy = base.balanceOf(address(target));
                
                deal(target, address(this), totalSupply);
                ERC20(target).approve(address(unwind), type(uint256).max);
                unwind.removeLiquidity(target);

                assertEq(base.balanceOf(address(this)), baseBalance + baseInStrategy);
                console2.log("%s: Burned %s", ERC20(target).name(), totalSupply);
                console2.log("%s: Obtained %s %s", ERC20(target).name(), base.balanceOf(address(this)) - baseBalance, base.name());
            }
        }
    }


    /// @dev Test that the total supply of all v1 strategies can be burned, or give a reason of why not
    function test_removeStrategyV1Liquidity() external {
        for (uint i = 0; i < unwind.knownContractsLength(); i++) {
            address target = unwind.knownContracts(i);
            if (unwind.contractTypes(target) == Unwind.Type.STRATEGYV1) {

                // We test burning the entire supply of the strategy, and then we check we obtained all the reserves.
                // We don't need to test that the strategy calculates amounts correctly, because that's already tested in the strategy tests.
                uint256 totalSupply = ERC20(target).totalSupply();
                ERC20 base = ERC20(address(IStrategyV1(target).pool()));
                uint256 baseBalance = base.balanceOf(address(this));
                uint256 baseInStrategy = base.balanceOf(address(target));
                
                deal(target, address(this), totalSupply);
                ERC20(target).approve(address(unwind), type(uint256).max);
                unwind.removeLiquidity(target);

                assertEq(base.balanceOf(address(this)), baseBalance + baseInStrategy);
                console2.log("%s: Burned %s", ERC20(target).name(), totalSupply);
                console2.log("%s: Obtained %s %s", ERC20(target).name(), base.balanceOf(address(this)) - baseBalance, base.name());
            }
        }
    }
}
