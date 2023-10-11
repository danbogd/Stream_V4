
// SPDX-License-Identifier: MIT 

pragma solidity 0.8.13;
pragma abicoder v2;// abicoder v2, позволяет кодировать и декодировать произвольные вложенные массивы и структуры в calldata.

import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';



/// @title Interface for WETH9
interface IWETH9 is IERC20 {
    /// @notice Deposit ether to get wrapped ether
    function deposit() external payable;

    /// @notice Withdraw wrapped ether to get ether
    function withdraw(uint256) external;
}

interface IERC20 {
   
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);
    
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

interface IRelayHub {
    function depositFor(address target) external payable;
    /// @return An account's balance. It can be either a deposit of a `Paymaster`, or a revenue of a Relay Manager.
    function balanceOf(address target) external view returns (uint256);
}

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(
    uint80 _roundId
  ) external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

  function latestRoundData()
    external
    view
    returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

contract MyBank {

    IWETH9 public constant WMatic = IWETH9(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
    ISwapRouter public immutable swapRouter;
    IRelayHub public relayHub = IRelayHub(0xfCEE9036EDc85cD5c12A9De6b267c4672Eb4bA1B);
    AggregatorV3Interface internal dataFeed = AggregatorV3Interface(0xAB594600376Ec9fD91F8e885dADF0CE036862dE0);// https://data.chain.link/polygon/mainnet/crypto-usd/matic-usd

    address public paymaster = 0x6eFb57A6ff65CAE8A0a600cfd2b617983c66A3fD;

    address public constant DAI = 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063;
    address public constant USDC = 0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359;
    address public constant USDT = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;
    address public constant WETH9 = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;// wMatic
    
    address public owner;
    // For this example, we will set the pool fee to 0.5%.
    uint24 public  poolFee = 3000;// https://info.uniswap.org/#/pools

    constructor(ISwapRouter _swapRouter) {
        swapRouter = _swapRouter; // 0xE592427A0AEce92De3Edee1F18E0157C05861564
         owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only Admin");
        _;
    }

  receive() external payable {}
   

    function changePoolFee(uint24 _newpollfee) external onlyOwner {
        poolFee = _newpollfee;
    }

   

    // обменивает фиксированное количество одного токена на максимально возможное количество другого токена.( fix one → max another )
    /// @notice swapExactInputSingle swaps a fixed amount of DAI for a maximum possible amount of WETH9
    /// using the DAI/WETH9 0.3% pool by calling `exactInputSingle` in the swap router.
    /// @dev The calling address must approve this contract to spend at least `amountIn` worth of its DAI for this function to succeed.
    /// @param amountIn The exact amount of DAI that will be swapped for WETH9.
    /// @return amountOut The amount of WETH9 received.
    function swapExactInputSingleDAI_Matic(uint256 amountIn) external returns (uint256 amountOut) {
        // msg.sender must approve this contract

        // Transfer the specified amount of DAI to this contract.
       //TransferHelper.safeTransferFrom(DAI, msg.sender, address(this), amountIn);

        // Approve the router to spend DAI.
        TransferHelper.safeApprove(DAI, address(swapRouter), amountIn);

        // Naively set amountOutMinimum to 0. In production, use an oracle or other data source to choose a safer value for amountOutMinimum.
        // We also set the sqrtPriceLimitx96 to be 0 to ensure we swap our exact input amount.
        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: DAI,// адрес контракта входящего токена
                tokenOut: WETH9,// адрес контракта исходящего токена
                fee: poolFee, // Уровень комиссии пула, используется для определения правильности контракта пула, в котором выполняется своп.
                recipient: address(this),// получатель средств
                deadline: block.timestamp,//время unix, по истечении которого своп не будет выполнен,используется для защиты от долго ожидающих транзакций и резких колебаний цен
                amountIn: amountIn,// 
                amountOutMinimum: 0,// amountOutMinimumмы устанавливаем на ноль,но в продакшене это дает определенный риск. 
                //Для реального проекта, это значение должно быть рассчитано с использованием нашего SDK или оракула цен в сети 
                //— это помогает защититься от получения нехарактерно плохих цен для сделки ,которые могут являться следствием работы фронта или любого другого типа манипулирования ценой.
                sqrtPriceLimitX96: 0// Мы устанавливаем в 0 — это делает этот парамент неактивным.В продакшене, 
                //это значение можно использовать для установки предела цены, по которой своп будет проходить в пуле. 
            });

        // The call to `exactInputSingle` executes the swap.
        amountOut = swapRouter.exactInputSingle(params);
        unwrap(amountOut);
        addData(amountOut, amountIn);
    }


    // Rates History

    struct TokenSwapData {
        uint256 maticOut;
        uint256 rate;
        uint256 time;
    }

    TokenSwapData[] public history;

    function lastHistoryNumber() external view returns (uint){
        return history.length;
    }

    function addData( uint amountOut, uint amountIn) private {
        uint currentRate = amountOut * 100 / amountIn;
        TokenSwapData memory tokenSwapData = TokenSwapData({maticOut: amountOut, rate:  currentRate, time: block.timestamp}); 
        history.push(tokenSwapData); 
    
    }

    










    /// @notice swapExactOutputSingle swaps a minimum possible amount of DAI for a fixed amount of WETH.
    /// @dev The calling address must approve this contract to spend its DAI for this function to succeed. As the amount of input DAI is variable,
    /// the calling address will need to approve for a slightly higher amount, anticipating some variance.
    /// @param amountOut The exact amount of WETH9 to receive from the swap.
    /// @param amountInMaximum The amount of DAI we are willing to spend to receive the specified amount of WETH9.
    /// @return amountIn The amount of DAI actually spent in the swap.
    function swapExactOutputSingle(uint256 amountOut, uint256 amountInMaximum) external returns (uint256 amountIn) {
        // Transfer the specified amount of DAI to this contract.
        TransferHelper.safeTransferFrom(DAI, msg.sender, address(this), amountInMaximum);

        // Approve the router to spend the specifed `amountInMaximum` of DAI.
        // In production, you should choose the maximum amount to spend based on oracles or other data sources to acheive a better swap.
        TransferHelper.safeApprove(DAI, address(swapRouter), amountInMaximum);

        ISwapRouter.ExactOutputSingleParams memory params =
            ISwapRouter.ExactOutputSingleParams({
                tokenIn: DAI,
                tokenOut: WETH9,
                fee: poolFee,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountOut: amountOut,
                amountInMaximum: amountInMaximum,
                sqrtPriceLimitX96: 0
            });

        // Executes the swap returning the amountIn needed to spend to receive the desired amountOut.
        amountIn = swapRouter.exactOutputSingle(params);

        // For exact output swaps, the amountInMaximum may not have all been spent.
        // If the actual amount spent (amountIn) is less than the specified maximum amount, we must refund the msg.sender and approve the swapRouter to spend 0.
        if (amountIn < amountInMaximum) {
            TransferHelper.safeApprove(DAI, address(swapRouter), 0);
            TransferHelper.safeTransfer(DAI, msg.sender, amountInMaximum - amountIn);
        }
    }


    function withdrawTokensFromContract(address _token, uint256 _amount) external  onlyOwner {
        uint256 balance = getTokenBalance(_token);
        require(balance >= _amount, 'Amount exceeds Balance');
        IERC20(_token).transfer(msg.sender, _amount);
    }

    function withdrawMaticFromContract(address payable _recipient, uint256 _amount) external onlyOwner{
        require(_amount <= address(this).balance, "Insufficient balance");
        
        (bool success, ) = _recipient.call{value: _amount}("");
        require(success, "Transfer failed");
    }

    // Admin

// Check current token balance of this contract i

    function getTokenBalance(address token) public view returns(uint) {
       return IERC20(token).balanceOf(address(this));
    }

    // Check current Matic balance of this contract

    function getMaticBalance() external view returns(uint) {
        return  address(this).balance;
    }

     function getDAIBalance() public view returns(uint) {
       return IERC20(DAI).balanceOf(address(this));
    }

    function getwMaticBalance() public view returns(uint) {
       return IERC20(WETH9).balanceOf(address(this));
    }



    function unwrap(uint _amount) private  {
        WMatic.withdraw(_amount);
        
    }


    // Paymaster functions

    function DepositForPaymaster (uint _value) external onlyOwner {
            relayHub.depositFor{value: _value}(paymaster);
    }

    function PaymasterBalance () external view returns (uint){
         return   relayHub.balanceOf(paymaster);
    }

    function ChangePaymaster (address _newPaymaster) external onlyOwner{
        require (_newPaymaster != address(0));
        paymaster = _newPaymaster;
    }


    // ChainLink data
    /**
     * Returns the latest answer Matic / USD / 100.
     */
    function getChainlinkDataFeedLatestAnswer() public view returns (int) {
        // prettier-ignore
        (
            /* uint80 roundID */,
            int answer,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = dataFeed.latestRoundData();
        return answer;
    }

 // Distribution fees for shareHolders

    uint256 constant public BASIS_POINTS = 10000;
    address public u60 = 0x5890308A84c791fA80b3655f922EF376b2062816;
    address public u25 = 0xa3B25b9D188E305052EF559EC85D8d7F079693e0;
    address public u15 = 0x9E91b1099b3c539903801fb2A21748930b725f79 ;
    


    function distributeFee (address _token)  external {// TODO Events
        IERC20 token = IERC20(_token);
        uint tokenAmount = token.balanceOf(address(this));
        uint amountU60 = tokenAmount * 6000 / BASIS_POINTS;// 60%
        uint amountU25 = tokenAmount * 2500 / BASIS_POINTS;// 25%
        uint amountU15 = tokenAmount * 1500 / BASIS_POINTS;// 15%
        token.transfer(amountU60, u60);
        token.transfer(amountU25, u25);
        token.transfer(amountU15, u15);
    }



}


