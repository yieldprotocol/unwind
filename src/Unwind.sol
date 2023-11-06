// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import { ERC20 } from "lib/yield-utils-v2/src/token/ERC20.sol";
import { IPool } from "lib/yieldspace-tv/src/interfaces/IPool.sol";
import { IStrategy } from "lib/strategy-v2/src/interfaces/IStrategy.sol";
import { IStrategyV1 } from "lib/strategy-v2/src/deprecated/IStrategyV1.sol";
import { IFYToken } from "lib/vault-v2/src/interfaces/IFYToken.sol";
import { IJoin } from "lib/vault-v2/src/interfaces/IJoin.sol";
import { DataTypes } from "lib/vault-v2/src/interfaces/DataTypes.sol";
import { ICauldron } from "lib/vault-v2/src/interfaces/ICauldron.sol";
import { ILadle } from "lib/vault-v2/src/interfaces/ILadle.sol";


contract Unwind {
    enum Type {
        UNKNOWN,
        FYTOKEN,
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
    error NotLendingAddress(address target);
    error VaultDoesNotExist(bytes12 vaultId);

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
            current = 0xFCb9B8C5160Cf2999f9879D8230dCed469E72eeb; knownContracts.push(current); contractTypes[current] = Type.FYTOKEN;
            current = 0x53C2a1bA37FF3cDaCcb3EA030DB3De39358e5593; knownContracts.push(current); contractTypes[current] = Type.FYTOKEN;
            current = 0x7Eaf9612Fbaa544FefbFB3C9A934c9441084816e; knownContracts.push(current); contractTypes[current] = Type.FYTOKEN;
            current = 0x53358d088d835399F1E97D2a01d79fC925c7D999; knownContracts.push(current); contractTypes[current] = Type.FYTOKEN;
            current = 0x7F0dD461D77F84cDd3ceD46F9D550e35F1969a24; knownContracts.push(current); contractTypes[current] = Type.FYTOKEN;
            current = 0x3353E1E2976DBbc191a739871faA8E6E9D2622c7; knownContracts.push(current); contractTypes[current] = Type.FYTOKEN;
            current = 0x386a0A72FfEeB773381267D69B61aCd1572e074D; knownContracts.push(current); contractTypes[current] = Type.FYTOKEN;
            current = 0xcDfBf28Db3B1B7fC8efE08f988D955270A5c4752; knownContracts.push(current); contractTypes[current] = Type.FYTOKEN;
            current = 0x38b8BF13c94082001f784A642165517F8760988f; knownContracts.push(current); contractTypes[current] = Type.FYTOKEN;
            current = 0xC20952b2C8bB6689e7EC2F70Aeba392C378EC413; knownContracts.push(current); contractTypes[current] = Type.FYTOKEN;
            current = 0x0FBd5ca8eE61ec921B3F61B707f1D7D64456d2d1; knownContracts.push(current); contractTypes[current] = Type.FYTOKEN; // - Not enough join balance
            current = 0x79A6Be1Ae54153AA6Fc7e4795272c63F63B2a6DC; knownContracts.push(current); contractTypes[current] = Type.FYTOKEN; // - Not enough join balance
            current = 0x22E1e5337C5BA769e98d732518b2128dE14b553C; knownContracts.push(current); contractTypes[current] = Type.FYTOKEN; // - Not enough join balance
            current = 0x2eb907fb4b71390dC5CD00e6b81B7dAAcE358193; knownContracts.push(current); contractTypes[current] = Type.FYTOKEN;
            current = 0x124c9F7E97235Fe3E35820f95D10aFfCe4bE9168; knownContracts.push(current); contractTypes[current] = Type.FYTOKEN; // - Not enough join balance
            current = 0x9ca4D6fbE0Ba91d553e74805d2E2545b04AbEfEA; knownContracts.push(current); contractTypes[current] = Type.FYTOKEN; // - Not enough join balance
            current = 0x667f185407C4CAb52aeb681f0006e4642d8091DF; knownContracts.push(current); contractTypes[current] = Type.FYTOKEN; // - Not enough join balance
            current = 0xFA71e5f0072401dA161b1FC25a9636927AF690D0; knownContracts.push(current); contractTypes[current] = Type.FYTOKEN;
            current = 0x8A6ff4c631816888444807541578Ab8465EdDDC2; knownContracts.push(current); contractTypes[current] = Type.FYTOKEN;
            current = 0xA0e4B17042F20D9BadBdA9961C2D0987c90F6439; knownContracts.push(current); contractTypes[current] = Type.FYTOKEN;
            current = 0xc8110b03629211b946c2783637ABC9402b50EcDf; knownContracts.push(current); contractTypes[current] = Type.FYTOKEN; // - Not enough join balance, maybe disabled after Euler event
            current = 0xc7f12Ea237bE7BE6028285052CF3727EaF0e597B; knownContracts.push(current); contractTypes[current] = Type.FYTOKEN; // - Not enough join balance, maybe disabled after Euler event
            current = 0x9912ED921832A8F6fc4a07E0892E5974A252043C; knownContracts.push(current); contractTypes[current] = Type.FYTOKEN; // - Not enough join balance, maybe disabled after Euler event
            current = 0xD28380De0e7093AC62bCb88610b9f4f4Fb58Be74; knownContracts.push(current); contractTypes[current] = Type.FYTOKEN;
            current = 0xD842A9f77e142f420BcdBCd6cFAC3548a68906dB; knownContracts.push(current); contractTypes[current] = Type.FYTOKEN; // - Not enough join balance
            current = 0xB917a6CD3f811A84c1c5B972E2c715a6d93f40aa; knownContracts.push(current); contractTypes[current] = Type.FYTOKEN; // - Not enough join balance
            current = 0x74c4cEa80c1afEAda2907B55FDD9C958Da4a53F2; knownContracts.push(current); contractTypes[current] = Type.FYTOKEN; // - Not enough join balance
            current = 0x299c9e28D2c5efa09aa147abB4f1CB4a8dc7AbE0; knownContracts.push(current); contractTypes[current] = Type.FYTOKEN;
            current = 0xB38Ba395D15392796B51057490bBc790871dd6a0; knownContracts.push(current); contractTypes[current] = Type.FYTOKEN;
            current = 0x82AC37A79D83f8C6E3B55E5e72e1f4ACb1E4fe9f; knownContracts.push(current); contractTypes[current] = Type.FYTOKEN; // - Not mature yet
            current = 0xB78F9F7d67a4c7cfAD0Dad80364E95bAe42d2fE1; knownContracts.push(current); contractTypes[current] = Type.FYTOKEN; // - Not mature yet
            current = 0x9536C528d9e3f12586ea3E8f624dACb8150b22aa; knownContracts.push(current); contractTypes[current] = Type.FYTOKEN; // - Not mature yet
            current = 0x72791dA88B34869CdF4863d966F182D866f51c04; knownContracts.push(current); contractTypes[current] = Type.FYTOKEN; // - Not mature yet
            current = 0x6BaC09a67Ed1e1f42c29563847F77c28ec3a04FC; knownContracts.push(current); contractTypes[current] = Type.POOL;
            current = 0xf5Fd5A9Db9CcCc6dc9f5EF1be3A859C39983577C; knownContracts.push(current); contractTypes[current] = Type.POOL;
            current = 0x341B0976F962eC34eEaF31cdF2464Ab3B15B6301; knownContracts.push(current); contractTypes[current] = Type.POOL;
            current = 0xc3348D8449d13C364479B1F114bcf5B73DFc0dc6; knownContracts.push(current); contractTypes[current] = Type.POOL;
            current = 0xA4d45197E3261721B8A8d901489Df5d4D2E79eD7; knownContracts.push(current); contractTypes[current] = Type.POOL;
            current = 0x4b32C37Be5949e77ba3726E863a030BD77942A97; knownContracts.push(current); contractTypes[current] = Type.POOL;
            current = 0x9D34dF69958675450ab8E53c8Df5531203398Dc9; knownContracts.push(current); contractTypes[current] = Type.POOL;
            current = 0x52956Fb3DC3361fd24713981917f2B6ef493DCcC; knownContracts.push(current); contractTypes[current] = Type.POOL;
            current = 0xB2fff7FEA1D455F0BCdd38DA7DeE98af0872a13a; knownContracts.push(current); contractTypes[current] = Type.POOL;
            current = 0xFa38F3717daD95085FF725aA93608Af3fa1D9e58; knownContracts.push(current); contractTypes[current] = Type.POOL;
            current = 0x1b2145139516cB97568B76a2FdbE37D2BCD61e63; knownContracts.push(current); contractTypes[current] = Type.POOL;
            current = 0xBdc7Bdae87dfE602E91FDD019c4C0334C38f6A46; knownContracts.push(current); contractTypes[current] = Type.POOL;
            current = 0x48b95265749775310B77418Ff6f9675396ABE1e8; knownContracts.push(current); contractTypes[current] = Type.POOL;
            current = 0x1D2eB98042006B1bAFd10f33743CcbB573429daa; knownContracts.push(current); contractTypes[current] = Type.POOL;
            current = 0xD129B0351416C75C9f0623fB43Bb93BB4107b2A4; knownContracts.push(current); contractTypes[current] = Type.POOL;
            current = 0xC2a463278387e649eEaA5aE5076e283260B0B1bE; knownContracts.push(current); contractTypes[current] = Type.POOL;
            current = 0x06aaF385809c7BC00698f1E266eD4C78d6b8ba75; knownContracts.push(current); contractTypes[current] = Type.POOL;
            current = 0x2E8F62e3620497DbA8A2D7A18EA8212215805F22; knownContracts.push(current); contractTypes[current] = Type.POOL;
            current = 0x7472DF92Ae587f97939de92bDFC23dbaCD8a3816; knownContracts.push(current); contractTypes[current] = Type.POOL;
            current = 0xB4DbEc738Ffe47981D337C02Cb5746E456ecd505; knownContracts.push(current); contractTypes[current] = Type.POOL;
            current = 0x60995D90B45169eB04F1ea9463443a62B83ab1c1; knownContracts.push(current); contractTypes[current] = Type.POOL;
            current = 0x0bdF152f6d899F4B63b9554ED98D9b9d22FFdee4; knownContracts.push(current); contractTypes[current] = Type.POOL;
            current = 0xaCd0523Aca72CC58EC2f3d4C14F5473FC11c5C2D; knownContracts.push(current); contractTypes[current] = Type.POOL;
            current = 0x6E38B8d9dedd967961508708183678b4EC1B1E33; knownContracts.push(current); contractTypes[current] = Type.POOL;
            current = 0xE56c9c47b271A58e5856004952c5F4D34a78B99B; knownContracts.push(current); contractTypes[current] = Type.POOL;
            current = 0x9ce9c9f9fF417Ffc215A4e5c6b4e44BB76Cf8C79; knownContracts.push(current); contractTypes[current] = Type.POOL;
            current = 0xFCd1C61139F8Af13c5090CfBb2dD674a2Ff4fe35; knownContracts.push(current); contractTypes[current] = Type.POOL;
            current = 0x0ECc79FE01b02548853c87466cCd57710bf9d11A; knownContracts.push(current); contractTypes[current] = Type.POOL;
            current = 0xe2F6f40192F3E4568a62577E0541AC823b6f0D9e; knownContracts.push(current); contractTypes[current] = Type.POOL;
            current = 0xB9345c19291bB073b0E6483048fAFD0986AB82dF; knownContracts.push(current); contractTypes[current] = Type.POOL;
            current = 0x14132D979fDdA62a56d9f552C9aa477b9c94851e; knownContracts.push(current); contractTypes[current] = Type.POOL;
            current = 0x3667362C4B666B952383eDBE12fC9cC108D09cD7; knownContracts.push(current); contractTypes[current] = Type.POOL;
            current = 0x9acbc758B9f06F9ad9AA5DdB6C42B5b0375B5B6c; knownContracts.push(current); contractTypes[current] = Type.POOL;
            current = 0xcf30A5A994f9aCe5832e30C138C9697cda5E1247; knownContracts.push(current); contractTypes[current] = Type.STRATEGYV1;
            current = 0x7ACFe277dEd15CabA6a8Da2972b1eb93fe1e2cCD; knownContracts.push(current); contractTypes[current] = Type.STRATEGYV1;
            current = 0xFBc322415CBC532b54749E31979a803009516b5D; knownContracts.push(current); contractTypes[current] = Type.STRATEGYV1;
            current = 0x1565F539E96c4d440c38979dbc86Fd711C995DD6; knownContracts.push(current); contractTypes[current] = Type.STRATEGYV1;
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
            current = 0x0e7727F4ee78D60f1D3aa30744B3ab6610F04170; knownContracts.push(current); contractTypes[current] = Type.FYTOKEN;
            current = 0xa9Bc738c017771A4cF01730F215E6E2b34DCa9B8; knownContracts.push(current); contractTypes[current] = Type.FYTOKEN;
            current = 0xa3eCAF5c5E98C1a500f4596576dAD3328A701C73; knownContracts.push(current); contractTypes[current] = Type.FYTOKEN;
            current = 0xC4b24Ec9fB2DC32b3a545e0d873d2598031B80C5; knownContracts.push(current); contractTypes[current] = Type.FYTOKEN;
            current = 0xe8Ec1A61f6C86e8d33C327FEdad559c20b9A66a2; knownContracts.push(current); contractTypes[current] = Type.FYTOKEN;
            current = 0xD4aeA765BC2c56f09074254eb5a3f5FF9d709449; knownContracts.push(current); contractTypes[current] = Type.FYTOKEN;
            current = 0x5655A973A49e1F9c1408bb9A617Fd0DBD0352464; knownContracts.push(current); contractTypes[current] = Type.FYTOKEN;
            current = 0x8a9262C7C6eC9bb143Eb68798AdB377c95F47138; knownContracts.push(current); contractTypes[current] = Type.FYTOKEN;
            current = 0x3295a74Bca0d6FdFeF648BA8549d305a8bA9cc13; knownContracts.push(current); contractTypes[current] = Type.FYTOKEN;
            current = 0x0FBd5ca8eE61ec921B3F61B707f1D7D64456d2d1; knownContracts.push(current); contractTypes[current] = Type.FYTOKEN;
            current = 0x523803c57a497c3AD0E850766c8276D4864edEA5; knownContracts.push(current); contractTypes[current] = Type.FYTOKEN;
            current = 0x60a6A7fabe11ff36cbE917a17666848f0FF3A60a; knownContracts.push(current); contractTypes[current] = Type.FYTOKEN;
            current = 0xCbB7Eba13F9E1d97B2138F588f5CA2F5167F06cc; knownContracts.push(current); contractTypes[current] = Type.FYTOKEN;
            current = 0xC24DA474A71C44d2b644089020ba255908AdA6e1; knownContracts.push(current); contractTypes[current] = Type.FYTOKEN;
            current = 0x035072cb2912DAaB7B578F468Bd6F0d32a269E32; knownContracts.push(current); contractTypes[current] = Type.FYTOKEN;
            current = 0xd947360575E6F01Ce7A210C12F2EE37F5ab12d11; knownContracts.push(current); contractTypes[current] = Type.FYTOKEN;
            current = 0xEE508c827a8990c04798B242fa801C5351012B23; knownContracts.push(current); contractTypes[current] = Type.FYTOKEN;
            current = 0x5Bb78E530D9365aeF75664c5093e40B0001F7CCd; knownContracts.push(current); contractTypes[current] = Type.FYTOKEN;
            current = 0x9B19889794A30056A1E5Be118ee0a6647B184c5f; knownContracts.push(current); contractTypes[current] = Type.FYTOKEN;
            current = 0x8c41fc42e8Ebf66eA5F3190346c2d5b94A80480F; knownContracts.push(current); contractTypes[current] = Type.FYTOKEN;
            current = 0xCA9d3B5dE1550c79155b1311Ef54EBc73954D470; knownContracts.push(current); contractTypes[current] = Type.FYTOKEN;
            current = 0x3B560caa508CA8E58f07263f58Ee2353044C0d5c; knownContracts.push(current); contractTypes[current] = Type.FYTOKEN;
            current = 0x9Ca40B35c3A8A717D4d54faC0905BBf889dDb281; knownContracts.push(current); contractTypes[current] = Type.FYTOKEN;
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
            current = 0xad1983745D6c739537fEaB5bed45795f47A940b3; knownContracts.push(current); contractTypes[current] = Type.STRATEGYV2;
            current = 0x5582b8398FB586F1b79edd1a6e83f1c5aa558955; knownContracts.push(current); contractTypes[current] = Type.STRATEGYV2;
            current = 0x4276BEaA49DE905eED06FCDc0aD438a19D3861DD; knownContracts.push(current); contractTypes[current] = Type.STRATEGYV2;
            current = 0x5aeB4EFaAA0d27bd606D618BD74Fe883062eAfd0; knownContracts.push(current); contractTypes[current] = Type.STRATEGYV2;
            current = 0x33e6B154efC7021dD55464c4e11a6AfE1f3D0635; knownContracts.push(current); contractTypes[current] = Type.STRATEGYV2;
            current = 0x3b4FFD93CE5fCf97e61AA8275Ec241C76cC01a47; knownContracts.push(current); contractTypes[current] = Type.STRATEGYV2;
            current = 0x861509A3fA7d87FaA0154AAE2CB6C1f92639339A; knownContracts.push(current); contractTypes[current] = Type.STRATEGYV2;
            current = 0xfe2Aba5ba890AF0ee8B6F2d488B1f85C9E7C5643; knownContracts.push(current); contractTypes[current] = Type.STRATEGYV2;
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
    function whatNext() public view returns (string memory, address) {
        address target;
        for (uint256 i=0; i < knownContracts.length; i++) {
            if (ERC20(knownContracts[i]).balanceOf(msg.sender) > 0) {
                target = knownContracts[i];
                break;
            }
        }

        if (target == address(0x0)) return ("Nothing to do", address(0x0));
        else {
            Type type_ = contractTypes[target];
            if (type_ == Type.UNKNOWN) return ("Nothing to do", target);
            else if (type_ == Type.FYTOKEN)  return ("closeLending", target);
            else if (type_ == Type.POOL) return ("removeLiquidity", target);
            else if (type_ == Type.STRATEGYV2) return ("removeLiquidity", target);
            else if (type_ == Type.STRATEGYV1) return ("removeLiquidity", target);
            else if (type_ == Type.STRATEGYUPGRADE) return ("upgradeStrategy", target);
            else return ("Unknown type", target);
        }
    }

    /// @dev Execute one step closer to full unwinding on a liquidity position
    /// User must have approved Unwind to take all their `target` tokens on the `target` contract
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
        
        if (contractTypes[target] == Type.POOL) {
            IPool pool = IPool(target);
            // We don't need to check that the pool is mature, because we won't release this until they all are
            pool.transferFrom(msg.sender, address(pool), pool.balanceOf(msg.sender));
            pool.burn(msg.sender, msg.sender, 0, type(uint256).max);
        } else if (contractTypes[target] == Type.STRATEGYV2) {
            IStrategy strategy = IStrategy(target);
            strategy.transferFrom(msg.sender, address(strategy), strategy.balanceOf(msg.sender));
            if (strategy.state() == IStrategy.State.DIVESTED) {
                strategy.burnDivested(msg.sender);
            } else if (strategy.state() == IStrategy.State.INVESTED) {
                strategy.burn(msg.sender);
            } else {
                revert StuckStrategy(target);
            }
        } else if (contractTypes[target] == Type.STRATEGYV1) {
            IStrategyV1 strategy = IStrategyV1(target);
            strategy.transferFrom(msg.sender, address(strategy), strategy.balanceOf(msg.sender));
            if (address(strategy.pool()) == address(0x0)) {
                strategy.burnForBase(msg.sender);
            } else {
                strategy.burn(msg.sender);
            }
        } else {
            revert NotLiquidityAddress(target);
        }
    }

    /// @dev Unwind a lending position
    /// User must have approved Unwind to take all their `target` tokens on the `target` contract
    function closeLend(address target) public {
        if (contractTypes[target] == Type.UNKNOWN) {
            revert UnknownAddress(target);
        }

        if (!checkAllowance(target)) {
            revert NotEnoughAllowance(target);
        }

        if (contractTypes[target] == Type.FYTOKEN) {
            IFYToken fyToken = IFYToken(target);
            fyToken.transferFrom(msg.sender, address(fyToken), fyToken.balanceOf(msg.sender));
            fyToken.redeem(msg.sender, 0); // If there is more fyToken in the contract than we sent, that's a bonus for the caller
        } else {
            revert NotLendingAddress(target);
        }
    }

    /// @dev Unwind a borrowing position, removing all collateral
    /// User must have approved Unwind to take enough underlying to repay the loan.
    /// Maybe approve max and then revoke, or use `howMuchDebt` and approve about 1.25x what was returned to be on the safe side.
    function closeBorrow(bytes12 vaultId) public {
        // Get the corresponding base join and vault data
        DataTypes.Vault memory vault = cauldron.vaults(vaultId);
        if (vault.owner == address(0)) {
            revert VaultDoesNotExist(vaultId);
        }

        DataTypes.Series memory series = cauldron.series(vault.seriesId);
        IJoin baseJoin = IJoin(ladle.joins(series.baseId));
        ERC20 baseToken = ERC20(baseJoin.asset());

        // Get the vault art and ink
        DataTypes.Balances memory balances = cauldron.balances(vaultId);

        // Convert the art into base
        uint256 baseAmount = cauldron.debtToBase(vault.seriesId, balances.art) + 1; // Let's take an extra wei, in case we mess up the rounding

        if (!checkAllowance(address(baseToken))) {
            revert NotEnoughAllowance(address(baseToken));
        }

        // Transfer the base to the Join
        baseToken.transferFrom(msg.sender, address(baseJoin), baseAmount + 1);

        // Call ladle.close to repay art and withdraw ink
        ladle.close(vaultId, msg.sender, -int128(balances.ink), -int128(balances.art)); // No one should have enough ink or art to make this overflow, and if they do, they are probably malicious, hurting only themselves.
    }

    /// @dev Show how much debt is outstanding on a vault in fyToken, minus interest.
    function howMuchDebt(bytes12 vaultId) public view returns (uint256) {
        return cauldron.balances(vaultId).art;
    }
}
