// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "operator-filter-registry/src/upgradeable/DefaultOperatorFiltererUpgradeable.sol";

contract wowTNftCollection1 is
    Initializable,
    ERC1155Upgradeable,
    AccessControlUpgradeable,
    DefaultOperatorFiltererUpgradeable
{
    string public name;
    string public symbol;
    string private _contractUri;

    address public owner;
    address public feeAddress;

    struct SaleItem {
        uint256 price;
        uint256 supply;
        uint256 sold;
        bool paused;
        bool exists;
    }

    mapping(uint256 => SaleItem) public saleItems;
    mapping(address => mapping(uint256 => uint256)) public boughtQuantities;
    bytes32 public constant MARKET_ADMIN_ROLE = keccak256("MARKET_ADMIN_ROLE");

  /*  constructor(
        string memory _name,
        string memory _symbol,
        address _feeAddress,
        string memory _contractUrl,
        string memory _tokenUri
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(MARKET_ADMIN_ROLE, _msgSender());
        owner = _msgSender();

        name = _name;
        symbol = _symbol;

        feeAddress = _feeAddress;
        _contractUri = _contractUrl;

        initialize(_tokenUri);
    } */

    function initialize(
        string memory _name,
        string memory _symbol,
        address _feeAddress,
        string memory _contractUrl,
        string memory _tokenUri) 
        public initializer {

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(MARKET_ADMIN_ROLE, _msgSender());
        owner = _msgSender();

        name = _name;
        symbol = _symbol;

        feeAddress = _feeAddress;
        _contractUri = _contractUrl;

        __ERC1155_init(_tokenUri);
        __AccessControl_init();

        
    }

    function mint(
        address _to,
        uint256 _tokenId,
        uint256 _amount
    ) public adminOnly {
        super._mint(_to, _tokenId, _amount, "0x");
    }

    function registerToken(
        uint256 _tokenId,
        uint256 _price,
        uint256 _supply
    ) public adminOnly {
        require(_supply > 0, "Not enough supply");
        require(saleItems[_tokenId].supply == 0, "Token already registered.");

        saleItems[_tokenId].supply = _supply;
        saleItems[_tokenId].price = _price;
        saleItems[_tokenId].paused = false;
        saleItems[_tokenId].exists = true;
    }

    function buyToken(uint256 _tokenId, uint256 _amount) public payable {
        require(saleItems[_tokenId].exists, "Token is not registered.");
        require(!saleItems[_tokenId].paused, "Token is paused.");
        require(
            saleItems[_tokenId].sold + _amount <= saleItems[_tokenId].supply,
            "Reached max supply"
        );
        require(
            msg.value == saleItems[_tokenId].price * _amount,
            "Not enough eth sent"
        );
        uint256[] memory tokenIds = new uint256[](_amount);
        for (uint256 i = 0; i < _amount; i++) {
            tokenIds[i] = saleItems[_tokenId].sold + i + 1;
        }
        super._mint(_msgSender(), _tokenId, _amount, "");
        payable(feeAddress).transfer(saleItems[_tokenId].price * _amount);
        saleItems[_tokenId].sold += _amount;
        boughtQuantities[_msgSender()][_tokenId] += _amount;
    }

    function pauseToken(uint256 _tokenId, bool _pauseStatus) public adminOnly {
        saleItems[_tokenId].paused = _pauseStatus;
    }

    function setMaxSupply(
        uint256 _tokenId,
        uint256 _newSupply
    ) public adminOnly {
        require(
            _newSupply >= saleItems[_tokenId].supply - saleItems[_tokenId].sold,
            "Invalid supply."
        );
        saleItems[_tokenId].supply = _newSupply;
    }

    function setTokenPrice(
        uint256 _tokenId,
        uint256 _newPrice
    ) public adminOnly {
        saleItems[_tokenId].price = _newPrice;
    }

    function setFeeAddress(address _newFeeAddress) public adminOnly {
        feeAddress = _newFeeAddress;
    }

    function setURI(string memory _newUri) public adminOnly {
        _setURI(_newUri);
    }

    function setContractURI(string memory _newUri) public adminOnly {
        _contractUri = _newUri;
    }

    function contractURI() public view returns (string memory) {
        return _contractUri;
    }

    /**
     * @dev Throws if called by any account other than admins.
     */
    modifier adminOnly() {
        require(
            hasRole(MARKET_ADMIN_ROLE, _msgSender()),
            "Must have market admin role"
        );
        _;
    }

    function grantRole(
        bytes32 role,
        address account
    ) public virtual override adminOnly {
        return super._grantRole(role, account);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC1155Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }
}
