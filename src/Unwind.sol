// SPDX-License-Identifier: UNLICENSED
// Audit: https://github.com/christos-eth/Unwind-audit/issues/2

pragma solidity ^0.8.21;

import { ERC20 } from "lib/yield-utils-v2/src/token/ERC20.sol";
import { IPool } from "lib/yieldspace-tv/src/interfaces/IPool.sol";
import { IStrategy } from "lib/strategy-v2/src/interfaces/IStrategy.sol";
import { IStrategyV1 } from "lib/strategy-v2/src/deprecated/IStrategyV1.sol";
import { IJoin } from "lib/vault-v2/src/interfaces/IJoin.sol";
import { DataTypes } from "lib/vault-v2/src/interfaces/DataTypes.sol";
import { ICauldron } from "lib/vault-v2/src/interfaces/ICauldron.sol";
import { ILadle } from "lib/vault-v2/src/interfaces/ILadle.sol";


/// @dev Unwind is a contract that allows users to remove liquidity from pools and strategies, despite
/// the forward-trust pattern that requires prior transfer of tokens.
/// https://hackernoon.com/using-the-forward-trust-design-pattern-to-make-scaling-easier
contract Unwind {
    enum Type {
        UNKNOWN,
        POOL,
        STRATEGYV2,
        STRATEGYV1,
        STRATEGYUPGRADE
    }

    error UnknownChain(uint256 chainId);
    error UnknownAddress(address target);
    error MustUpgradeStrategy(address strategy);
    error NotEnoughAllowance(address target);
    error StuckStrategy(address strategy);
    error NotLiquidityAddress(address target);
    error NoBalance(address target);

    address[] public knownContracts;
    mapping(address => Type) public contractTypes; // Surely I could do magic and do a read-only storage mapping, but not worth the effort and complexity this time.

    ICauldron public immutable cauldron;
    ILadle public immutable ladle;

    // @dev Push into storage all the known addresses and their types.
    constructor () {
        address current;
        if (block.chainid == 1) {
            ladle = ILadle(0x6cB18fF2A33e981D1e38A663Ca056c0a5265066A);
            cauldron = ICauldron(0xc88191F8cb8e6D4a668B047c1C8503432c3Ca867);

            // The following pools were affected by the Euler hack and can't be operated with:
            // 0x9D34dF69958675450ab8E53c8Df5531203398Dc9
            // 0x52956Fb3DC3361fd24713981917f2B6ef493DCcC
            // 0xB2fff7FEA1D455F0BCdd38DA7DeE98af0872a13a
            // 0x1b2145139516cB97568B76a2FdbE37D2BCD61e63
            // 0xBdc7Bdae87dfE602E91FDD019c4C0334C38f6A46
            // 0x48b95265749775310B77418Ff6f9675396ABE1e8
            // 0xD129B0351416C75C9f0623fB43Bb93BB4107b2A4
            // 0xC2a463278387e649eEaA5aE5076e283260B0B1bE
            // 0x06aaF385809c7BC00698f1E266eD4C78d6b8ba75
            // 0x7472DF92Ae587f97939de92bDFC23dbaCD8a3816
            // 0xB4DbEc738Ffe47981D337C02Cb5746E456ecd505

            current = 0x6BaC09a67Ed1e1f42c29563847F77c28ec3a04FC; knownContracts.push(current); contractTypes[current] = Type.POOL;
            current = 0xf5Fd5A9Db9CcCc6dc9f5EF1be3A859C39983577C; knownContracts.push(current); contractTypes[current] = Type.POOL;
            current = 0x341B0976F962eC34eEaF31cdF2464Ab3B15B6301; knownContracts.push(current); contractTypes[current] = Type.POOL;
            current = 0xc3348D8449d13C364479B1F114bcf5B73DFc0dc6; knownContracts.push(current); contractTypes[current] = Type.POOL;
            current = 0xA4d45197E3261721B8A8d901489Df5d4D2E79eD7; knownContracts.push(current); contractTypes[current] = Type.POOL;
            current = 0x4b32C37Be5949e77ba3726E863a030BD77942A97; knownContracts.push(current); contractTypes[current] = Type.POOL;
            current = 0xFa38F3717daD95085FF725aA93608Af3fa1D9e58; knownContracts.push(current); contractTypes[current] = Type.POOL;
            current = 0x1D2eB98042006B1bAFd10f33743CcbB573429daa; knownContracts.push(current); contractTypes[current] = Type.POOL;
            current = 0x2E8F62e3620497DbA8A2D7A18EA8212215805F22; knownContracts.push(current); contractTypes[current] = Type.POOL; // No balance
            current = 0x60995D90B45169eB04F1ea9463443a62B83ab1c1; knownContracts.push(current); contractTypes[current] = Type.POOL; // No balance
            current = 0x0bdF152f6d899F4B63b9554ED98D9b9d22FFdee4; knownContracts.push(current); contractTypes[current] = Type.POOL; // No balance
            current = 0xaCd0523Aca72CC58EC2f3d4C14F5473FC11c5C2D; knownContracts.push(current); contractTypes[current] = Type.POOL; // No balance
            current = 0x6E38B8d9dedd967961508708183678b4EC1B1E33; knownContracts.push(current); contractTypes[current] = Type.POOL; // No balance
            current = 0xE56c9c47b271A58e5856004952c5F4D34a78B99B; knownContracts.push(current); contractTypes[current] = Type.POOL;
            current = 0x9ce9c9f9fF417Ffc215A4e5c6b4e44BB76Cf8C79; knownContracts.push(current); contractTypes[current] = Type.POOL;
            current = 0xFCd1C61139F8Af13c5090CfBb2dD674a2Ff4fe35; knownContracts.push(current); contractTypes[current] = Type.POOL;
            current = 0x0ECc79FE01b02548853c87466cCd57710bf9d11A; knownContracts.push(current); contractTypes[current] = Type.POOL;
            current = 0xe2F6f40192F3E4568a62577E0541AC823b6f0D9e; knownContracts.push(current); contractTypes[current] = Type.POOL; // No balance
            current = 0xB9345c19291bB073b0E6483048fAFD0986AB82dF; knownContracts.push(current); contractTypes[current] = Type.POOL;
            current = 0x14132D979fDdA62a56d9f552C9aa477b9c94851e; knownContracts.push(current); contractTypes[current] = Type.POOL;
            current = 0x3667362C4B666B952383eDBE12fC9cC108D09cD7; knownContracts.push(current); contractTypes[current] = Type.POOL;
            current = 0x9acbc758B9f06F9ad9AA5DdB6C42B5b0375B5B6c; knownContracts.push(current); contractTypes[current] = Type.POOL;
            current = 0xcf30A5A994f9aCe5832e30C138C9697cda5E1247; knownContracts.push(current); contractTypes[current] = Type.STRATEGYV1;
            current = 0x7ACFe277dEd15CabA6a8Da2972b1eb93fe1e2cCD; knownContracts.push(current); contractTypes[current] = Type.STRATEGYV1;
            current = 0xFBc322415CBC532b54749E31979a803009516b5D; knownContracts.push(current); contractTypes[current] = Type.STRATEGYV1;
            current = 0x1565F539E96c4d440c38979dbc86Fd711C995DD6; knownContracts.push(current); contractTypes[current] = Type.STRATEGYV1;
            current = 0x1144e14E9B0AA9e181342c7e6E0a9BaDB4ceD295; knownContracts.push(current); contractTypes[current] = Type.STRATEGYV1;
            current = 0xbD6277E36686184A5343F83a4be5CeD0f8CD185A; knownContracts.push(current); contractTypes[current] = Type.STRATEGYV1;
            current = 0x831dF23f7278575BA0b136296a285600cD75d076; knownContracts.push(current); contractTypes[current] = Type.STRATEGYV1;
            current = 0x8e8D6aB093905C400D583EfD37fbeEB1ee1c0c39; knownContracts.push(current); contractTypes[current] = Type.STRATEGYV1;
            current = 0xF708005ceE17b2c5Fe1a01591E32ad6183A12EaE; knownContracts.push(current); contractTypes[current] = Type.STRATEGYUPGRADE;
            current = 0xb268E2C85861B74ec75fe728Ae40D9A2308AD9Bb; knownContracts.push(current); contractTypes[current] = Type.STRATEGYUPGRADE;
            current = 0x9ca2a34ea52bc1264D399aCa042c0e83091FEECe; knownContracts.push(current); contractTypes[current] = Type.STRATEGYUPGRADE;
            current = 0x5dd6DcAE25dFfa0D46A04C9d99b4875044289fB2; knownContracts.push(current); contractTypes[current] = Type.STRATEGYUPGRADE;
            current = 0x428e229aC5BC52a2e07c379B2F486fefeFd674b1; knownContracts.push(current); contractTypes[current] = Type.STRATEGYUPGRADE;
            current = 0x4B010fA49E8b673D0682CDeFCF7834328076748C; knownContracts.push(current); contractTypes[current] = Type.STRATEGYV2; // FRAX - DIVESTED
            current = 0xDa072f54cDB9100e62FDE31c60fbEe555dc43a76; knownContracts.push(current); contractTypes[current] = Type.STRATEGYV2;
            current = 0xAB4a4bDE7C182e47339BB9920212851CEAE0eAA1; knownContracts.push(current); contractTypes[current] = Type.STRATEGYV2;
            current = 0xeDa2fEc6953b90aA163C2737AEf9a731B44CE17b; knownContracts.push(current); contractTypes[current] = Type.STRATEGYV2;
            current = 0x87df4c7E6E8E76ba82C4C239261A8D070576E76F; knownContracts.push(current); contractTypes[current] = Type.STRATEGYV2;
            current = 0x3AE72b6F5Fb854eaa2B2b862359B6fCA7e4bC2fc; knownContracts.push(current); contractTypes[current] = Type.STRATEGYV2;
            current = 0x160bF035154858FAEE3EE2d4592e5393d259c3A6; knownContracts.push(current); contractTypes[current] = Type.STRATEGYV2;
            current = 0xa874c4dF3CAA250307C0351AAa13d3d20f70c321; knownContracts.push(current); contractTypes[current] = Type.STRATEGYV2;
            current = 0xE7C82f5964b810B6AE01ab116991D5E110C846f5; knownContracts.push(current); contractTypes[current] = Type.STRATEGYV2;
            current = 0x93dEe161a396aF75c7458a65687895299bFeB437; knownContracts.push(current); contractTypes[current] = Type.STRATEGYV2; // FRAX - DIVESTED
        } else if (block.chainid == 42161) {
            ladle = ILadle(0x16E25cf364CeCC305590128335B8f327975d0560);
            cauldron = ICauldron(0x23cc87FBEBDD67ccE167Fa9Ec6Ad3b7fE3892E30);
            current = 0x7Fc2c417021d46a4790463030Fb01A948D54Fc04; knownContracts.push(current); contractTypes[current] = Type.POOL;
            current = 0xf76906AA78ECD4FcFB8a7923fB40fA42c07F20D6; knownContracts.push(current); contractTypes[current] = Type.POOL;
            current = 0x6651f8E1ff6863Eb366a319F9A94191346D0e323; knownContracts.push(current); contractTypes[current] = Type.POOL;
            current = 0x8C8A448FD8d3e44224d97146B25F4DeC425af309; knownContracts.push(current); contractTypes[current] = Type.POOL;
            current = 0x25e46aD1cC867c5253a179F45e1aB46144c8aBc0; knownContracts.push(current); contractTypes[current] = Type.POOL;
            current = 0x81Ae3D05e4F0d0DD29d6840424a0b761A7fdB51c; knownContracts.push(current); contractTypes[current] = Type.POOL;
            current = 0x7F0dD461D77F84cDd3ceD46F9D550e35F1969a24; knownContracts.push(current); contractTypes[current] = Type.POOL;
            current = 0x79A6Be1Ae54153AA6Fc7e4795272c63F63B2a6DC; knownContracts.push(current); contractTypes[current] = Type.POOL;
            current = 0x22E1e5337C5BA769e98d732518b2128dE14b553C; knownContracts.push(current); contractTypes[current] = Type.POOL;
            current = 0x2eb907fb4b71390dC5CD00e6b81B7dAAcE358193; knownContracts.push(current); contractTypes[current] = Type.POOL;
            current = 0xb268E2C85861B74ec75fe728Ae40D9A2308AD9Bb; knownContracts.push(current); contractTypes[current] = Type.POOL;
            current = 0x3e0a639c4a6D4d39a0DeAE07c228Ff080de55eeE; knownContracts.push(current); contractTypes[current] = Type.POOL;
            current = 0x54D47f765fA247AfEE226fDf919392CdaC6cbb2E; knownContracts.push(current); contractTypes[current] = Type.POOL;
            current = 0xB71dB5f70FE5Af728Db8C05930d48553E5a0eB98; knownContracts.push(current); contractTypes[current] = Type.POOL;
            current = 0xbc62d88182ffA86918d0129f5bD35Dea8df9213a; knownContracts.push(current); contractTypes[current] = Type.POOL;
            current = 0x530648558a27fe1d1BfC7356F67a34f4a7f06B6D; knownContracts.push(current); contractTypes[current] = Type.POOL;
            current = 0xf7F6eB1b097F60673e65347C83d83Cb4ade82a0B; knownContracts.push(current); contractTypes[current] = Type.POOL;
            current = 0x7388f277441b3E1f3388f0464244e469fEA30e41; knownContracts.push(current); contractTypes[current] = Type.POOL;
            current = 0x1EEc5ED8E01E0232F5ab2D70bB00231250aB2e7A; knownContracts.push(current); contractTypes[current] = Type.POOL;
            current = 0xf6c1bD232b1D6de368de2BbeD096D821F0596c28; knownContracts.push(current); contractTypes[current] = Type.POOL;
            current = 0xCF275fDd705B321789cD046694cEBbF678c45FA3; knownContracts.push(current); contractTypes[current] = Type.POOL;
            current = 0x1CD29A42882c163BaD7a7C0124C3195a0584C518; knownContracts.push(current); contractTypes[current] = Type.POOL;
            current = 0xA73ba15B76a165a4dB56ef71B46D695A751334b6; knownContracts.push(current); contractTypes[current] = Type.POOL;
            current = 0xD5B43b2550751d372025d048553352ac60f27151; knownContracts.push(current); contractTypes[current] = Type.STRATEGYV1;
            current = 0xE779cd75E6c574d83D3FD6C92F3CBE31DD32B1E1; knownContracts.push(current); contractTypes[current] = Type.STRATEGYV1;
            current = 0x92A5B31310a3ED4546e0541197a32101fCfBD5c8; knownContracts.push(current); contractTypes[current] = Type.STRATEGYV1;
            current = 0xa3cAF61FD23d374ce13c742E4E9fA9FAc23Ddae6; knownContracts.push(current); contractTypes[current] = Type.STRATEGYV1;
            current = 0x54F08092e3256131954dD57C04647De8b2E7A9a9; knownContracts.push(current); contractTypes[current] = Type.STRATEGYV1;
            current = 0x3353E1E2976DBbc191a739871faA8E6E9D2622c7; knownContracts.push(current); contractTypes[current] = Type.STRATEGYV1;
            current = 0xad1983745D6c739537fEaB5bed45795f47A940b3; knownContracts.push(current); contractTypes[current] = Type.STRATEGYUPGRADE;
            current = 0x5582b8398FB586F1b79edd1a6e83f1c5aa558955; knownContracts.push(current); contractTypes[current] = Type.STRATEGYUPGRADE;
            current = 0x4276BEaA49DE905eED06FCDc0aD438a19D3861DD; knownContracts.push(current); contractTypes[current] = Type.STRATEGYUPGRADE;
            current = 0x5aeB4EFaAA0d27bd606D618BD74Fe883062eAfd0; knownContracts.push(current); contractTypes[current] = Type.STRATEGYUPGRADE;
            current = 0x33e6B154efC7021dD55464c4e11a6AfE1f3D0635; knownContracts.push(current); contractTypes[current] = Type.STRATEGYUPGRADE;
            current = 0x3b4FFD93CE5fCf97e61AA8275Ec241C76cC01a47; knownContracts.push(current); contractTypes[current] = Type.STRATEGYUPGRADE;
            current = 0x861509A3fA7d87FaA0154AAE2CB6C1f92639339A; knownContracts.push(current); contractTypes[current] = Type.STRATEGYUPGRADE;
            current = 0xfe2Aba5ba890AF0ee8B6F2d488B1f85C9E7C5643; knownContracts.push(current); contractTypes[current] = Type.STRATEGYUPGRADE;
            current = 0xC7D2E96Ca94E1870605c286268313785886D2257; knownContracts.push(current); contractTypes[current] = Type.STRATEGYV2;
            current = 0x0A4B2e37BFEF8e54DeA997A87749A403353134e8; knownContracts.push(current); contractTypes[current] = Type.STRATEGYV2;
            current = 0x9847D09cb0eEA77f7875A6904BFA22AE06b34CCE; knownContracts.push(current); contractTypes[current] = Type.STRATEGYV2;
            current = 0x4771522accAC6fEcf89A6365cEaF05667ed95886; knownContracts.push(current); contractTypes[current] = Type.STRATEGYV2;
            current = 0xCeAf1CBf0CFDD1f7Ea4C1C850c0bC032a60431DB; knownContracts.push(current); contractTypes[current] = Type.STRATEGYV2;
            current = 0x7012aF43F8a3c1141Ee4e955CC568Ad2af59C3fa; knownContracts.push(current); contractTypes[current] = Type.STRATEGYV2;
            current = 0x8b814aD71e611e7a38eE64Ec16ce421A477956e1; knownContracts.push(current); contractTypes[current] = Type.STRATEGYV2;
            current = 0x2C918C4db3843F715556c65646f9E4a04C4BfBa6; knownContracts.push(current); contractTypes[current] = Type.STRATEGYV2;
        } else {
            revert UnknownChain(block.chainid);
        }
    }

    /// @dev Verify that the caller has given permission to Unwind to take all their tokens from a given contract
    function checkAllowance(address target) public view returns (bool) {
        return (ERC20(target).allowance(msg.sender, address(this)) >= ERC20(target).balanceOf(msg.sender));
    }

    /// @dev Return the amount of known contracts
    function knownContractsLength() public view returns (uint256) {
        return knownContracts.length;
    }

    /// @dev Examine the caller's wallet and determine what the next step should be
    /// @param user The address to look in for Yield Protocol tokens
    function whatNext(address user) public view returns (string memory, address) {
        address target;
        for (uint256 i=0; i < knownContracts.length; i++) {
            if (ERC20(knownContracts[i]).balanceOf(user) > 0) {
                target = knownContracts[i];
                break;
            }
        }

        if (target == address(0x0)) return ("Nothing to do", address(0x0));
        else {
            Type type_ = contractTypes[target];
            if (type_ == Type.UNKNOWN) return ("Nothing to do", target);
            else if (type_ == Type.POOL || type_ == Type.STRATEGYV2 || type_ == Type.STRATEGYV1) return ("removeLiquidity", target);
            else if (type_ == Type.STRATEGYUPGRADE) return ("upgradeStrategy", target);
            else return ("Unknown type", target);
        }
    }

    /// @dev Execute one step closer to full unwinding on a liquidity position
    /// User must have approved Unwind to take all their `target` tokens on the `target` contract
    /// @param target The Yield Protocol token address to unwind from the caller
    function removeLiquidity(address target) public {
        if (contractTypes[target] == Type.UNKNOWN) {
            revert UnknownAddress(target);
        }

        if (contractTypes[target] == Type.STRATEGYUPGRADE) {
            revert MustUpgradeStrategy(target);
        }
        
        if (!checkAllowance(target)) {
            revert NotEnoughAllowance(target);
        }
        
        uint256 tokenAmount = ERC20(target).balanceOf(msg.sender);
        if (tokenAmount == 0) {
            revert NoBalance(target);
        }

        if (contractTypes[target] == Type.POOL) {
            IPool pool = IPool(target);
            // We don't need to check that the pool is mature, because we won't release this until they all are
            pool.transferFrom(msg.sender, address(pool), tokenAmount);
            pool.burn(msg.sender, msg.sender, 0, type(uint256).max);
        } else if (contractTypes[target] == Type.STRATEGYV2) {
            IStrategy strategy = IStrategy(target);
            strategy.transferFrom(msg.sender, address(strategy), tokenAmount);
            if (strategy.state() == IStrategy.State.DIVESTED) {
                strategy.burnDivested(msg.sender);
            } else if (strategy.state() == IStrategy.State.INVESTED) {
                strategy.burn(msg.sender);
            } else {
                revert StuckStrategy(target);
            }
        } else if (contractTypes[target] == Type.STRATEGYV1) {
            IStrategyV1 strategy = IStrategyV1(target);
            strategy.transferFrom(msg.sender, address(strategy), tokenAmount);
            if (address(strategy.pool()) == address(0x0)) {
                strategy.burnForBase(msg.sender);
            } else {
                strategy.burn(msg.sender);
            }
        } else {
            revert NotLiquidityAddress(target);
        }
    }
}