// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Context.sol";

import "./IFlexableAuth.sol";

contract FlexableVendor is ERC721 {
    IFlexableAuth private flexableAuth;
    uint256 private counter = 1;

    struct VendorInfo {
        address payoutWallet;
        string name;
        string serviceMetadata;
        bool isActive;
        bool isVerified;
    }

    mapping(uint256 => string) private _tokenURIs;
    mapping(uint256 => VendorInfo) private _vendorInfo;

    event VendorCreated(
        address indexed to,
        uint256 indexed tokenId,
        string name,
        string serviceMetadata
    );

    event VendorStatus(uint256 indexed tokenId, string name, bool status);

    event VendorBurned(
        uint256 indexed tokenId,
        string name,
        string serviceMetadata
    );

    event VendorWalletUpdated(
        uint256 indexed tokenId,
        address indexed oldWallet,
        address indexed newWallet
    );

    event VendorURIUpdated(uint256 indexed tokenId, string newURI);

    constructor(
        address _flexableAuthAddr
    ) ERC721("FlexableVendor", "FLEXVENDOR") {
        flexableAuth = IFlexableAuth(_flexableAuthAddr);
    }

    // ===== MAIN FUNCTIONS =====
    //  Give an Array of VendorInfo , and create vendors for each of them.
    function createVendor(
        address to,
        string memory _name,
        string memory _uri
    ) external returns (uint256) {
        uint256 tokenId = counter;
        _safeMint(to, tokenId);
        _tokenURIs[tokenId] = _uri;
        _vendorInfo[tokenId] = VendorInfo({
            payoutWallet: to,
            name: _name,
            serviceMetadata: _uri,
            isActive: true,
            isVerified: false
        });
        counter++;
        emit VendorCreated(to, tokenId, _name, _uri);
        return tokenId;
    }

    function setTokenURI(uint256 tokenId, string memory _uri) public {
        require(flexableAuth.isOperator(_msgSender()), "Not an operator");
        _tokenURIs[tokenId] = _uri;
        emit VendorURIUpdated(tokenId, _uri);
    }

    function setVendorActive(uint256 tokenId, bool _isActive) public {
        require(
            flexableAuth.isOperator(_msgSender()) ||
                ownerOf(tokenId) == _msgSender(),
            "Not the owner"
        );
        _vendorInfo[tokenId].isActive = _isActive;
        emit VendorStatus(tokenId, _vendorInfo[tokenId].name, _isActive);
    }

    function updateVendorWallet(uint256 tokenId, address _wallet) public {
        require(ownerOf(tokenId) == _msgSender(), "Not the Owner");
        _vendorInfo[tokenId].payoutWallet = _wallet;
        emit VendorWalletUpdated(
            tokenId,
            _vendorInfo[tokenId].payoutWallet,
            _wallet
        );
    }

    function burnVendor(uint256 tokenId) public {
        require(ownerOf(tokenId) == _msgSender(), "Not the owner");
        _burn(tokenId);
        emit VendorBurned(
            tokenId,
            _vendorInfo[tokenId].name,
            _vendorInfo[tokenId].serviceMetadata
        );
        delete _vendorInfo[tokenId];
        delete _tokenURIs[tokenId];
    }

    // ================================== VIEW FUNCTIONS =====================================//

    function tokenIdToVendorWallet(
        uint256 tokenId
    ) public view returns (address) {
        return _vendorInfo[tokenId].payoutWallet;
    }

    function isVendorActive(uint256 tokenId) external view returns (bool) {
        return _vendorInfo[tokenId].isActive;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        return _tokenURIs[tokenId];
    }
}
