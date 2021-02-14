/** This is the staking contract implementation for the Reward Token. I consulted the below mentioned source for reference but my implementaion is completely different from theirs for reasoned described on the gigthub readme. 
 *     Reference: https://github.com/HQ20/StakingToken/blob/master/contracts/StakingToken.sol
 */

pragma solidity ^0.6.2;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error. SafeMath prevents overflow and underflow and throws if they occur.
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

// Defining the RewardToken Interface
abstract contract RewardToken {
    function transfer(address _to, uint256 _value) public virtual returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public virtual returns (bool success);
    function allowance(address _owner, address _spender) public virtual view returns (uint256 remaining);
    function balanceOf(address _owner) public virtual view returns (uint256 balance);
}


/**
 * @title RewardTokenStaker
 * @dev Implementation of the Reward Token staking contract
 */

contract RewardTokenStaker {
  using SafeMath for uint256;
  
  mapping(address => uint256) internal stakeBalances; //Maps participant addresses to their staked amount
  uint256 public totalStaked = 0; //The total amount of tokens staked in the staking contract at any point
  uint256 public stakerContractBalance = 0; //The amount of tokens in the balance of the Staker contract. The contract uses these funds to provides rewards to stakers.
  
  mapping(address => uint256) internal lastRewardBlock; //Maps participant addresses to their last reward block
  RewardToken internal constant associatedTokenContract = RewardToken(0xd26A24884402f1D3D9Dea5AA41ADfb26f65f477D);
  uint256 public constant rewardPerBlock = 100 * (10 ** 18); //The amount of tokens rewarded each block. This reward is divided among all stakers in proportion to their stake. Current reward is 100 tokens each block

  constructor() public
  {
    stakerContractBalance = associatedTokenContract.balanceOf(address(this)); //Update balance if predeployment transfer was made to address
  }

  /**
  * @dev Updates the staker contract's balance by looking at the ERC-20 contract. Includes both minted and staked tokens.
  */
  function updateStakerContractBalance() public
  {
    stakerContractBalance = associatedTokenContract.balanceOf(address(this)); //Update balance of the staker contract
  }
  
  /**
  * @dev deposit is called by the participant to stake their tokens. ERC-20 approve must be called before calling deposit. Throws if prior ERC-20 approval is not granted for staking
  * @param _value The value that the participant wants to stake
  */
  function deposit(uint256 _value) public
  {
    require(associatedTokenContract.transferFrom(msg.sender, address(this), _value) == true); //Take the staked tokens from the participant
    updateRewards(msg.sender); //Update rewards before depositing new tokens
    //if(stakeBalances[msg.sender] == 0) addStakeholder(msg.sender); //Add address to stakers list if existing stake balance is zero
    stakeBalances[msg.sender] = stakeBalances[msg.sender].add(_value); //Add balance to staker's account
    totalStaked = totalStaked.add(_value); //Increase total staked amount
    stakerContractBalance = associatedTokenContract.balanceOf(address(this)); //Update staker contract's token balance
  }
  
  /**
  * @dev updateRewards updates the rewards for the specified address depending on that address' stake amount
  * @param _address The participant address whose rewards are to be updated
  */
  function updateRewards(address _address) public validRecipient(_address)
  {
    if (lastRewardBlock[_address] != 0) {
      uint256 rewardsToGet = (block.number.sub(lastRewardBlock[_address])).mul(rewardPerBlock); // Rewards to distribute = (current_block - last_reward_block) * reward_per_block
      uint256 rewardForThisStaker = (stakeBalances[_address].mul(rewardsToGet)).div(totalStaked); // Reward for this staker = his stake * rewards / total stake
      stakeBalances[_address] = stakeBalances[_address].add(rewardForThisStaker); // Add reward to staked balance
      totalStaked = totalStaked.add(rewardForThisStaker); //Add reward to total staked count
    }
    lastRewardBlock[_address] = block.number;
  }
  
  /**
  * @dev viewBalance view function for querying the balance of any participant in the staking contract
  * @param _address The participant address whose balance is to be queried
  */
  function viewBalance(address _address) public view validRecipient(_address) returns (uint256 _balance)
  {
    return stakeBalances[_address];
  }
  
  /**
  * @dev viewLastRewardRound view function for querying the last round (block number) when the participant's rewards were updated
  * @param _address The participant address
  */
  function viewLastRewardRound(address _address) public view validRecipient(_address) returns (uint256 _round)
  {
    return lastRewardBlock[_address];
  }

  /**
  * @dev withdraw function to allow participants to withdraw their staked tokens
  */
  function withdraw() public
  {
    updateRewards(msg.sender); //Update rewards before withdrawing
    require(associatedTokenContract.transfer(msg.sender, stakeBalances[msg.sender]) == true); //Return the staked tokens to the participant
    totalStaked = totalStaked.sub(stakeBalances[msg.sender]); //Decrease total staked amount
    stakeBalances[msg.sender] = 0; //Empty the staker's account
    stakerContractBalance = associatedTokenContract.balanceOf(address(this)); //Update staker contract's token balance
  }

  // MODIFIERS

  modifier validRecipient(address _recipient) {
    require(_recipient != address(0) && _recipient != address(this));
    _;
  }

}
