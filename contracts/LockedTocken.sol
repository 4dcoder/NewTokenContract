pragma solidity ^0.4.11;

import "./StandardToken.sol";


/** @title The AirSwap Token
  * An ERC20-compliant token that is only transferable after a
  * specified time. Holders also have the ability to lock an amount of tokens
  * for a period of time for applications that reference this locked amount
  * for example for licensing features.
  */
contract LockedToken is StandardToken {

    string public constant name = tSlava;
    string public constant symbol = "IML";
    uint8 public constant decimals = 4;
    uint256 public constant totalSupply = 5000000000000;

    address public tAndrey;
    address public tMichail;
    address public tSlava;


    // The time after which tokens become transferable.
    // Current value is December 18, 2017 10:10:10 Eastern Time.
    uint256 becomesTransferable = 1513555200;

    // The time that tokens are to be locked before becoming unlockable.
    // Current value is 7 days.
    uint256 lockingPeriod = 1521072000;

    // Prevents premature execution.
    modifier onlyAfter(uint256 _time) {
        require(now >= _time);
        _;
    }

    // Prevent premature execution for anyone but the owner.
    modifier onlyAfterOrOwner(uint256 _time, address _from) {
        if (_from != owner) {
            require(now >= _time);
        }
        _;
    }

    // Holds the amount and date of a given balance lock.
    struct BalanceLock {
        uint256 amount;
        uint256 unlockDate;
    }

    // A mapping of balance lock to a given address.
    mapping (address => BalanceLock) public balanceLocks;

    // An event to notify that _owner has locked a balance.
    event BalanceLocked(address indexed _owner, uint256 _oldLockedAmount,
    uint256 _newLockedAmount, uint256 _expiry);

    /** @dev Constructor for the contract.
      * @param _deployer The address that will initially hold all tokens.
      * @param _owner The address that will be able to transfer early.
      * @param _balance The initial balance for the owner.
      */
    function AirSwapToken(address _deployer, address _owner, uint256 _balance)
        Pausable() {
        transferOwnership(_owner);
        balances[_deployer] = totalSupply - _balance;
        balances[_owner] = _balance;
        Transfer(0x0, _deployer, totalSupply);
        Transfer(_deployer, _owner, _balance);
    }

    /** @dev Sets a token balance to be locked by the sender, on the condition
      * that the amount is equal or greater than the previous amount, or if the
      * previous lock time has expired.
      * @param _value The amount be locked.
      */
    function lockBalance(uint256 _value) {

        // Check if the lock on previously locked tokens is still active.
        if (balanceLocks[msg.sender].unlockDate > now) {
            // Only allow confirming the lock or adding to it.
            require(_value >= balanceLocks[msg.sender].amount);
        }
        // Ensure that no more than the balance can be locked.
        require(balances[msg.sender] >= _value);

        // Lock tokens and notify.
        uint256 _expiry = now + lockingPeriod;
        BalanceLocked(msg.sender, balanceLocks[msg.sender].amount, _value, _expiry);
        balanceLocks[msg.sender] = BalanceLock(_value, _expiry);
    }

    /** @dev Returns the balance that a given address has available for transfer.
      * @param _owner The address of the token owner.
      */
    function availableBalance(address _owner) constant returns(uint256) {
        if (balanceLocks[_owner].unlockDate < now) {
            return balances[_owner];
        } else {
            assert(balances[_owner] >= balanceLocks[_owner].amount);
            return balances[_owner] - balanceLocks[_owner].amount;
        }
    }

    /** @dev Send `_value` token to `_to` from `msg.sender`, on the condition
      * that there are enough unlocked tokens in the `msg.sender` account.
      * @param _to The address of the recipient.
      * @param _value The amount of token to be transferred.
      * @return Whether the transfer was successful or not.
      */
    function transfer(address _to, uint256 _value)
        onlyAfter(becomesTransferable) whenNotPaused
        returns (bool success) {
        require(availableBalance(msg.sender) >= _value);
        return super.transfer(_to, _value);
    }

    /** @dev Send `_value` token to `_to` from `_from` on the condition
      * that there are enough unlocked tokens in the `_from` account.
      * @param _from The address of the sender.
      * @param _to The address of the recipient.
      * @param _value The amount of token to be transferred.
      * @return Whether the transfer was successful or not.
      */
    function transferFrom(address _from, address _to, uint256 _value)
        onlyAfterOrOwner(becomesTransferable, _from) whenNotPaused
        returns (bool success) {
        require(availableBalance(_from) >= _value);
        return super.transferFrom(_from, _to, _value);
    }
}

}

}
