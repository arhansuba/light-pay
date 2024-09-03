// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../interfaces/IERC20.sol";
import "../libraries/ReentrancyGuard.sol";
import "../libraries/Ownable.sol";

/**
 * @title Escrow
 * @dev This smart contract handles an escrow mechanism where funds are held and released based on predefined conditions.
 * The contract supports both ETH and ERC-20 tokens.
 */
contract Escrow is ReentrancyGuard, Ownable {
    // Struct to store details of each escrow transaction
    struct EscrowTransaction {
        address buyer;
        address seller;
        address tokenAddress; // If address(0), it indicates ETH
        uint256 amount;
        bool isCompleted;
        bool isDisputed;
        address arbitrator;
        bool fundsReleased;
    }

    // Mapping to store each escrow transaction
    mapping(uint256 => EscrowTransaction) public escrows;
    uint256 public escrowCount;

    // Events for logging escrow actions
    event EscrowCreated(uint256 indexed escrowId, address indexed buyer, address indexed seller, uint256 amount);
    event FundsDeposited(uint256 indexed escrowId, uint256 amount);
    event FundsReleased(uint256 indexed escrowId, address indexed seller);
    event DisputeRaised(uint256 indexed escrowId);
    event DisputeResolved(uint256 indexed escrowId, address indexed recipient);

    /**
     * @dev Modifier to ensure the caller is the buyer or the arbitrator in the escrow.
     */
    modifier onlyBuyerOrArbitrator(uint256 escrowId) {
        require(
            msg.sender == escrows[escrowId].buyer || msg.sender == escrows[escrowId].arbitrator,
            "Caller is not buyer or arbitrator"
        );
        _;
    }

    /**
     * @dev Function to create an escrow transaction.
     * @param _seller The address of the seller.
     * @param _tokenAddress The address of the ERC-20 token contract (address(0) for ETH).
     * @param _amount The amount of tokens/ETH involved in the transaction.
     * @param _arbitrator The address of the arbitrator who can resolve disputes.
     */
    function createEscrow(
        address _seller,
        address _tokenAddress,
        uint256 _amount,
        address _arbitrator
    ) external payable nonReentrant returns (uint256) {
        require(_seller != address(0), "Invalid seller address");
        require(_arbitrator != address(0), "Invalid arbitrator address");
        require(_amount > 0, "Invalid amount");

        escrowCount++;
        escrows[escrowCount] = EscrowTransaction({
            buyer: msg.sender,
            seller: _seller,
            tokenAddress: _tokenAddress,
            amount: _amount,
            isCompleted: false,
            isDisputed: false,
            arbitrator: _arbitrator,
            fundsReleased: false
        });

        // Deposit ETH into escrow if it's an ETH transaction
        if (_tokenAddress == address(0)) {
            require(msg.value == _amount, "ETH amount does not match");
            emit FundsDeposited(escrowCount, msg.value);
        }

        emit EscrowCreated(escrowCount, msg.sender, _seller, _amount);
        return escrowCount;
    }

    /**
     * @dev Function for the buyer to deposit ERC-20 tokens into escrow.
     * @param escrowId The ID of the escrow transaction.
     */
    function depositTokens(uint256 escrowId) external nonReentrant {
        EscrowTransaction storage escrow = escrows[escrowId];
        require(escrow.tokenAddress != address(0), "This is an ETH escrow");
        require(escrow.buyer == msg.sender, "Only the buyer can deposit tokens");
        require(!escrow.isCompleted, "Escrow already completed");

        IERC20 token = IERC20(escrow.tokenAddress);
        require(token.transferFrom(msg.sender, address(this), escrow.amount), "Token transfer failed");

        emit FundsDeposited(escrowId, escrow.amount);
    }

    /**
     * @dev Function for the buyer or arbitrator to release funds to the seller.
     * @param escrowId The ID of the escrow transaction.
     */
    function releaseFunds(uint256 escrowId) external nonReentrant onlyBuyerOrArbitrator(escrowId) {
        EscrowTransaction storage escrow = escrows[escrowId];
        require(!escrow.isCompleted, "Escrow already completed");
        require(!escrow.isDisputed, "Escrow is disputed");
        require(!escrow.fundsReleased, "Funds already released");

        escrow.fundsReleased = true;
        escrow.isCompleted = true;

        if (escrow.tokenAddress == address(0)) {
            // ETH transfer
            payable(escrow.seller).transfer(escrow.amount);
        } else {
            // ERC-20 token transfer
            IERC20 token = IERC20(escrow.tokenAddress);
            require(token.transfer(escrow.seller, escrow.amount), "Token transfer failed");
        }

        emit FundsReleased(escrowId, escrow.seller);
    }

    /**
     * @dev Function to raise a dispute by the buyer.
     * @param escrowId The ID of the escrow transaction.
     */
    function raiseDispute(uint256 escrowId) external {
        EscrowTransaction storage escrow = escrows[escrowId];
        require(msg.sender == escrow.buyer, "Only the buyer can raise a dispute");
        require(!escrow.isCompleted, "Escrow already completed");
        require(!escrow.isDisputed, "Dispute already raised");

        escrow.isDisputed = true;
        emit DisputeRaised(escrowId);
    }

    /**
     * @dev Function for the arbitrator to resolve a dispute.
     * @param escrowId The ID of the escrow transaction.
     * @param recipient The address that will receive the funds (either buyer or seller).
     */
    function resolveDispute(uint256 escrowId, address recipient) external nonReentrant {
        EscrowTransaction storage escrow = escrows[escrowId];
        require(msg.sender == escrow.arbitrator, "Only the arbitrator can resolve disputes");
        require(escrow.isDisputed, "No dispute to resolve");
        require(!escrow.isCompleted, "Escrow already completed");
        require(recipient == escrow.buyer || recipient == escrow.seller, "Invalid recipient");

        escrow.isCompleted = true;

        if (escrow.tokenAddress == address(0)) {
            // ETH transfer
            payable(recipient).transfer(escrow.amount);
        } else {
            // ERC-20 token transfer
            IERC20 token = IERC20(escrow.tokenAddress);
            require(token.transfer(recipient, escrow.amount), "Token transfer failed");
        }

        emit DisputeResolved(escrowId, recipient);
    }

    /**
     * @dev Fallback function to accept ETH transfers directly into the contract.
     */
    receive() external payable {}
}
