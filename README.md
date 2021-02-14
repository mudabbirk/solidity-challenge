# challenge
create and deploy (locally) an ERC20 token and a staking contract that will distribute rewards to stakers over time. No need for an app or UI. You can reuse published or open source code, but you must indicate the source and what you have modified.

## User journey
An account with some balance of the tokens can deposit them into the staking contract (which also has the tokens and distributes them over time). As the time goes by and blocks are being produced, this user should accumulate more of the tokens and can claim the rewards and withdraw the deposit.

## RewardToken.sol
this contract defines an ERC20 token that will be used for staking/rewards. The owner should be able to mint the token.

## Staker.sol
this contract will get deployed with some tokens minted for the distribution to the stakers. And then, according to a schedule, allocate the reward tokens to addresses that deposited those tokens into the contract. The schedule is up to you, but you could say that every block 100 tokens are being distributed; then you'd take the allocated tokens and divide by the total balance of the deposited tokens so each depositor get's proportional share of the rewards. Ultimately, a user will deposit some tokens and later will be able to withdraw the principal amount plus the earned rewards. The following functions must be implemented: deposit(), withdraw()

## Scoring criteria
- launch ERC20 token
- implement reward allocation logic
- safe deposit/withdraw functions (avoid common attack vectors)


## SOLUTION


## Solution Design Choices
The ERC-20 implemention is pretty standard. For the Staker contract the following design choices were made:
1) Mapping was used to keep track of all staking participants rather than using dynamic arrays.
2) For staking, some implementations burn the staked tokens and re-mint them upon withdrawl to avoid user misbehaviour. I have taken a different approach. The tokens are instead transferred to the staker contract's address when staked hence barring stakers from gaming the system.
3) The staking participant uses the ERC-20 approve function to pre-approve the staker contract to take over their staked funds. A different approach could be to implement onTokenTransfer() receiver or to use burning instead of transferring.
4) The token and staker contracts are decoupled. When the staker contract is deployed, the token contract must send it tokens so that it can reward participants. This can be done pre or post deployment.
5) For rewarding, the scheme used is 100 tokens rewarded every block. The participants get a share of these tokens in propotion to their stake percentage.
6) Keep in mind that the token is implemented with 18 decimals. Hence the reward is represented as 100 ** 18. The total supply cap is 1 billion tokens. The ERC-20 starts with 100 million tokens and the miner can mint the rest but not go beyond the 1 billion hardcap.
7) For staking reward calculation, multiple strategies are possible. The current strategy is very simple. At the time of withdrawl, it determines the stake percentage of the participant and rewards them accordingly. The rewards are also updated every time a new deposit is made or by calling a reward update public function. So, participants essentially claim their rewards themselves. A different approach could be having the system administrators updating all contract's rewards periodically but then they would have to pay for the large amount of gas fee. Another way could be updating the rewards for all accounts each time a participant deposit or withdrawl is made. This places unneccessary gas fee burden on small participants and disincentivizes moving staked tokens.

## User Documentation:
1) Send funds to the Staker contract after deploying
2) The ERC-20 contract address is hardcoded in the staker contract and must be updated before deploying. 
3) For staking participants, the must first ERC-20 approve their stake amount before calling the deposit function.
4) Withdraw results in the withdrawl of the entire staked amount and fractional withdrawls have not been implemented for the sake of simplicity. 
