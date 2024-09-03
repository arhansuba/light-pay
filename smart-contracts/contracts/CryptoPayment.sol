// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../libraries/ReentrancyGuard.sol";
import "../libraries/Ownable.sol";
import "../libraries/SafeMath.sol";
import "../interfaces/IERC20.sol";

/**
 * @title CryptoPayment
 * @dev A smart contract for handling crypto payments (ETH & ERC-20 tokens), sending, receiving, and logging transactions.
 */
contract CryptoPayment is ReentrancyGuard, Ownable {
    using SafeMath for uint256;

    // Events for logging transactions
    event PaymentReceived(address indexed sender, address indexed recipient, uint256 amount, string currency);
    event PaymentSent(address indexed sender, address indexed recipient, uint256 amount, string currency);
    event ERC20PaymentReceived(address indexed sender, address indexed recipient, address token, uint256 amount);
    event ERC20PaymentSent(address indexed sender, address indexed recipient, address token, uint256 amount);
    
    /**
     * @dev Receive ETH payments and log the transaction.
     */
    receive() external payable {
        require(msg.value > 0, "No ETH sent");
        emit PaymentReceived(msg.sender, address(this), msg.value, "ETH");
    }

    /**
     * @dev Send ETH payments to a recipient and log the transaction.
     * @param recipient The address of the recipient.
     * @param amount The amount of ETH to send.
     */
    function sendPayment(address payable recipient, uint256 amount) external nonReentrant onlyOwner {
        require(recipient != address(0), "Invalid recipient address");
        require(amount <= address(this).balance, "Insufficient balance");
        recipient.transfer(amount);
        emit PaymentSent(msg.sender, recipient, amount, "ETH");
    }

    /**
     * @dev Receive ERC-20 token payments and log the transaction.
     * @param token The address of the ERC-20 token contract.
     * @param amount The amount of tokens to receive.
     */
    function receiveERC20Payment(address token, uint256 amount) external nonReentrant {
        require(token != address(0), "Invalid token address");
        require(amount > 0, "No tokens sent");
        
        IERC20 erc20 = IERC20(token);
        require(erc20.transferFrom(msg.sender, address(this), amount), "Token transfer failed");
        
        emit ERC20PaymentReceived(msg.sender, address(this), token, amount);
    }

    /**
     * @dev Send ERC-20 token payments to a recipient and log the transaction.
     * @param token The address of the ERC-20 token contract.
     * @param recipient The address of the recipient.
     * @param amount The amount of tokens to send.
     */
    function sendERC20Payment(address token, address recipient, uint256 amount) external nonReentrant onlyOwner {
        require(token != address(0), "Invalid token address");
        require(recipient != address(0), "Invalid recipient address");
        require(amount > 0, "Amount must be greater than zero");
        
        IERC20 erc20 = IERC20(token);
        require(erc20.balanceOf(address(this)) >= amount, "Insufficient token balance");
        require(erc20.transfer(recipient, amount), "Token transfer failed");
        
        emit ERC20PaymentSent(msg.sender, recipient, token, amount);
    }

    /**
     * @dev Withdraw all ETH from the contract to the owner’s address.
     */
    function withdraw() external onlyOwner nonReentrant {
        require(address(this).balance > 0, "No ETH to withdraw");
        payable(owner()).transfer(address(this).balance);
    }

    /**
     * @dev Withdraw ERC-20 tokens from the contract to the owner's address.
     * @param token The address of the ERC-20 token contract.
     */
    function withdrawERC20(address token) external onlyOwner nonReentrant {
        require(token != address(0), "Invalid token address");
        
        IERC20 erc20 = IERC20(token);
        uint256 balance = erc20.balanceOf(address(this));
        require(balance > 0, "No tokens to withdraw");
        
        require(erc20.transfer(owner(), balance), "Token transfer failed");
    }

    /**
     * @dev Get the contract's ETH balance.
     */
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Get the contract's ERC-20 token balance.
     * @param token The address of the ERC-20 token contract.
     * @return The token balance of the contract.
     */
    function getTokenBalance(address token) external view returns (uint256) {
        IERC20 erc20 = IERC20(token);
        return erc20.balanceOf(address(this));
    }
}
