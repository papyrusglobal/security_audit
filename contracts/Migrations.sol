pragma solidity ^0.4.11;

import "./zeppelin/ownership/Ownable.sol";

/**
 * @title Migrations
 * @dev This is a truffle contract, needed for truffle integration.
 */
contract Migrations is Ownable {
  
  uint256 public lastCompletedMigration;

  function setCompleted(uint256 completed) onlyOwner {
    lastCompletedMigration = completed;
  }

  function upgrade(address newAddress) onlyOwner {
    Migrations upgraded = Migrations(newAddress);
    upgraded.setCompleted(lastCompletedMigration);
  }
  
}
