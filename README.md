## Yield Unwind

Mainnet: 0xC7ef61f925eFFD6253A1Fb038eB93e42cd9EA290
Arbitrum: 0xa9871ff711C333765642d0d5343C1303e4341Ea3

Unwind.sol is a permissionless contract that allows users to unwind their liquidity positions on Yield through Etherscan or Arbiscan.

The user should call the `whatNext` view function which will scan the supplied account for known Yield Protocol tokens addresses. It will return an action to take and a token address (`token`).

If the action to take is `removeLiquidity`, the user will have to approve `Unwind.sol` to take his balance of `token`, and then call `removeLiquidity(token)` which will result in `token` being gone from the user’s wallet, and some other token appearing. This other token might be underlying such as DAI or USDC, or it could be another Yield Protocol token.

The user should repeat this process until `whatNext` returns "Nothing to do", as it will return only one token at a time, and sometimes `removeLiquidity` will replace a Yield token for another Yield token (usually when unwinding liquidity positions).

## Troubleshooting
The best way to debug a failing transaction is through [Tenderly](https://tenderly.co). Past transactions can be searched for, or failing transactions can be simulated to find exactly where it is that they are failing.

## Support
This contract is unsupported. One place where you can might find help is the [Yield Protocol discord](https://discord.com/invite/JAFfDj5).

## Audit

- [christos.eth](https://github.com/christos-eth/Unwind-audit/issues/2)

## License

This project is unlicensed.
