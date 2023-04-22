// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./UniswapV2Library.sol";

contract UniswapV2Router02 {

    error ExcessiveInputAmount();
    error InsufficientAAmount();
    error InsufficientBAmount();
    error InsufficientOutputAmount();
    error SafeTransferFailed();

    IUniswapV2Factory factory;
    address public WETH;

    // modifier ensure(uint256 deadline) {
    //     require(deadline >= block.timestamp, 'UniswapV2Router: EXPIRED');
    //     _;
    // }

    constructor(address factoryAddress) {
        factory = IUniswapV2Factory(factoryAddress);
    }

    // receive() external payable {
    //     assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    // }

    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) internal returns (uint256 amountA, uint256 amountB) {
       
        (uint256 reserveA, uint256 reserveB) = UniswapV2Library.getReserves(address(factory), tokenA, tokenB);

        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint256 amountBOptimal = UniswapV2Library.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                if (amountBOptimal <= amountBMin) revert InsufficientBAmount();
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal = UniswapV2Library.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                if (amountAOptimal <= amountAMin) revert InsufficientAAmount();
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to
    )  public returns (uint amountA, uint amountB, uint liquidity) {

        if (factory.pairs(tokenA, tokenB) == address(0)) {
            factory.createPair(tokenA, tokenB);
        }


        (amountA, amountB) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
        address pair = UniswapV2Library.pairFor(address(factory), tokenA, tokenB);

        _safeTransferFrom(tokenA, msg.sender, pair, amountA);
        _safeTransferFrom(tokenB, msg.sender, pair, amountB);
        liquidity = IUniswapV2Pair(pair).mint(to);
    }

    // function addLiquidityETH(
    //     address token,
    //     uint amountTokenDesired,
    //     uint amountTokenMin,
    //     uint amountETHMin,
    //     address to,
    //     uint deadline
    // ) external virtual override payable ensure(deadline) returns (uint amountToken, uint amountETH, uint liquidity) {
    //     (amountToken, amountETH) = _addLiquidity(
    //         token,
    //         WETH,
    //         amountTokenDesired,
    //         msg.value,
    //         amountTokenMin,
    //         amountETHMin
    //     );
    //     address pair = UniswapV2Library.pairFor(factory, token, WETH);
    //     TransferHelper.safeTransferFrom(token, msg.sender, pair, amountToken);
    //     IWETH(WETH).deposit{value: amountETH}();
    //     assert(IWETH(WETH).transfer(pair, amountETH));
    //     liquidity = IUniswapV2Pair(pair).mint(to);
    //     // refund dust eth, if any
    //     if (msg.value > amountETH) TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH);
    // }

    // **** REMOVE LIQUIDITY ****
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to
    ) public returns (uint256 amountA, uint256 amountB) {
        address pair = UniswapV2Library.pairFor(address(factory), tokenA, tokenB);
        IUniswapV2Pair(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        // (uint256 amount0, uint256 amount1) = IUniswapV2Pair(pair).burn(to);
        (amountA, amountB) = IUniswapV2Pair(pair).burn(to);
        if (amountA < amountAMin) revert InsufficientAAmount();
        if (amountA < amountBMin) revert InsufficientBAmount();
    }

    // function removeLiquidityETH(
    //     address token,
    //     uint256 liquidity,
    //     uint256 amountTokenMin,
    //     uint256 amountETHMin,
    //     address to,
    //     uint256 deadline
    // ) public  returns (uint256 amountToken, uint256 amountETH) {
    //     (amountToken, amountETH) = removeLiquidity(
    //         token,
    //         WETH,
    //         liquidity,
    //         amountTokenMin,
    //         amountETHMin,
    //         address(this),
    //         deadline
    //     );
    //     TransferHelper.safeTransfer(token, to, amountToken);
    //     IWETH(WETH).withdraw(amountETH);
    //     TransferHelper.safeTransferETH(to, amountETH);
    // }
    // function removeLiquidityWithPermit(
    //     address tokenA,
    //     address tokenB,
    //     uint256 liquidity,
    //     uint256 amountAMin,
    //     uint256 amountBMin,
    //     address to,
    //     uint256 deadline,
    //     bool approveMax,
    //     uint8 v, bytes32 r, bytes32 s
    // ) external virtual override returns (uint amountA, uint amountB) {
    //     address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);
    //     uint value = approveMax ? type(uint).max : liquidity;
    //     IUniswapV2Pair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
    //     (amountA, amountB) = removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline);
    // }
    // function removeLiquidityETHWithPermit(
    //     address token,
    //     uint liquidity,
    //     uint amountTokenMin,
    //     uint amountETHMin,
    //     address to,
    //     uint deadline,
    //     bool approveMax, uint8 v, bytes32 r, bytes32 s
    // ) external virtual override returns (uint amountToken, uint amountETH) {
    //     address pair = UniswapV2Library.pairFor(factory, token, WETH);
    //     uint value = approveMax ? type(uint).max : liquidity;
    //     IUniswapV2Pair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
    //     (amountToken, amountETH) = removeLiquidityETH(token, liquidity, amountTokenMin, amountETHMin, to, deadline);
    // }

    // **** REMOVE LIQUIDITY (supporting fee-on-transfer tokens) ****
    // function removeLiquidityETHSupportingFeeOnTransferTokens(
    //     address token,
    //     uint liquidity,
    //     uint amountTokenMin,
    //     uint amountETHMin,
    //     address to,
    //     uint deadline
    // ) public virtual override ensure(deadline) returns (uint amountETH) {
    //     (, amountETH) = removeLiquidity(
    //         token,
    //         WETH,
    //         liquidity,
    //         amountTokenMin,
    //         amountETHMin,
    //         address(this),
    //         deadline
    //     );
    //     TransferHelper.safeTransfer(token, to, IERC20(token).balanceOf(address(this)));
    //     IWETH(WETH).withdraw(amountETH);
    //     TransferHelper.safeTransferETH(to, amountETH);
    // }

    // function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
    //     address token,
    //     uint liquidity,
    //     uint amountTokenMin,
    //     uint amountETHMin,
    //     address to,
    //     uint deadline,
    //     bool approveMax,
    //     uint8 v, bytes32 r, bytes32 s
    // ) external virtual override returns (uint amountETH) {
    //     address pair = UniswapV2Library.pairFor(factory, token, WETH);
    //     uint value = approveMax ? type(uint).max : liquidity;
    //     IUniswapV2Pair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
    //     amountETH = removeLiquidityETHSupportingFeeOnTransferTokens(
    //         token, liquidity, amountTokenMin, amountETHMin, to, deadline
    //     );
    //     return amountETH;
    // }


    // **** SWAP ****

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to
    ) public returns (uint256[] memory amounts) {
        amounts = UniswapV2Library.getAmountsOut(address(factory), amountIn, path);
        if (amounts[amounts.length - 1] < amountOutMin)
            revert InsufficientOutputAmount();
        _safeTransferFrom(
            path[0], msg.sender, UniswapV2Library.pairFor(address(factory), path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, to);
    }

function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to
    ) public returns (uint[] memory amounts) {
        amounts = UniswapV2Library.getAmountsIn(address(factory), amountOut, path);
        if (amounts[amounts.length - 1] > amountInMax)
            revert ExcessiveInputAmount();
        _safeTransferFrom(
            path[0], msg.sender, UniswapV2Library.pairFor(address(factory), path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, to);
    }

    // function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    //     external
    //     virtual
    //     override
    //     payable
    //     ensure(deadline)
    //     returns (uint[] memory amounts)
    // {
    //     require(path[0] == WETH, 'UniswapV2Router: INVALID_PATH');
    //     amounts = UniswapV2Library.getAmountsOut(factory, msg.value, path);
    //     require(amounts[amounts.length - 1] >= amountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
    //     IWETH(WETH).deposit{value: amounts[0]}();
    //     assert(IWETH(WETH).transfer(UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]));
    //     _swap(amounts, path, to);
    // }
    // function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    //     external
    //     virtual
    //     override
    //     ensure(deadline)
    //     returns (uint[] memory amounts)
    // {
    //     require(path[path.length - 1] == WETH, 'UniswapV2Router: INVALID_PATH');
    //     amounts = UniswapV2Library.getAmountsIn(factory, amountOut, path);
    //     require(amounts[0] <= amountInMax, 'UniswapV2Router: EXCESSIVE_INPUT_AMOUNT');
    //     TransferHelper.safeTransferFrom(
    //         path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]
    //     );
    //     _swap(amounts, path, address(this));
    //     IWETH(WETH).withdraw(amounts[amounts.length - 1]);
    //     TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    // }
    // function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    //     external
    //     virtual
    //     override
    //     ensure(deadline)
    //     returns (uint[] memory amounts)
    // {
    //     require(path[path.length - 1] == WETH, 'UniswapV2Router: INVALID_PATH');
    //     amounts = UniswapV2Library.getAmountsOut(factory, amountIn, path);
    //     require(amounts[amounts.length - 1] >= amountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
    //     TransferHelper.safeTransferFrom(
    //         path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]
    //     );
    //     _swap(amounts, path, address(this));
    //     IWETH(WETH).withdraw(amounts[amounts.length - 1]);
    //     TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    // }
    // function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    //     external
    //     virtual
    //     override
    //     payable
    //     ensure(deadline)
    //     returns (uint[] memory amounts)
    // {
    //     require(path[0] == WETH, 'UniswapV2Router: INVALID_PATH');
    //     amounts = UniswapV2Library.getAmountsIn(factory, amountOut, path);
    //     require(amounts[0] <= msg.value, 'UniswapV2Router: EXCESSIVE_INPUT_AMOUNT');
    //     IWETH(WETH).deposit{value: amounts[0]}();
    //     assert(IWETH(WETH).transfer(UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]));
    //     _swap(amounts, path, to);
    //     // refund dust eth, if any
    //     if (msg.value > amounts[0]) TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0]);
    // }

    // **** SWAP (supporting fee-on-transfer tokens) ****
    // requires the initial amount to have already been sent to the first pair
    // function _swapSupportingFeeOnTransferTokens(address[] memory path, address _to) internal virtual {
    //     for (uint i; i < path.length - 1; i++) {
    //         (address input, address output) = (path[i], path[i + 1]);
    //         (address token0,) = UniswapV2Library.sortTokens(input, output);
    //         IUniswapV2Pair pair = IUniswapV2Pair(UniswapV2Library.pairFor(factory, input, output));
    //         uint amountInput;
    //         uint amountOutput;
    //         { // scope to avoid stack too deep errors
    //         (uint reserve0, uint reserve1,) = pair.getReserves();
    //         (uint reserveInput, uint reserveOutput) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    //         amountInput = IERC20(input).balanceOf(address(pair)).sub(reserveInput);
    //         amountOutput = UniswapV2Library.getAmountOut(amountInput, reserveInput, reserveOutput);
    //         }
    //         (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));
    //         address to = i < path.length - 2 ? UniswapV2Library.pairFor(factory, output, path[i + 2]) : _to;
    //         pair.swap(amount0Out, amount1Out, to, new bytes(0));
    //     }
    // }
    // function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    //     uint amountIn,
    //     uint amountOutMin,
    //     address[] calldata path,
    //     address to,
    //     uint deadline
    // ) external virtual override ensure(deadline) {
    //     TransferHelper.safeTransferFrom(
    //         path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amountIn
    //     );
    //     uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
    //     _swapSupportingFeeOnTransferTokens(path, to);
    //     require(
    //         IERC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
    //         'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT'
    //     );
    // }
    // function swapExactETHForTokensSupportingFeeOnTransferTokens(
    //     uint amountOutMin,
    //     address[] calldata path,
    //     address to,
    //     uint deadline
    // )
    //     external
    //     virtual
    //     override
    //     payable
    //     ensure(deadline)
    // {
    //     require(path[0] == WETH, 'UniswapV2Router: INVALID_PATH');
    //     uint amountIn = msg.value;
    //     IWETH(WETH).deposit{value: amountIn}();
    //     assert(IWETH(WETH).transfer(UniswapV2Library.pairFor(factory, path[0], path[1]), amountIn));
    //     uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
    //     _swapSupportingFeeOnTransferTokens(path, to);
    //     require(
    //         IERC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
    //         'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT'
    //     );
    // }
    // function swapExactTokensForETHSupportingFeeOnTransferTokens(
    //     uint amountIn,
    //     uint amountOutMin,
    //     address[] calldata path,
    //     address to,
    //     uint deadline
    // )
    //     external
    //     virtual
    //     override
    //     ensure(deadline)
    // {
    //     require(path[path.length - 1] == WETH, 'UniswapV2Router: INVALID_PATH');
    //     TransferHelper.safeTransferFrom(
    //         path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amountIn
    //     );
    //     _swapSupportingFeeOnTransferTokens(path, address(this));
    //     uint amountOut = IERC20(WETH).balanceOf(address(this));
    //     require(amountOut >= amountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
    //     IWETH(WETH).withdraw(amountOut);
    //     TransferHelper.safeTransferETH(to, amountOut);
    // }

    function _swap(
        uint256[] memory amounts,
        address[] memory path,
        address to_
    ) internal {
        for (uint256 i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0, ) = UniswapV2Library.sortTokens(input, output);
            uint256 amountOut = amounts[i + 1];
            (uint256 amount0Out, uint256 amount1Out) = input == token0
                ? (uint256(0), amountOut)
                : (amountOut, uint256(0));
            address to = i < path.length - 2
                ? UniswapV2Library.pairFor(
                    address(factory),
                    output,
                    path[i + 2]
                )
                : to_;
            IUniswapV2Pair(
                UniswapV2Library.pairFor(address(factory), input, output)
            ).swap(amount0Out, amount1Out, to, "");
        }
    }


    // **** LIBRARY FUNCTIONS ****
    // function quote(uint amountA, uint reserveA, uint reserveB) public pure virtual override returns (uint amountB) {
    //     return UniswapV2Library.quote(amountA, reserveA, reserveB);
    // }

    // function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut)
    //     public
    //     pure
    //     virtual
    //     override
    //     returns (uint amountOut)
    // {
    //     return UniswapV2Library.getAmountOut(amountIn, reserveIn, reserveOut);
    // }

    // function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut)
    //     public
    //     pure
    //     virtual
    //     override
    //     returns (uint amountIn)
    // {
    //     return UniswapV2Library.getAmountIn(amountOut, reserveIn, reserveOut);
    // }

    // function getAmountsOut(uint amountIn, address[] memory path)
    //     public
    //     view
    //     virtual
    //     override
    //     returns (uint[] memory amounts)
    // {
    //     return UniswapV2Library.getAmountsOut(factory, amountIn, path);
    // }

    // function getAmountsIn(uint amountOut, address[] memory path)
    //     public
    //     view
    //     virtual
    //     override
    //     returns (uint[] memory amounts)
    // {
    //     return UniswapV2Library.getAmountsIn(factory, amountOut, path);
    // }


    function _safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) private {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSignature(
                "transferFrom(address,address,uint256)",
                from,
                to,
                value
            )
        );
        if (!success || (data.length != 0 && !abi.decode(data, (bool))))
            revert SafeTransferFailed();
    }
}
