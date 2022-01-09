pragma solidity ^0.4.22;

/******************* Imports **********************/
import "./erc20interface.sol";
import "./safemath.sol";
import "./Ownable.sol";

/// @title A staking smart contract
/// @author M.Armaghan Raza
/// @notice This smart contract serves as a staking pool where users can stake against and get rewards.
contract Staking is Ownable {
    using SafeMath for uint;
    
    uint BIGNUMBER = 10**18;
    uint DECIMAL = 10**3;

    /******************* State Variables **********************/
    /// @notice This struct stores information regarding staking info details.
    struct stakingInfo {
        uint amount;
    }
    
    
    //allowed token addresses
    mapping (address => bool) public allowedTokens;
    
    // @notice tokenAddr to user to stake amount.
    mapping (address => mapping(address => stakingInfo)) public StakeMap;
    
    // @notice tokenAddr to user to remaining claimable amount per stake.
    mapping (address => mapping(address => uint)) public userCummRewardPerStake;

    // @notice tokenAddr to cummulative per token reward since the beginning or time.
    mapping (address => uint) public tokenCummRewardPerStake;

    // @notice tokenAddr to total token claimed.
    mapping (address => uint) public tokenTotalStaked;
  
    // @notice modifieer to validate TokenAddress.    
    modifier isValidToken(address _tokenAddr){
        require(allowedTokens[_tokenAddr]);
        _;
    }

    // @notice Stores stake tokenAddress.
    address public StakeTokenAddr;
    
    constructor(address _tokenAddr) public{
        StakeTokenAddr= _tokenAddr;
    }
    
    
    /**
    * @dev add approved token address to the mapping 
    */
    
    function addToken( address _tokenAddr) onlyOwner external {
        allowedTokens[_tokenAddr] = true;
    }
    
    /**
    * @dev remove approved token address from the mapping 
    */
    function removeToken( address _tokenAddr) onlyOwner external {
        allowedTokens[_tokenAddr] = false;
    }

    /**
    * @dev stake a specific amount to a token
    * @param _amount the amount to be staked
    * @param _tokenAddr the token the user wish to stake on
    * for demo purposes, not requiring user to actually send in tokens right now
    */
    
    function stake(uint _amount, address _tokenAddr) isValidToken(_tokenAddr) external returns (bool){
        require(_amount != 0);
        require(ERC20(StakeTokenAddr).transferFrom(msg.sender,this,_amount));
        
        if (StakeMap[_tokenAddr][msg.sender].amount ==0){
            StakeMap[_tokenAddr][msg.sender].amount = _amount;
            userCummRewardPerStake[_tokenAddr][msg.sender] = tokenCummRewardPerStake[_tokenAddr];
        }else{
            claim(_tokenAddr, msg.sender);
            StakeMap[_tokenAddr][msg.sender].amount = StakeMap[_tokenAddr][msg.sender].amount.add( _amount);
        }
        tokenTotalStaked[_tokenAddr] = tokenTotalStaked[_tokenAddr].add(_amount);
        return true;
    }
    
    
    /**
     * demo version
    * @dev pay out dividends to stakers, update how much per token each staker can claim
    * @param _reward the aggregate amount to be send to all stakers
    * @param _tokenAddr the token that this dividend gets paied out in
    */
    function distribute(uint _reward,address _tokenAddr) isValidToken(_tokenAddr) external onlyOwner returns (bool){
        require(tokenTotalStaked[_tokenAddr] != 0);
        uint reward = _reward.mul(BIGNUMBER); //simulate floating point operations
        uint rewardAddedPerToken = reward/tokenTotalStaked[_tokenAddr];
        tokenCummRewardPerStake[_tokenAddr] = tokenCummRewardPerStake[_tokenAddr].add(rewardAddedPerToken);
        return true;
    }
    
    // /**
    // * production version
    // * @dev pay out dividends to stakers, update how much per token each staker can claim
    // * @param _reward the aggregate amount to be send to all stakers
    // */
    
    // function distribute(uint _reward) isValidToken(msg.sender) external returns (bool){
    //     require(tokenTotalStaked[msg.sender] != 0);
    //     uint reward = _reward.mul(BIGNUMBER);
    //     tokenCummRewardPerStake[msg.sender] += reward/tokenTotalStaked[msg.sender];
    //     return true;
    // } 
    
    
    event claimed(uint amount);
    /**
    * @dev claim dividends for a particular token that user has stake in
    * @param _tokenAddr the token that the claim is made on
    * @param _receiver the address which the claim is paid to
    */
    function claim(address _tokenAddr, address _receiver) isValidToken(_tokenAddr)  public returns (uint) {
        uint stakedAmount = StakeMap[_tokenAddr][msg.sender].amount;
        //the amount per token for this user for this claim
        uint amountOwedPerToken = tokenCummRewardPerStake[_tokenAddr].sub(userCummRewardPerStake[_tokenAddr][msg.sender]);
        uint claimableAmount = stakedAmount.mul(amountOwedPerToken); //total amoun that can be claimed by this user
        claimableAmount = claimableAmount.mul(DECIMAL); //simulate floating point operations
        claimableAmount = claimableAmount.div(BIGNUMBER); //simulate floating point operations
        userCummRewardPerStake[_tokenAddr][msg.sender]=tokenCummRewardPerStake[_tokenAddr];
        if (_receiver == address(0)){
            require(ERC20(_tokenAddr).transfer(msg.sender,claimableAmount));
        } else {
           require(ERC20(_tokenAddr).transfer(_receiver,claimableAmount));
        }
        emit claimed(claimableAmount);
        return claimableAmount;

    }
    
    /**
    * @dev Unstake
    */
    function unstake(uint _amount, address _tokenAddr) isValidToken(_tokenAddr)  external returns(bool){
        require(StakeMap[_tokenAddr][msg.sender].amount >0 );
        claim(_tokenAddr, msg.sender);
        require(ERC20(_tokenAddr).transfer(msg.sender,_amount));
        tokenTotalStaked[_tokenAddr] = tokenTotalStaked[_tokenAddr].sub(_amount);
        return true;
    }
    
}