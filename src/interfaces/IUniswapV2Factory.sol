// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IUniswapV2Factory {
    // event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function pairs(address, address) external pure returns (address);

    function createPair(address, address) external returns (address);
}
