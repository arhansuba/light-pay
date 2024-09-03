// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../libraries/ReentrancyGuard.sol";
import "../libraries/Ownable.sol";
import "../interfaces/IERC20.sol";
import "../libraries/SafeMath.sol";

/**
 * @title Wallet
 * @dev A smart contract to manage user wallet balances and operations like deposit, withdraw, and transfer.
 * It supports both native ETH and ERC-20 tokens.
 */
contract Wallet is ReentrancyGuard, Ownable {
    using SafeMath for uint256;

    // Mapping to track user ETH balances
    mapping(address => uint256) private ethBalances;

    // Mapping to track user ERC-20 token balances by token address
    mapping(address => mapping(address => uint256)) private tokenBalances;

    // Events for logging wallet operations
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event TokenDeposit(address indexed user, address indexed token, uint256 amount);
    event TokenWithdraw(address indexed user, address indexed token, uint256 amount);
    event TokenTransfer(address indexed from, address indexed to, address token, uint256 amount);

    /**
     * @dev Deposit ETH into the wallet.
     */
    function depositETH() external payable nonReentrant {
        require(msg.value > 0, "No ETH sent");
        ethBalances[msg.sender] = ethBalances[msg.sender].add(msg.value);
        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @dev Withdraw ETH from the wallet.
     * @param amount The amount of ETH to withdraw.
     */
    function withdrawETH(uint256 amount) external nonReentrant {
        require(amount <= ethBalances[msg.sender], "Insufficient ETH balance");
        ethBalances[msg.sender] = ethBalances[msg.sender].sub(amount);
        payable(msg.sender).transfer(amount);
        emit Withdraw(msg.sender, amount);
    }

    /**
     * @dev Transfer ETH between users within the contract.
     * @param recipient The address of the recipient.
     * @param amount The amount of ETH to transfer.
     */
    function transferETH(address recipient, uint256 amount) external nonReentrant {
        require(recipient != address(0), "Invalid recipient address");
        require(amount <= ethBalances[msg.sender], "Insufficient balance");
        ethBalances[msg.sender] = ethBalances[msg.sender].sub(amount);
        ethBalances[recipient] = ethBalances[recipient].add(amount);
        emit Transfer(msg.sender, recipient, amount);
    }

    /**
     * @dev Deposit ERC-20 tokens into the wallet.
     * @param token The address of the ERC-20 token contract.
     * @param amount The amount of tokens to deposit.
     */
    function depositToken(address token, uint256 amount) external nonReentrant {
        require(amount > 0, "No tokens sent");
        require(token != address(0), "Invalid token address");

        IERC20 erc20 = IERC20(token);
        require(erc20.transferFrom(msg.sender, address(this), amount), "Token transfer failed");

        tokenBalances[msg.sender][token] = tokenBalances[msg.sender][token].add(amount);
        emit TokenDeposit(msg.sender, token, amount);
    }

    /**
     * @dev Withdraw ERC-20 tokens from the wallet.
     * @param token The address of the ERC-20 token contract.
     * @param amount The amount of tokens to withdraw.
     */
    function withdrawToken(address token, uint256 amount) external nonReentrant {
        require(token != address(0), "Invalid token address");
        require(amount <= tokenBalances[msg.sender][token], "Insufficient token balance");

        tokenBalances[msg.sender][token] = tokenBalances[msg.sender][token].sub(amount);
        IERC20 erc20 = IERC20(token);
        require(erc20.transfer(msg.sender, amount), "Token transfer failed");

        emit TokenWithdraw(msg.sender, token, amount);
    }

    /**
     * @dev Transfer ERC-20 tokens between users within the contract.
     * @param recipient The address of the recipient.
     * @param token The address of the ERC-20 token contract.
     * @param amount The amount of tokens to transfer.
     */
    function transferToken(address recipient, address token, uint256 amount) external nonReentrant {
        require(recipient != address(0), "Invalid recipient address");
        require(token != address(0), "Invalid token address");
        require(amount <= tokenBalances[msg.sender][token], "Insufficient token balance");

        tokenBalances[msg.sender][token] = tokenBalances[msg.sender][token].sub(amount);
        tokenBalances[recipient][token] = tokenBalances[recipient][token].add(amount);

        emit TokenTransfer(msg.sender, recipient, token, amount);
    }

    /**
     * @dev Get the ETH balance of a user.
     * @param user The address of the user.
     * @return The ETH balance of the user.
     */
    function getETHBalance(address user) external view returns (uint256) {
        return ethBalances[user];
    }

    /**
     * @dev Get the ERC-20 token balance of a user.
     * @param user The address of the user.
     * @param token The address of the ERC-20 token contract.
     * @return The token balance of the user.
     */
    function getTokenBalance(address user, address token) external view returns (uint256) {
        return tokenBalances[user][token];
    }

    /**
     * @dev Fallback function to accept ETH transfers directly.
     */
    receive() external payable {
        ethBalances[msg.sender] = ethBalances[msg.sender].add(msg.value);
        emit Deposit(msg.sender, msg.value);
    }
}
