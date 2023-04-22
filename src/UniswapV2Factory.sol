// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

// import './interfaces/IUniswapV2Factory.sol';
import './UniswapV2Pair.sol';
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

    // address public feeTo;
    // address public feeToSetter;

    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    constructor(address _feeToSetter) {
        feeToSetter = _feeToSetter;
    }

    function allPairsLength() external view override returns (uint) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB) public returns (address pair) {
        if (tokenA == tokenB) revert IdenticalAddresses();
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        if (token0 == address(0)) revert ZeroAddress();

        if (pairs[token0][token1] != address(0)) revert PairExists(); // single check is sufficient
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

    // function setFeeTo(address _feeTo) external {
    //     require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
    //     feeTo = _feeTo;
    // }

    // function setFeeToSetter(address _feeToSetter) external {
    //     require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
    //     feeToSetter = _feeToSetter;
    // }
}
