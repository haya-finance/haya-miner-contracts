// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import {AddressArrayUtils} from "./lib/AddressArrayUtils.sol";

/**
 * @title Miner
 * @dev This contract represents a Haya Miner, which is used to mine Haya tokens.
*/
contract Miner is ERC1155, Ownable2Step {


    using AddressArrayUtils for address[];

    /**
     * @dev Mapping to store the total supply of tokens for each ID.
     * The key of the mapping is the ID of the token, and the value is the total supply of that token.
     * This mapping is private, meaning it can only be accessed within the contract.
     */
    mapping(uint256 => uint256) private _totalSupply;
    
    /**
     * @dev Represents the total supply of a token.
     */
    uint256 private _totalSupplyAll;

    /**
     * @dev The address of the factory contract that creates Haya Miners.
     */
    address[] public factories;

    /**
     * @dev The name of the miner.
     */
    string public name;

    /**
     * @dev Public variable representing the symbol of the contract.
     */
    string public symbol;

    /**
     * @dev Enum representing the different types of Haya Miners.
     * Mini: Represents a Mini Miner.
     * Bronze: Represents a Bronze Miner.
     * Silver: Represents a Silver Miner.
     * Gold: Represents a Gold Miner.
     */
    enum MinerType {
        Mini,
        Bronze,
        Silver,
        Gold
    }

    /**
     * @dev Emitted when a new factory is added.
     * @param newFactory The address of the new factory.
     */
    event FactoryAdded(address indexed newFactory);

    /**
     * @dev Emitted when a factory is removed.
     * @param factory The address of the removed factory.
     */
    event FactoryRemoved(address indexed factory);

    /**
     * @dev Constructor function for the HayaMiner contract.
     * @param _uri The URI for the ERC1155 token metadata.
     * @param _owner The address of the contract owner.
     */
    constructor(string memory _uri, address _owner) ERC1155(_uri) Ownable(_owner) {
        name = "HAYA Genesis Miner";
        symbol = "HGM";
    }

    /**
     * @dev Mints a new token and assigns it to the specified account.
     * 
     * Requirements:
     * - The caller must be the factory contract.
     * 
     * @param account The address to which the minted token will be assigned.
     * @param id The ID of the token to be minted.
     * @param amount The amount of tokens to be minted.
     * @param data Additional data to be passed during the minting process.
     */
    function mint(address account, uint256 id, uint256 amount, bytes memory data) public onlyFactory {
        _mint(account, id, amount, data);
    }

    /**
     * @dev Adds a new factory address to the list of factories.
     * @param _factory The address of the factory to be added.
     * @notice Only the contract owner can call this function.
     * @notice The factory address must not already exist in the list of factories.
     * @notice Emits a `FactoryAdded` event.
     */
    function addFactory(address _factory) external onlyOwner {
        require(factories.contains(_factory) == false, "Miner: factory already exists");
        factories.push(_factory);
        emit FactoryAdded(_factory);
    }

    /**
     * @dev Removes a factory from the list of registered factories.
     * @param _factory The address of the factory to be removed.
     * @notice Only the contract owner can call this function.
     * @notice The factory must exist in the list of registered factories.
     * @notice Emits a `FactoryRemoved` event upon successful removal.
     */
    function removeFactory(address _factory) external onlyOwner {
        require(factories.contains(_factory), "Miner: factory does not exist");
        factories.removeStorage(_factory);
        emit FactoryRemoved(_factory);
    }

    /**
     * @dev Sets the URI for the token metadata.
     * Can only be called by the contract owner.
     * @param newuri The new URI to set.
     */
    function setURI(string memory newuri) external onlyOwner {
        _setURI(newuri);
    }

    /**
     * @dev Burns a specific amount of tokens from the specified account.
     * 
     * Requirements:
     * - The caller must be the account owner or have been approved for all tokens by the account owner.
     * 
     * @param account The address of the account from which the tokens will be burned.
     * @param id The identifier of the token to be burned.
     * @param value The amount of tokens to be burned.
     */
    function burn(address account, uint256 id, uint256 value) public {
        if (account != _msgSender() && !isApprovedForAll(account, _msgSender())) {
            revert ERC1155MissingApprovalForAll(_msgSender(), account);
        }
        _burn(account, id, value);
    }

    /**
     * @dev Total value of tokens in with a given id.
     */
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }

    /**
     * @dev Total value of tokens.
     */
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupplyAll;
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) public view virtual returns (bool) {
        return totalSupply(id) > 0;
    }

    /**
     * @dev See {ERC1155-_update}.
     */
    function _update(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values
    ) internal virtual override {
        super._update(from, to, ids, values);

        if (from == address(0)) {
            uint256 totalMintValue = 0;
            for (uint256 i = 0; i < ids.length; ++i) {
                uint256 value = values[i];
                // Overflow check required: The rest of the code assumes that totalSupply never overflows
                _totalSupply[ids[i]] += value;
                totalMintValue += value;
            }
            // Overflow check required: The rest of the code assumes that totalSupplyAll never overflows
            _totalSupplyAll += totalMintValue;
        }

        if (to == address(0)) {
            uint256 totalBurnValue = 0;
            for (uint256 i = 0; i < ids.length; ++i) {
                uint256 value = values[i];

                unchecked {
                    // Overflow not possible: values[i] <= balanceOf(from, ids[i]) <= totalSupply(ids[i])
                    _totalSupply[ids[i]] -= value;
                    // Overflow not possible: sum_i(values[i]) <= sum_i(totalSupply(ids[i])) <= totalSupplyAll
                    totalBurnValue += value;
                }
            }
            unchecked {
                // Overflow not possible: totalBurnValue = sum_i(values[i]) <= sum_i(totalSupply(ids[i])) <= totalSupplyAll
                _totalSupplyAll -= totalBurnValue;
            }
        }
    }

    /**
     * @dev Fallback function to reject any incoming Ether transfers.
     * Reverts the transaction to prevent accidental transfers to this contract.
     */
    receive() external payable {
        revert();
    }

    modifier onlyFactory() {
        require(factories.contains(msg.sender), "Miner: caller is not a factory");
        _;
    }
}