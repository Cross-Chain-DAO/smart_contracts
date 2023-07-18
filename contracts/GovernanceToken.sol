// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Logger.sol";

/// @custom:security-contact contact@yashgoyal.dev
contract GovernanceToken is ERC20, ERC20Permit, ERC20Votes, Ownable {
    Logger public logger;

    constructor(
        string memory name,
        string memory symbol,
        address loggerContract,
        bytes32 serverSignature
    ) ERC20(name, symbol) ERC20Permit(name) {
        logger = Logger(loggerContract);
        logger.authorizeContract(msg.sender, serverSignature);
    }

    // The following functions are overrides required by Solidity.

    function clock() public view virtual override returns (uint48) {
        return SafeCast.toUint48(block.timestamp);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Votes) {
        logger.emitTokenTransferEvent(from, to, amount);
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Votes) {
        super._mint(to, amount);
    }

    function _burn(
        address account,
        uint256 amount
    ) internal override(ERC20, ERC20Votes) {
        super._burn(account, amount);
    }

    // TODO: add the code for bridging the token
}
