// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ReputationSystem.sol";

contract ContentRegistry {
    ReputationSystem public reputationSystem;

    struct Verification {
        address verifier;
        uint256 score;
        uint256 timestamp;
    }

    struct Content {
        address author;
        string ipfsHash;
        uint256 timestamp;
        bool isVerified;
        uint256 verificationScore;
        address[] factCheckers;
        Verification[] verifications;
    }

    mapping(string => Content) public contents;
    string[] private contentHashes;

    uint256 public constant MIN_VERIFIERS = 3;
    uint256 public constant SCORE_THRESHOLD = 70;
    uint256 public constant MIN_REPUTATION_TO_VERIFY = 35;
    uint256 public constant MIN_REPUTATION_TO_REGISTER = 30;

    event VerificationAdded(string indexed ipfsHash, address indexed verifier, uint256 score);
    event ContentVerified(string indexed ipfsHash, uint256 verificationScore, bool isCorrect);
    event ReputationChange(address indexed user, string action, uint256 amount, uint256 oldScore, uint256 newScore);

    constructor(address _reputationSystem) {
        require(_reputationSystem != address(0), "Invalid ReputationSystem address");
        reputationSystem = ReputationSystem(_reputationSystem);
        reputationSystem.initializeContentRegistry(address(this));
    }

    function registerContent(string memory ipfsHash) external {
        require(bytes(ipfsHash).length > 0, "Invalid IPFS hash");
        require(contents[ipfsHash].author == address(0), "Content already registered");

        uint256 authorReputation = reputationSystem.calculateTrustScore(msg.sender);
        require(authorReputation >= MIN_REPUTATION_TO_REGISTER, "Reputation too low to register content");

        Content storage content = contents[ipfsHash];
        content.author = msg.sender;
        content.ipfsHash = ipfsHash;
        content.timestamp = block.timestamp;
        content.isVerified = false;
        content.verificationScore = 0;

        contentHashes.push(ipfsHash);
    }

    function verifyContent(string memory ipfsHash, uint256 score) external {
        Content storage content = contents[ipfsHash];
        require(content.author != address(0), "Content not found");
        require(content.author != msg.sender, "Cannot verify own content");
        require(content.verifications.length < MIN_VERIFIERS, "Max verifications reached");
        require(score <= 100, "Score must be 0-100");

        uint256 verifierReputation = reputationSystem.calculateTrustScore(msg.sender);
        require(verifierReputation > MIN_REPUTATION_TO_VERIFY, "Reputation too low to verify");

        for (uint i = 0; i < content.verifications.length; i++) {
            require(content.verifications[i].verifier != msg.sender, "Already verified");
        }

        content.verifications.push(Verification({
            verifier: msg.sender,
            score: score,
            timestamp: block.timestamp
        }));
        content.factCheckers.push(msg.sender);

        emit VerificationAdded(ipfsHash, msg.sender, score);

        if (content.verifications.length == MIN_VERIFIERS) {
            require(content.factCheckers.length == MIN_VERIFIERS, "FactCheckers length mismatch");
            content.isVerified = true;

            // Calculate average score
            uint256 totalScore = 0;
            for (uint i = 0; i < content.verifications.length; i++) {
                totalScore += content.verifications[i].score;
            }
            content.verificationScore = totalScore / MIN_VERIFIERS;

            bool isCorrect = content.verificationScore > SCORE_THRESHOLD;
            emit ContentVerified(ipfsHash, content.verificationScore, isCorrect);

            // Update verifiers' reputations
            for (uint i = 0; i < MIN_VERIFIERS; i++) {
                address verifier = content.factCheckers[i];
                uint256 verifierScore = content.verifications[i].score;
                uint256 currentRep = reputationSystem.calculateTrustScore(verifier);

                if (isCorrect) {
                    if (verifierScore >= SCORE_THRESHOLD) {
                        uint256 reward = (verifierScore - SCORE_THRESHOLD) / 10 + 5;
                        reputationSystem.increaseTrustScore(verifier, reward);
                        emit ReputationChange(verifier, "VerifierReward", reward, currentRep, currentRep + reward);
                    } else {
                        uint256 penalty = (SCORE_THRESHOLD - verifierScore) / 5;
                        if (penalty > 0) {
                            reputationSystem.decreaseTrustScore(verifier, penalty);
                            emit ReputationChange(verifier, "VerifierPenalty", penalty, currentRep, currentRep - penalty);
                        } else {
                            emit ReputationChange(verifier, "VerifierNoChange", 0, currentRep, currentRep);
                        }
                    }
                } else {
                    if (verifierScore >= SCORE_THRESHOLD) {
                        uint256 penalty = (verifierScore - SCORE_THRESHOLD) / 5;
                        if (penalty > 0) {
                            reputationSystem.decreaseTrustScore(verifier, penalty);
                            emit ReputationChange(verifier, "VerifierPenalty", penalty, currentRep, currentRep - penalty);
                        } else {
                            emit ReputationChange(verifier, "VerifierNoChange", 0, currentRep, currentRep);
                        }
                    } else {
                        uint256 reward = (SCORE_THRESHOLD - verifierScore) / 10 + 5;
                        reputationSystem.increaseTrustScore(verifier, reward);
                        emit ReputationChange(verifier, "VerifierReward", reward, currentRep, currentRep + reward);
                    }
                }
            }

            // Update author's reputation
            uint256 authorCurrentRep = reputationSystem.calculateTrustScore(content.author);
            if (isCorrect) {
                uint256 authorReward = content.verificationScore / 5;
                reputationSystem.increaseTrustScore(content.author, authorReward);
                emit ReputationChange(content.author, "AuthorReward", authorReward, authorCurrentRep, authorCurrentRep + authorReward);
            } else {
                uint256 authorPenalty = (100 - content.verificationScore) / 5;
                if (authorPenalty > 0) {
                    reputationSystem.decreaseTrustScore(content.author, authorPenalty);
                    emit ReputationChange(content.author, "AuthorPenalty", authorPenalty, authorCurrentRep, authorCurrentRep - authorPenalty);
                } else {
                    emit ReputationChange(content.author, "AuthorNoChange", 0, authorCurrentRep, authorCurrentRep);
                }
            }
        }
    }

    function getAllContentHashes() external view returns (string[] memory) {
        return contentHashes;
    }

    function getContent(string memory ipfsHash) external view returns (
        address author,
        string memory hash,
        uint256 timestamp,
        bool isVerified,
        uint256 verificationScore,
        address[] memory factCheckers,
        Verification[] memory verifications
    ) {
        Content storage content = contents[ipfsHash];
        require(content.author != address(0), "Content not found");
        return (
            content.author,
            content.ipfsHash,
            content.timestamp,
            content.isVerified,
            content.verificationScore,
            content.factCheckers,
            content.verifications
        );
    }
}