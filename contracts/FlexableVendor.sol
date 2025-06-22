// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Context.sol";

import "./IFlexableAuth.sol";

contract FlexableVendor is ERC721 {
    IFlexableAuth private flexableAuth;
    uint256 private counter = 1;

    struct VendorInfo {
        address wallet;
        string name;
        string serviceMetadata;
    }

    mapping(uint256 => string) private _tokenURIs;
    mapping(uint256 => VendorInfo) private _vendorInfo;

    event VendorMinted(address to, uint256 tokenId);

    constructor(
        address _flexableAuthAddr
    ) ERC721("FlexableVendor", "FLEXABLEVENDOR") {
        flexableAuth = IFlexableAuth(_flexableAuthAddr);
    }

    function mintVendor(
        address to,
        string memory _name,
        string memory _uri
    ) public {
        require(flexableAuth.isMinter(_msgSender()), "Not a minter");
        require(balanceOf(to) == 0, "Vendor already minted");
        uint256 tokenId = counter;

        _safeMint(to, tokenId);
        _tokenURIs[tokenId] = _uri;
        _vendorInfo[tokenId] = VendorInfo({
            wallet: to,
            name: _name,
            serviceMetadata: _uri
        });
        counter++;
        emit VendorMinted(to, tokenId);
    }

    function setTokenURI(uint256 tokenId, string memory _uri) public {
        require(flexableAuth.isOperator(_msgSender()), "Not an operator");
        _tokenURIs[tokenId] = _uri;
    }

    function burnVendor(uint256 tokenId) public {
        require(_vendorInfo[tokenId].wallet == _msgSender(), "Not the owner");
        _burn(tokenId);
    }

    function updateVendorWallet(uint256 tokenId, address _wallet) public {
        require(_vendorInfo[tokenId].wallet == _msgSender(), "Not the owner");
        _vendorInfo[tokenId].wallet = _wallet;
    }

    function tokenIdToVendorWallet(
        uint256 tokenId
    ) public view returns (address) {
        return _vendorInfo[tokenId].wallet;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        return _tokenURIs[tokenId];
    }
}
