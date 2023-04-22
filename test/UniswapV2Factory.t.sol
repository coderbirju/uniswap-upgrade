// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.19;

import "../lib/forge-std/src/Test.sol";
import "./fakes/DummyErc20.sol";
import "../src/UniswapV2Factory.sol";
import "../src/UniswapV2Pair.sol";


contract UniswapV2FactoryTest is Test {
    UniswapV2Factory factory;

    DummyErc20 token0;
    DummyErc20 token1;
    DummyErc20 token2;
    DummyErc20 token3;

    function setUp() public {
        factory = new UniswapV2Factory();

        token0 = new DummyErc20("Token A", "TKNA");
        token1 = new DummyErc20("Token B", "TKNB");
        token2 = new DummyErc20("Token C", "TKNC");
        token3 = new DummyErc20("Token D", "TKND");
    }

    function encodeError(string memory error)
        internal
        pure
        returns (bytes memory encoded)
    {
        encoded = abi.encodeWithSignature(error);
    }

    function testCreatePair() public {
        address pairAddress = factory.createPair(
            address(token1),
            address(token0)
        );

        UniswapV2Pair pair = UniswapV2Pair(pairAddress);

        assertEq(pair.token0(), address(token0));
        assertEq(pair.token1(), address(token1));
    }

    function testCreatePairZeroAddress() public {
        vm.expectRevert(encodeError("ZeroAddress()"));
        factory.createPair(address(0), address(token0));

        vm.expectRevert(encodeError("ZeroAddress()"));
        factory.createPair(address(token1), address(0));
    }

    function testCreatePairPairExists() public {
        factory.createPair(address(token1), address(token0));

        vm.expectRevert(encodeError("PairExists()"));
        factory.createPair(address(token1), address(token0));
    }

    function testCreatePairIdenticalTokens() public {
        vm.expectRevert(encodeError("IdenticalAddresses()"));
        factory.createPair(address(token0), address(token0));
    }
}
