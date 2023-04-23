// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.19;

import "./UniswapV2Pair.sol";
import "./interfaces/IUniswapV2Pair.sol";

contract UniswapV2Factory {
    error IdenticalAddresses();
    error PairExists();
    error ZeroAddress();

    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    mapping(address => mapping(address => address)) public pairs;
    address[] public allPairs;

    /**
     * @dev Creates a new UniswapV2Pair contract for the specified token pair.
     * @param tokenA The address of one of the tokens in the pair.
     * @param tokenB The address of the other token in the pair.
     *  The address of the new UniswapV2Pair contract.
     *  IdenticalAddresses if tokenA and tokenB are the same address.
     *  ZeroAddress if tokenA or tokenB is the zero address.
     *  PairExists if a pair for the specified token pair already exists.
     */
    function createPair(address tokenA, address tokenB)
        public
        returns (address pair)
    {
        if (tokenA == tokenB) revert IdenticalAddresses();

        (address token0, address token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);

        if (token0 == address(0)) revert ZeroAddress();

        if (pairs[token0][token1] != address(0)) revert PairExists();

        bytes memory bytecode = type(UniswapV2Pair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        IUniswapV2Pair(pair).initialize(token0, token1);

        pairs[token0][token1] = pair;
        pairs[token1][token0] = pair;
        allPairs.push(pair);

        emit PairCreated(token0, token1, pair, allPairs.length);
    }
}
