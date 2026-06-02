// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

/**
 * @title BuyMeACoffee
 * @dev A contract to allow anyone to send a coffee (ETH tip) with a message.
 */
contract BuyMeACoffee {
    /// @dev Event emitted when a memo is created
    event NewMemo(
        address indexed from,
        uint256 timestamp,
        string name,
        string message
    );

    /// @dev Struct to represent a coffee memo
    struct Memo {
        address from;
        uint256 timestamp;
        string name;
        string message;
    }

    /// @dev List of all memos received
    Memo[] public memos;

    /// @dev The owner of the contract who can withdraw the tips
    address payable public owner;

    /// @dev Error thrown when tipping less than minimum amount
    error InsufficientEth();

    /// @dev Error thrown when unauthorized address tries to withdraw
    error NotOwner();

    /// @dev Error thrown if withdrawal fails
    error WithdrawalFailed();

    /**
     * @dev Constructor sets the deployer as the owner.
     */
    constructor() {
        owner = payable(msg.sender);
    }

    /**
     * @dev Buy a coffee for the contract owner.
     * @param _name The name of the coffee buyer.
     * @param _message A message from the coffee buyer.
     */
    function buyCoffee(
        string calldata _name,
        string calldata _message
    ) external payable {
        if (msg.value < 0.001 ether) {
            revert InsufficientEth();
        }
        memos.push(
            Memo({
                from: msg.sender,
                timestamp: block.timestamp,
                name: _name,
                message: _message
            })
        );

        emit NewMemo(msg.sender, block.timestamp, _name, _message);
    }

    /**
     * @dev Withdraw all tipped Ether to the owner.
     */
    function withdrawTips() external {
        if (msg.sender != owner) {
            revert NotOwner();
        }

        uint256 balance = address(this).balance;
        (bool success, ) = owner.call{value: balance}("");
        if (!success) {
            revert WithdrawalFailed();
        }
    }

    /**
     * @dev Get all memos stored in the contract.
     * @return An array of Memo structs.
     */
    function getMemos() external view returns (Memo[] memory) {
        return memos;
    }
}
