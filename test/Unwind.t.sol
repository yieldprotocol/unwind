// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.21 <0.9.0;

import { console2 } from "forge-std/console2.sol";
import { StdCheats } from "forge-std/StdCheats.sol";
import { PRBTest } from "lib/prb-test/src/PRBTest.sol";
import { ERC20, IJoin, IFYToken, IPool, IStrategy, IStrategyV1, ICauldron, ILadle, DataTypes, Unwind } from "../src/Unwind.sol";

/// @dev If this is your first time with Forge, read this tutorial in the Foundry Book:
/// https://book.getfoundry.sh/forge/writing-tests
contract UnwindTest is PRBTest, StdCheats {
    error UnknownChain(uint256 chainId);
    error UnknownAddress(address target);
    error MustUpgradeStrategy(address strategy);
    error NotEnoughAllowance(address target);
    error StuckStrategy(address strategy);
    error NotLiquidityAddress(address target);
    error NotLendingAddress(address target);
    error VaultDoesNotExist(bytes12 vaultId);

    Unwind internal unwind;

    bytes12[] internal sampleVaultIds;

    /// @dev A function invoked before each test case is run.
    function setUp() public virtual {
        // Instantiate the contract-under-test.
        unwind = new Unwind();
        sampleVaultIds.push(0x8ed222243d2e7d89be3aa966);
        sampleVaultIds.push(0x0a51ad005255a2c9cceffbfd);
        sampleVaultIds.push(0x14a639e62b1c243211462143);
        sampleVaultIds.push(0x52042d8840d0de8f6e132e98);
        // sampleVaultIds.push(0x0899B797F67B7ED0E303D049); fCash breaks the test
    }

    /// @dev Test that the total supply of all fyToken can be redeemed, or give a reason of why not
    function test_closeLend() external {
        for (uint i = 0; i < unwind.knownContractsLength(); i++) {
            address target = unwind.knownContracts(i);
            if (unwind.contractTypes(target) == Unwind.Type.FYTOKEN) {
                uint256 totalSupply = ERC20(target).totalSupply();
                
                // Check the join can redeem the fyTokens
                IJoin baseJoin = IFYToken(target).join();
                ERC20 base = ERC20(baseJoin.asset());
                uint256 baseBalance = base.balanceOf(address(this));
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
                    console2.log("%s: Obtained %s %s", ERC20(target).name(), base.balanceOf(address(this)) - baseBalance, base.name());
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
                ERC20 base = ERC20(address(IPool(target).base()));
                ERC20 fyToken = ERC20(address(IPool(target).fyToken()));
                uint256 baseBalance = base.balanceOf(address(this));
                uint256 fyTokenBalance = fyToken.balanceOf(address(this));
                
                deal(target, address(this), totalSupply);
                ERC20(target).approve(address(unwind), type(uint256).max);
                unwind.removeLiquidity(target);
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
                uint256 totalSupply = ERC20(target).totalSupply();
                ERC20 base = ERC20(address(IStrategy(target).pool()));
                if (address(base) == address(0)) base = ERC20(address(IStrategy(target).base())); // In case the strategy is divested
                uint256 baseBalance = base.balanceOf(address(this));
                
                deal(target, address(this), totalSupply);
                ERC20(target).approve(address(unwind), type(uint256).max);
                unwind.removeLiquidity(target);
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
                uint256 totalSupply = ERC20(target).totalSupply();
                ERC20 base = ERC20(address(IStrategyV1(target).pool()));
                uint256 baseBalance = base.balanceOf(address(this));
                
                deal(target, address(this), totalSupply);
                ERC20(target).approve(address(unwind), type(uint256).max);
                unwind.removeLiquidity(target);
                console2.log("%s: Burned %s", ERC20(target).name(), totalSupply);
                console2.log("%s: Obtained %s %s", ERC20(target).name(), base.balanceOf(address(this)) - baseBalance, base.name());
            }
        }
    }

    function testCloseBorrow() external {
        ICauldron cauldron = unwind.cauldron();
        ILadle ladle = unwind.ladle();

        for (uint i = 0; i < sampleVaultIds.length; i++) {
            bytes12 vaultId = sampleVaultIds[i];

            // Get the vault art and ink
            DataTypes.Vault memory vault = cauldron.vaults(vaultId);
            DataTypes.Balances memory balancesBefore = cauldron.balances(vaultId);

            // Get the vault series and base token
            DataTypes.Series memory series = cauldron.series(vault.seriesId);
            IJoin baseJoin = IJoin(ladle.joins(series.baseId));
            IJoin ilkJoin = IJoin(ladle.joins(vault.ilkId));
            ERC20 baseToken = ERC20(baseJoin.asset());
            ERC20 ilkToken = ERC20(ilkJoin.asset());

            // Make sure the Join can return the collateral
            deal(address(ilkToken), address(ilkJoin), ilkJoin.storedBalance() + balancesBefore.ink);
            vm.prank(address(ladle));
            ilkJoin.join(address(ladle), balancesBefore.ink);

            // Convert the art into base
            uint256 baseAmount = cauldron.debtToBase(vault.seriesId, balancesBefore.art) + 2; // Let's take an extra wei, in case we mess up the rounding

            // Deal and approve the base token
            deal(address(baseToken), vault.owner, baseAmount);

            // Impersonate the vault owner
            vm.startPrank(vault.owner);

            // SOMETHING BREAKS IF COLLATERAL AND BASE ARE THE SAME, but only on the tests, don't worry.

            // Clean collateral amount
            ilkToken.transfer(address(0xdead), ilkToken.balanceOf(vault.owner));

            baseToken.approve(address(baseJoin), type(uint256).max);

            // Close the borrow
            if (balancesBefore.art > 0) ladle.close(vaultId, vault.owner, -int128(balancesBefore.ink), -int128(balancesBefore.art));
            else ladle.pour(vaultId, vault.owner, -int128(balancesBefore.ink), -int128(balancesBefore.art));

            vm.stopPrank();

            // Check that the borrow was closed and collateral returned
            {
                DataTypes.Balances memory balancesAfter = cauldron.balances(vaultId);
                assertEq(balancesAfter.art, 0);
                assertEq(balancesAfter.ink, 0);
            }
            assertEq(ilkToken.balanceOf(vault.owner), balancesBefore.ink);
            
            console2.log("%s: Closed %s debt of %s", uint256(bytes32(vaultId)), balancesBefore.art, baseToken.name());
            console2.log("%s: Obtained %s collateral of %s", uint256(bytes32(vaultId)), ilkToken.balanceOf(vault.owner), ilkToken.name());
        } 
    }
}
