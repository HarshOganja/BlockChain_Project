// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Import the ContentRegistry contract
import "./ContentRegistry.sol";
import "./ReputationSystem.sol";

contract IncentiveSystem is Ownable {
    IERC20 public rewardToken;
    ContentRegistry public contentRegistry;
    ReputationSystem public reputationSystem;

    uint256 public verificationReward = 100;
    uint256 public reputationBonusMultiplier = 2;

    mapping(string => bool) public rewardedContent;

    event RewardsDistributed(
        address indexed recipient,
        uint256 amount,
        string contentHash
    );

    constructor(
        address _tokenAddress,
        address _contentRegistry,
        address _reputationSystem,
        address _initialOwner
    ) Ownable(_initialOwner) {
        rewardToken = IERC20(_tokenAddress);
        contentRegistry = ContentRegistry(_contentRegistry);
        reputationSystem = ReputationSystem(_reputationSystem);
    }

    function distributeRewards(string memory _contentHash) public onlyOwner {
        require(!rewardedContent[_contentHash], "Content already rewarded");

        (address author, , , bool isVerified, uint256 verificationScore, ) = 
            contentRegistry.getContent(_contentHash);

        require(isVerified, "Content not verified");

        uint256 reputationScore = reputationSystem.calculateTrustScore(author);
        uint256 baseReward = verificationReward * verificationScore / 100;
        uint256 reputationBonus = (baseReward * reputationScore * reputationBonusMultiplier) / 10000;
        uint256 totalReward = baseReward + reputationBonus;

        require(rewardToken.transfer(author, totalReward), "Token transfer failed");
        rewardedContent[_contentHash] = true;

        emit RewardsDistributed(author, totalReward, _contentHash);
    }

    function setVerificationReward(uint256 _newReward) public onlyOwner {
        verificationReward = _newReward;
    }

    function setReputationBonusMultiplier(uint256 _newMultiplier) public onlyOwner {
        reputationBonusMultiplier = _newMultiplier;
    }

    function withdrawTokens(uint256 _amount) public onlyOwner {
        require(rewardToken.transfer(owner(), _amount), "Token transfer failed");
    }
}