pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Logger is Ownable {
    event TokenTransfer(
        address indexed tokenContract,
        address indexed from,
        address indexed to,
        uint256 value
    );

    event TokenTransferredChain(
        address indexed tokenContract,
        address indexed owner,
        uint256 destChainId,
        uint256 value
    );

    event ContractAuthorized(address indexed contractAddress);

    mapping(address => bool) isContractAuthorized;

    constructor() {
        uint256 id;
        assembly {
            id := chainid()
        }
        emit ChainSetup(chainId);
    }

    modifier onlyAuthorizedContracts() {
        require(
            isContractAuthorized[msg.sender],
            "only authorized contracts allowed"
        );
        _;
    }

    function authorizeContract(address contractAddress, bytes32 signature) {
        // TODO: verify the server signature

        isContractAuthorized[contractAddress] = true;
        emit ContractAuthorized(contractAddress);
    }

    function emitTokenTransferEvent(
        address from,
        address to,
        uint256 value
    ) public onlyAuthorizedContracts {
        emit TokenTransfer(msg.sender, from, to, value);
    }
}
