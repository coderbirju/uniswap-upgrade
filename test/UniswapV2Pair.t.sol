// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/UniswapV2Pair.sol";
import "../src/test/ERC20.sol";



interface Hevm {
    function warp(uint256) external;
}

contract TestUniswapV2Pair is Test {
     UniswapV2Pair pair;
     Hevm hevm;

    function setUp() public {
        pair = new UniswapV2Pair();
        hevm = Hevm(HEVM_ADDRESS);
    }

    function test_initialize() public {
        address token0 = 0x1000000000000000000000000000000000000000;
        address token1 = 0x2000000000000000000000000000000000000000;
        pair.initialize(token0, token1);
        assertEq(pair.token0(), token0);
        assertEq(pair.token1(), token1);
    }

    function test_mint() public {
        uint256 balance0 = 1000000;
        uint256 balance1 = 2000000;
        address to = address(this);
        address token0 = 0x1000000000000000000000000000000000000000;
        address token1 = 0x2000000000000000000000000000000000000000;
        pair.initialize(token0, token1);
        // ERC20(address(this)).approve(address(pair), type(uint256).max);
        pair.mint(to);
        assertEq(pair.balanceOf(to), pair.totalSupply());
        assertEq(pair.balanceOf(to), pair.balanceOf(address(this)));
        assertEq(IERC20(address(this)).balanceOf(address(pair)), 0);
        assertEq(IERC20(address(pair)).balanceOf(address(this)), 0);
        assertEq(IERC20(address(this)).balanceOf(to), balance0);
        assertEq(IERC20(address(pair)).balanceOf(to), balance1);
    }


}
