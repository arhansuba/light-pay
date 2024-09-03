// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../libraries//ERC20.sol";
import "../libraries/Ownable.sol";

/**
 * @title Token
 * @dev An ERC-20 token contract for issuing a custom token within your payment app.
 * The token supports minting, burning, and ownership control.
 */
contract Token is ERC20, Ownable {

    // Maximum supply cap (optional)
    uint256 private immutable maxSupply;

    /**
     * @dev Constructor that gives msg.sender all of the initial tokens.
     * @param _name Name of the token.
     * @param _symbol Symbol of the token.
     * @param _initialSupply Initial supply of tokens (in smallest unit, e.g., wei for ETH).
     * @param _maxSupply Maximum supply cap (optional).
     */
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _initialSupply,
        uint256 _maxSupply
    ) ERC20(_name, _symbol) {
        require(_initialSupply <= _maxSupply, "Initial supply exceeds max supply");
        maxSupply = _maxSupply;
        _mint(msg.sender, _initialSupply);
    }

    /**
     * @dev Function to mint new tokens. Only the owner can mint tokens.
     * @param to The address that will receive the minted tokens.
     * @param amount The amount of tokens to mint.
     */
    function mint(address to, uint256 amount) external onlyOwner {
        require(totalSupply() + amount <= maxSupply, "Max supply exceeded");
        _mint(to, amount);
    }

    /**
     * @dev Function to burn tokens.
     * @param amount The amount of tokens to burn.
     */
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    /**
     * @dev Function to burn tokens from an approved account.
     * @param from The account to burn tokens from.
     * @param amount The amount of tokens to burn.
     */
    function burnFrom(address from, uint256 amount) external {
        uint256 currentAllowance = allowance(from, msg.sender);
        require(currentAllowance >= amount, "Burn amount exceeds allowance");
        _approve(from, msg.sender, currentAllowance - amount);
        _burn(from, amount);
    }

    /**
     * @dev Returns the maximum supply of tokens.
     */
    function getMaxSupply() external view returns (uint256) {
        return maxSupply;
    }
}
