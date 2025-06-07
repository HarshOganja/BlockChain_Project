// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ReputationSystem {
    address public contentRegistry;
    mapping(address => uint256) public trustScores;

    event ContentRegistrySet(address indexed contentRegistry, address indexed caller);
    event OnlyContentRegistryCheck(address indexed sender, address indexed contentRegistry);
    event ReputationUpdated(address indexed user, uint256 oldScore, uint256 amount, uint256 newScore, bool increased);

    modifier onlyContentRegistry() {
        emit OnlyContentRegistryCheck(msg.sender, contentRegistry);
        require(msg.sender == contentRegistry, "Only ContentRegistry can call");
        require(contentRegistry != address(0), "ContentRegistry not set");
        _;
    }

    constructor() {}

    function initializeContentRegistry(address _contentRegistry) external {
        require(_contentRegistry != address(0), "Invalid ContentRegistry address");
        require(contentRegistry == address(0), "ContentRegistry already set");
        contentRegistry = _contentRegistry;
        emit ContentRegistrySet(_contentRegistry, msg.sender);
    }

    function calculateTrustScore(address user) public view returns (uint256) {
        return trustScores[user] == 0 ? 50 : trustScores[user];
    }

    function updateTrustScore(address user, uint256 score) external onlyContentRegistry {
        require(user != address(0), "Invalid user address");
        uint256 oldScore = trustScores[user] == 0 ? 50 : trustScores[user];
        trustScores[user] = score;
        emit ReputationUpdated(user, oldScore, score, score, false);
    }

    function increaseTrustScore(address user, uint256 amount) external onlyContentRegistry {
        require(user != address(0), "Invalid user address");
        uint256 oldScore = trustScores[user] == 0 ? 50 : trustScores[user];
        trustScores[user] = oldScore + amount;
        emit ReputationUpdated(user, oldScore, amount, trustScores[user], true);
    }

    function decreaseTrustScore(address user, uint256 amount) external onlyContentRegistry {
        require(user != address(0), "Invalid user address");
        uint256 oldScore = trustScores[user] == 0 ? 50 : trustScores[user];
        trustScores[user] = oldScore > amount ? oldScore - amount : 0;
        emit ReputationUpdated(user, oldScore, amount, trustScores[user], false);
    }

    function getContentRegistry() external view returns (address) {
        return contentRegistry;
    }
}