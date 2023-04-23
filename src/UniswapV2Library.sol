// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.19;

import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Pair.sol";
import {UniswapV2Pair} from "./UniswapV2Pair.sol";

library UniswapV2Library {
    error InsufficientAmount();
    error InsufficientLiquidity();
    error InvalidPath();

    /**
     * @dev Gets the reserves of the specified token pair in a UniswapV2Pair contract.
     * @param factoryAddress The address of the UniswapV2Factory contract.
     * @param tokenA The address of one of the tokens in the pair.
     * @param tokenB The address of the other token in the pair.
     *  reserveA The amount of tokenA in the reserves.
     *  reserveB The amount of tokenB in the reserves.
     */
    function getReserves(
        address factoryAddress,
        address tokenA,
        address tokenB
    ) public returns (uint256 reserveA, uint256 reserveB) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(
            pairFor(factoryAddress, token0, token1)
        ).getReserves();
        (reserveA, reserveB) = tokenA == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
    }

    /**
     * @dev Calculates the amount of tokenOut that can be obtained by trading a certain amount of tokenIn,
     * based on the reserves of a UniswapV2Pair contract.
     * @param amountIn The amount of tokenIn to trade.
     * @param reserveIn The amount of tokenIn in the reserves.
     * @param reserveOut The amount of tokenOut in the reserves.
     *  amountOut The amount of tokenOut that can be obtained.
     *  InsufficientAmount if amountIn is zero.
     *  InsufficientLiquidity if either reserveIn or reserveOut is zero.
     */
    function quote(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) public pure returns (uint256 amountOut) {
        if (amountIn == 0) revert InsufficientAmount();
        if (reserveIn == 0 || reserveOut == 0) revert InsufficientLiquidity();

        return (amountIn * reserveOut) / reserveIn;
    }

    /**
     * @dev Sorts two token addresses in ascending order, and returns them as `token0` and `token1`.
     * @param tokenA The address of the first token to sort.
     * @param tokenB The address of the second token to sort.
     *  token0 The address of the token with the lower value.
     *  token1 The address of the token with the higher value.
     */
    function sortTokens(address tokenA, address tokenB)
        internal
        pure
        returns (address token0, address token1)
    {
        return tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    }

    /**
     * @dev Computes the address of the Uniswap pair contract for two tokens, given the factory address.
     * @param factoryAddress The address of the Uniswap factory contract.
     * @param tokenA The address of the first token.
     * @param tokenB The address of the second token.
     * The address of the Uniswap pair contract for the two tokens.
     */
    function pairFor(
        address factoryAddress,
        address tokenA,
        address tokenB
    ) internal pure returns (address pairAddress) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pairAddress = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factoryAddress,
                            keccak256(abi.encodePacked(token0, token1)),
                            keccak256(type(UniswapV2Pair).creationCode)
                        )
                    )
                )
            )
        );
    }

    /**
     * @dev Given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset.
     * @param amountIn Input amount of asset to swap.
     * @param reserveIn Reserve of the input asset in the pair.
     * @param reserveOut Reserve of the output asset in the pair.
     * @return Maximum output amount of the output asset.
     */
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) public pure returns (uint256) {
        if (amountIn == 0) revert InsufficientAmount();
        if (reserveIn == 0 || reserveOut == 0) revert InsufficientLiquidity();

        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = (reserveIn * 1000) + amountInWithFee;

        return numerator / denominator;
    }


    /**
     * @dev Given an input amount of an asset and a pair of token addresses, returns the maximum output amount
     * of the other asset that can be received, along with an array of the intermediate amounts and the
     * addresses of the pairs through which the trade path would take place.
     * @param factory The address of the Uniswap V2 factory contract.
     * @param amountIn The amount of the input asset to trade.
     * @param path An array of token addresses. Each consecutive pair of elements represents a token pair.
     * @return An array of the output amounts and an array of the intermediate pairs.
     */
    function getAmountsOut(
        address factory,
        uint256 amountIn,
        address[] memory path
    ) public returns (uint256[] memory) {
        if (path.length < 2) revert InvalidPath();
        uint256[] memory amounts = new uint256[](path.length);
        amounts[0] = amountIn;

        for (uint256 i; i < path.length - 1; i++) {
            (uint256 reserve0, uint256 reserve1) = getReserves(
                factory,
                path[i],
                path[i + 1]
            );
            amounts[i + 1] = getAmountOut(amounts[i], reserve0, reserve1);
        }

        return amounts;
    }


    /**
        * @dev Calculates the required amount of amountIn to receive amountOut based on the provided reserves.
        * @param amountOut The desired amount of output tokens.
        * @param reserveIn The reserve of the input token.
        * @param reserveOut The reserve of the output token.
        * The required amount of input tokens.
        * InsufficientAmount If amountOut is zero.
        * InsufficientLiquidity If reserveIn or reserveOut is zero.
    */
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) public pure returns (uint256) {
        if (amountOut == 0) revert InsufficientAmount();
        if (reserveIn == 0 || reserveOut == 0) revert InsufficientLiquidity();

        uint256 numerator = reserveIn * amountOut * 1000;
        uint256 denominator = (reserveOut - amountOut) * 997;

        return (numerator / denominator) + 1;
    }

    /**
     * @dev Given a factory address, an amount of output tokens, and an array of tokens in the desired input-output order,
     * returns an array of input token amounts that would be required to obtain the given amount of output tokens.
     * 
     * Requirements:
     * - The input-output token path must have at least 2 elements.
     * 
     * @param factory The address of the UniswapV2Factory contract.
     * @param amountOut The desired amount of output tokens.
     * @param path An array of token addresses representing the desired input-output token path.
     * 
     * @return amounts An array of input token amounts required to obtain the desired amount of output tokens.
    */
    function getAmountsIn(
        address factory,
        uint256 amountOut,
        address[] memory path
    ) public returns (uint256[] memory) {
        if (path.length < 2) revert InvalidPath();
        uint256[] memory amounts = new uint256[](path.length);
        amounts[amounts.length - 1] = amountOut;

        for (uint256 i = path.length - 1; i > 0; i--) {
            (uint256 reserve0, uint256 reserve1) = getReserves(
                factory,
                path[i - 1],
                path[i]
            );
            amounts[i - 1] = getAmountIn(amounts[i], reserve0, reserve1);
        }

        return amounts;
    }
}
