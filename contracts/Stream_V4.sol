
// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@opengsn/contracts/src/ERC2771Recipient.sol";

interface IERC20 {
    
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);
    
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

}
interface IERC20Permit {
    
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
} 

// interface of the History contract - dataBase

interface IHistory{

    struct WithDraw{
            uint256 amount;
            uint256 timeW;
        }

    struct StreamHistory {
            
            uint256 deposit;
            
            uint64 startTime;
            uint64 stopTime;
            uint64 blockTime;
            uint64 cancelTime;

            uint256 recipientAmountOnCancel;
                        
            address payable sender;
            uint32 numberOfWithdraws;

            address payable recipient;
            uint8 status; //1 canceled, 2 paused
            uint8 whoCancel;
            
            string purpose;
            
        }

    

    function addUserId(address payable _user, uint256 _id ) external;


     function addStream(
       uint256 streamId, 
       address payable recipient,
       address payable sender, 
       uint256 deposit, 
       uint64 startTime, 
       uint64 stopTime, 
       uint64 blockTime, 
       string memory title,
       uint8 whoCancel
       
    ) external;
 
    function addWithdraw(uint256 _id, uint256 _amount) external;

    function addCancel (uint256 _id, uint256 _amount) external;

    function getHistoryStream(uint256 _id) external view returns(StreamHistory memory streamHistory);
}




abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract ERC2771Context is Context {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address private immutable _trustedForwarder;

    /**
     * @dev Initializes the contract with a trusted forwarder, which will be able to
     * invoke functions on this contract on behalf of other accounts.
     *
     * NOTE: The trusted forwarder can be replaced by overriding {trustedForwarder}.
     */
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address trustedForwarder_) {
        _trustedForwarder = trustedForwarder_;
    }

    /**
     * @dev Returns the address of the trusted forwarder.
     */
    function trustedForwarder() public view virtual returns (address) {
        return _trustedForwarder;
    }

    /**
     * @dev Indicates whether any particular address is the trusted forwarder.
     */
    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == trustedForwarder();
    }

    /**
     * @dev Override for `msg.sender`. Defaults to the original `msg.sender` whenever
     * a call is not performed by the trusted forwarder or the calldata length is less than
     * 20 bytes (an address length).
     */
    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender) && msg.data.length >= 20) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    /**
     * @dev Override for `msg.data`. Defaults to the original `msg.data` whenever
     * a call is not performed by the trusted forwarder or the calldata length is less than
     * 20 bytes (an address length).
     */
    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender) && msg.data.length >= 20) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }
}



abstract contract Ownable is ERC2771Context {

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

abstract contract Pausable is Ownable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () {
        //_paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function pause() external onlyOwner whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function unpause() external onlyOwner whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}





// Main stream conntract

contract MyStream is Pausable, IERC20, IERC20Permit {
    
          
    // Variables
    IHistory public  history; 
    uint256 public nextStreamId;
   // uint256 public  fee;
   string public versionRecipient = "3.0.0";
    
     constructor(address _history, uint _nextStreamId, address forwarder)  {
        require(_history != address(0), "zero address");
        require(_nextStreamId != 0, "Stream id is zero");
        history = IHistory(_history);
        nextStreamId = _nextStreamId;
        _setTrustedForwarder(forwarder);
    }
    
    //Mappings
    
    mapping(uint256 => Stream) private streams;
    uint256 public contractFeeBalance;
    
    //Modifiers
    
     
    modifier onlySenderOrRecipient(uint256 streamId) {
        IHistory.StreamHistory memory s = IHistory(history).getHistoryStream(streamId);
        
        require(
            _msgSender() == s.sender || _msgSender() == s.recipient,
            "caller is not the sender/recipient"
        );
        _;
    }

    modifier onlyRecipient(uint256 streamId) {
        IHistory.StreamHistory memory s = IHistory(history).getHistoryStream(streamId);
        require(_msgSender() == s.recipient,
            "caller is not the recipient"
        );
        _;
    }

   
    modifier streamExists(uint256 streamId) {
        require(streams[streamId].isEntity, "stream does not exist");
        _;
    }

    
    
       
    // Structs
    struct Stream{
        uint256 ratePerSecond;
        uint256 remainingBalance;
        uint256 remainder; 
        bool isEntity;
        
    }
    
       
      
    
    struct CreateStreamLocalVars {
        
        uint256 duration;
        uint256 ratePerSecond;
    }
    
    struct BalanceOfLocalVars {
        
        uint256 recipientBalance;
        uint256 withdrawalAmount;
        uint256 senderBalance;
    }
    
    
    
    // Events
     
    event withdrawFee(
        uint256 amount,
        address indexed reciver
    );

   
    address public bank;

    function setBank(address _newBank) external onlyOwner {
        bank = _newBank;
    }
   
    
    function createStream(
    address tokenAddress, 
    uint256 deposit, 
    address payable recipient, 
    uint64 startTime, 
    uint64 stopTime, 
    uint64 blockTime, 
    uint8 whoCancel, 
    string memory title,
    uint8 v,
    bytes32 r,
    bytes32 s
    ) 
    whenNotPaused  public  returns (uint256){
               
        //noContracts(msg.sender);
        //noContracts(recipient);
        uint fee = feeCharge(deposit);
        
        uint256 realDeposit = deposit + fee;
        require (deposit >= 5e18,"Wrong deposit");// TODO
        
        
        unchecked{ 
        contractFeeBalance = contractFeeBalance + fee;
        }
        if (startTime == 0){
            startTime = uint64(block.timestamp);// convert to uint64(block.timestamp)
        }

        
        require (whoCancel < 4, "Invalid input");
        require(recipient != address(0), "stream to the zero address");
        require(recipient != address(this), "stream to the contract itself");
        require(recipient != _msgSender(), "stream to the caller");
        require(deposit != 0, "deposit is zero");
        require(startTime >= block.timestamp, "startTime before block.timestamp");
        require(stopTime > startTime, "Invalid stop/start time");
        require (blockTime == 0 || blockTime <= stopTime, "Invalid blockTime");

        //function permit(address owner, IAllowanceTransfer.PermitSingle memory permitSingle, bytes calldata signature) external
        
        IERC20 token = IERC20(tokenAddress);
        IERC20Permit Ierc20permit = IERC20Permit(tokenAddress);
        uint noncE = Ierc20permit.nonces(_msgSender());
        Ierc20permit.permit(_msgSender(),
        address(this),
        noncE++,//?
        block.timestamp,
        true,
        v,
        r,
        s
        // uint8 v,
        // bytes32 r,
        // bytes32 s
    ); 
        token.transferFrom(msg.sender, address(this), deposit);
        token.transferFrom(msg.sender, bank, fee);
        CreateStreamLocalVars memory vars;

        unchecked{
        vars.duration = stopTime - startTime;
        }

        /* Without this, the rate per second would be zero. */
        require(deposit >= vars.duration, "deposit smaller than time delta");

        uint256 rem;// remainder
                
        if (deposit % vars.duration == 0){
            rem = 0;
        }
        
        else{
            rem = deposit % vars.duration;
        }

        vars.ratePerSecond = deposit / vars.duration;
        
        
        /* Create and store the stream object. */
        uint256 streamId = nextStreamId;
        streams[streamId] = Stream({
            remainingBalance: deposit,
            isEntity: true,
            ratePerSecond: vars.ratePerSecond,
            remainder: rem
           
        });

        /* Increment the next stream id. */
        unchecked{
        nextStreamId = nextStreamId + 1;
        }
        
              
       
        addToHistory(
          streamId,
          recipient,
          payable(_msgSender()), 
          deposit, 
          startTime, 
          stopTime, 
          blockTime, 
          title,
          whoCancel
          

        );

        //distribute(payable(msg.sender), recipient);       
        
        return streamId;
    }

    mapping (address => bool) public tokensList;

    function addToken (address _token) external onlyOwner{
        require (_token != address(0), "Zero token address");
        tokensList[_token] = true;

    }

    uint public feeRate = 100;

    function changeFeeRate(uint _newFeeRate) external onlyOwner{
        require (feeRate <= 2000, "FeeRate too large");
        feeRate = _newFeeRate;
    }


    function feeCharge (uint256 deposit) public view returns (uint256){//TODO change to internal
        return deposit * feeRate / 10000;
    }

    
   

    

    

   

       
    
   function addToHistory (
       uint256 streamId, 
       address payable recipient,
       address payable sender, 
       uint256 deposit, 
       uint64 startTime, 
       uint64 stopTime, 
       uint64 blockTime, 
       string memory title,
       uint8 whoCancel
       ) internal {
      
      IHistory(history).addStream(
          streamId,
          recipient,
          sender, 
          deposit, 
          startTime, 
          stopTime, 
          blockTime, 
          title,
          whoCancel
          );
   }

   
   function noContracts(address _sender) internal view {
        uint32 size;
        assembly {
            size := extcodesize(_sender)
        }
        require (size == 0,"No contracts"); 
    }
  

    function getStream(uint256 id)external view returns(Stream memory stream){
    return streams[id];
    }

    
    // 92262 gas 60148
    function cancelStream(uint256 streamId)
        external
        streamExists(streamId)
        onlySenderOrRecipient(streamId)
        returns (bool)
    {
            
        cancelStreamInternal(streamId);
        
        return true;
    }
    
    
    function cancelStreamInternal(uint256 streamId) private {
        
        IHistory.StreamHistory memory s = IHistory(history).getHistoryStream(streamId);
        
        
        
        require (s.blockTime <= block.timestamp,"stream blocked");
        require (s.stopTime >= block.timestamp, "stream finished");

               
        if (_msgSender() == s.sender && s.whoCancel != 1 && s.whoCancel != 3 ){
            revert();
        }
        if (_msgSender() == s.recipient && s.whoCancel  != 2 && s.whoCancel != 3){
            revert();
        }
        
        
        uint256 senderBalance = balanceOf(streamId, s.sender);
        uint256 recipientBalance = balanceOf(streamId, s.recipient);
        

       

       history.addCancel(streamId, recipientBalance);

       delete streams[streamId];

       
        if (recipientBalance != 0){
               (bool success1, ) = s.recipient.call{value: recipientBalance}("");//TODO
               require(success1, "recipient transfer failure");
        }     
        
                     
        if (senderBalance != 0){
                (bool success1, ) = s.sender.call{value: senderBalance}("");//TODO
                require(success1, "recipient transfer failure");
        }    
            
    }
    
    function balanceOf(uint256 streamId, address who) public view streamExists(streamId) returns (uint256 balance) {
        IHistory.StreamHistory memory s = IHistory(history).getHistoryStream(streamId);
        Stream memory stream = streams[streamId];
        BalanceOfLocalVars memory vars;

        uint256 delta = deltaOf(streamId);
        vars.recipientBalance = delta * stream.ratePerSecond + stream.remainder;
        
        /*
         * If the stream `balance` does not equal `deposit`, it means there have been withdrawals.
         * We have to subtract the total amount withdrawn from the amount of money that has been
         * streamed until now.
         */
        if (s.deposit > stream.remainingBalance) {
            vars.withdrawalAmount = s.deposit - stream.remainingBalance;
            
            vars.recipientBalance = vars.recipientBalance - vars.withdrawalAmount;
            
        }

        if (who == s.recipient) return vars.recipientBalance;
        if (who == s.sender) {
            vars.senderBalance = stream.remainingBalance - vars.recipientBalance;
            
            return vars.senderBalance;
        }
        return 0;
    }
    

    // Calculate current stream time
    function deltaOf(uint256 streamId) internal view streamExists(streamId) returns (uint256 delta) {
        
        IHistory.StreamHistory memory s = IHistory(history).getHistoryStream(streamId);
        
        if (block.timestamp <= s.startTime) return 0;
        
        if (block.timestamp < s.stopTime) return block.timestamp - s.startTime;
        
        return s.stopTime - s.startTime;
    }
    
    
    
    
    function withdrawFromStream(uint256 streamId, uint256 amount)
        external
        //whenNotPaused
        streamExists(streamId)
        onlyRecipient(streamId)
        returns (bool)
    {
        require(amount != 0, "amount is zero");
        
       
        IHistory.StreamHistory memory s = IHistory(history).getHistoryStream(streamId);
        require (s.startTime <= block.timestamp,"stream not started");
        uint256 balance = balanceOf(streamId, s.recipient);
        
        require(balance >= amount, "amount exceeds the available balance");
        address recipient = s.recipient;
        withdrawFromStreamInternal(streamId, amount, recipient);

        history.addWithdraw (streamId, amount); 
        
        return true;
    }
    
    function withdrawFromStreamInternal(uint256 streamId, uint256 amount,  address recipient) internal {
        Stream memory stream = streams[streamId];
        
        uint256 rem2 = streams[streamId].remainder;
        //streams[streamId].remainingBalance = stream.remainingBalance - amount;
        streams[streamId].remainingBalance = stream.remainingBalance + rem2 - amount;// TODO check
        streams[streamId].remainder = 0;

        if (streams[streamId].remainingBalance == 0) delete streams[streamId];
        
        (bool sent, ) = recipient.call{value: amount}("");
        require(sent, "Failed to send Ether");        
          
       
        
               
        
        
        
        
    }
    
     // Admin functions
     
    // WithDraw fees

     struct AdminWithdraw{
        uint amount;
        uint time;
        address who;

    } 
    
    uint public numberOfFeeWithdraws;
    mapping (uint256 => AdminWithdraw) public withdraws;
    // WithDraw fees  
    
    function withdrawFeeForHolders(uint256 amount, address reciver) external onlyOwner returns (bool){
        require (amount <= contractFeeBalance);
        require(reciver != address(0));
        require (amount > 0);
        ++ numberOfFeeWithdraws;
       
       withdraws[numberOfFeeWithdraws] = AdminWithdraw({
            amount: amount,
            time: block.timestamp,
            who : reciver
           
        });

        contractFeeBalance = contractFeeBalance - amount;
        (bool success, ) = reciver.call{value: amount}("");
        require(success, "Failed to send Ether");  
        
        emit withdrawFee (amount, reciver);
        return true;
    }


// Batch streams
    function batchStream(

        uint256[] calldata deposit,
        address payable[] calldata recipient,
        uint64[3][] calldata time,
        uint8[] calldata whoCancel, 
        string[] memory title

        ) external whenNotPaused returns (bool){

       uint len = deposit.length;

       require (len == recipient.length);
       require (len == whoCancel.length);
       require (len == time.length);
       require (len == title.length);

            for (uint i; i < len; ) {

                    createStream
                        (deposit[i],
                        recipient [i],
                        time[i][0],
                        time[i][1], 
                        time[i][2], 
                        whoCancel[i], 
                        title[i]);
                    
                    
                    unchecked { ++i; }
            }
        
        return true;
    }
    
}