// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.19;

import "../lib/forge-std/src/Test.sol";
import "./fakes/DummyErc20.sol";


contract DummyErc20Test is Test{
    DummyErc20 e;
    address owner;
    function setUp() public{
        owner = address(this);
        e = new DummyErc20("Token", "TK");
    }

    function testMint() public{
        e.mint(100, owner);
        assertEq(e.balanceOf(owner), 100);
    }
}