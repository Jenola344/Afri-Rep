// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IAfriRep {
    // Admin functions
    function addSkill(
        string memory _skillId,
        string memory _name,
        string memory _category
    ) external;

    function setCountryMultiplier(
        string memory _countryCode,
        uint256 _multiplier
    ) external;

    // User functions
    function registerUser(
        string memory _name,
        string memory _countryCode,
        string memory _profileImageHash
    ) external;

    function giveVouch(
        address _to,
        string memory _skillId,
        uint256 _confidence,
        string memory _comment,
        string memory _evidenceHash
    ) external returns (bytes32);

    // View functions
    function getUserProfile(address _user)
        external
        view
        returns (
            string memory name,
            string memory countryCode,
            uint256 reputationScore,
            bool isVerified,
            string memory profileImageHash,
            uint256 lastActivity
        );

    function getUserVouches(address _user)
        external
        view
        returns (bytes32[] memory);
}