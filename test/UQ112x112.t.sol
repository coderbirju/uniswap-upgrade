// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/libraries/UQ112X112.sol";

contract UQ112X112Test is Test{
    using UQ112x112 for uint224;

    function testEncode() public{
        assertEq(UQ112x112.encode(1), 5192296858534827628530496329220096);
    }

    function testDiv() public{
        assertEq(UQ112x112.uqdiv(10,2), 5);
    }
}
