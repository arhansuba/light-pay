// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title Migrations
 * @dev This contract is used to manage the migration of smart contracts in Ethereum development frameworks.
 * It ensures that migrations are executed only once.
 */
contract Migrations {
    address public owner;
    uint public last_completed_migration;

    modifier restricted() {
        require(msg.sender == owner, "Only the owner can call this");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Set the last completed migration.
     * @param completed The migration number that has been completed.
     */
    function setCompleted(uint completed) public restricted {
        last_completed_migration = completed;
    }

    /**
     * @dev Upgrade the Migrations contract.
     * @param new_address The address of the new Migrations contract.
     */
    function upgrade(address new_address) public restricted {
        Migrations upgraded = Migrations(new_address);
        upgraded.setCompleted(last_completed_migration);
    }
}
