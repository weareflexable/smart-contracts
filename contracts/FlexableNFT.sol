// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

/**
 * @dev {ERC721} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a creator role that allows for token minting (creation)
 *  - a pauser role that allows to stop all token transfers
 *  - token ID and URI autogeneration
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the creator and pauser
 * roles, as well as the default admin role, which will let it grant both creator
 * and pauser roles to other accounts.
 */
contract FlexableNFT is
    Context,
    AccessControlEnumerable,
    ERC721Enumerable,
    ERC721Pausable,
    ERC2981
{
    using Counters for Counters.Counter;

    bytes32 public constant FLEXABLENFT_ADMIN_ROLE = keccak256("FLEXABLENFT_ADMIN_ROLE");
    bytes32 public constant FLEXABLENFT_OPERATOR_ROLE = keccak256("FLEXABLENFT_OPERATOR_ROLE");
    bytes32 public constant FLEXABLENFT_CREATOR_ROLE = keccak256("FLEXABLENFT_CREATOR_ROLE");

    Counters.Counter private _tokenIdTracker;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    struct Ticket {
        uint16 redeemCount;
        string redeemInfo;
    }

    // Track Ticket Status
    mapping(uint256 => Ticket) public TicketStatus;

    event TicketCreated(uint256 tokenID, address indexed creator, string metaDataURI);
    event TicketRedeemed(uint256 indexed tokenID, uint16 indexed count, string info);
    event TicketBurnt(uint256 indexed tokenId, address indexed ownerOrApproved);
    event RoyaltyUpdated(address indexed reciever, uint96 indexed percentageBasisPoint);

    using Strings for uint256;

    /**
     * @dev Grants `FLEXABLENFT_ADMIN_ROLE`, `FLEXABLENFT_CREATOR_ROLE` and `FLEXABLENFT_OPERATOR_ROLE` to the
     * account that deploys the contract.
     *
     * Token URIs will be autogenerated based on `baseURI` and their token IDs.
     * See {ERC721-tokenURI}.
     */
    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
        _setupRole(FLEXABLENFT_ADMIN_ROLE, _msgSender());
        _setRoleAdmin(FLEXABLENFT_ADMIN_ROLE, FLEXABLENFT_ADMIN_ROLE);
        _setRoleAdmin(FLEXABLENFT_OPERATOR_ROLE, FLEXABLENFT_ADMIN_ROLE);
        _setRoleAdmin(FLEXABLENFT_CREATOR_ROLE, FLEXABLENFT_OPERATOR_ROLE);

        _setDefaultRoyalty(_msgSender(), 500);
    }

    /**
     * @dev Creates a new token for `to`. Its token ID will be automatically
     * assigned (and available on the emitted {IERC721-Transfer} event), and the token
     * URI autogenerated based on the base URI passed at construction.
     *
     * See {ERC721-_safeMint}.
     *
     * Requirements:
     *
     * - the caller must have the `FLEXABLENFT_CREATOR_ROLE`.
     */
    function createTicket(
        string memory metadataURI
    ) public onlyRole(FLEXABLENFT_CREATOR_ROLE) returns (uint256) {
        // We cannot just use balanceOf to create the new tokenId because tokens
        // can be burned (destroyed), so we need a separate counter.
        _tokenIdTracker.increment();
        uint256 currentTokenID = _tokenIdTracker.current();
        _safeMint(_msgSender(), currentTokenID);
        _setTokenURI(currentTokenID, metadataURI);

        emit TicketCreated(
            currentTokenID,
            _msgSender(),
            tokenURI(currentTokenID)
        );
        return currentTokenID;
    }

    function createTicketWithCustomRoyalty(
        string memory metadataURI,
        uint96 royaltyPercentBasisPoint
    ) public onlyRole(FLEXABLENFT_CREATOR_ROLE) returns (uint256) {
        _tokenIdTracker.increment();
        uint256 currentTokenID = _tokenIdTracker.current();
        _safeMint(_msgSender(), currentTokenID);
        _setTokenURI(currentTokenID, metadataURI);

        emit TicketCreated(currentTokenID, _msgSender(), tokenURI(currentTokenID));
        _setTokenRoyalty(currentTokenID, _msgSender(), royaltyPercentBasisPoint);
        return currentTokenID;
    }

    /**
     * @dev Creates a new token for `creator`. Its token ID will be automatically
     * assigned (and available on the emitted {IERC721-Transfer} event), and the token
     * URI autogenerated based on the base URI passed at construction.
     *
     * See {ERC721-_safeMint}.
     *
     * Requirements:
     *
     * - the caller must have the `FLEXABLENFT_OPERATOR_ROLE`.
     */
    function delegateTicketCreation(
        address creator,
        string memory metadataURI
    ) public onlyRole(FLEXABLENFT_OPERATOR_ROLE) returns (uint256) {
        _tokenIdTracker.increment();
        uint256 currentTokenID = _tokenIdTracker.current();
        _safeMint(creator, currentTokenID);
        _setTokenURI(currentTokenID, metadataURI);

        emit TicketCreated(currentTokenID, creator, metadataURI);
        return currentTokenID;
    }

    function delegateTicketCreationWithCustomRoyalty(
        address creator,
        string memory metadataURI,
        address royaltyaddress,
        uint96 royaltyPercentBasisPoint
    ) public onlyRole(FLEXABLENFT_OPERATOR_ROLE) returns (uint256) {
        _tokenIdTracker.increment();
        uint256 currentTokenID = _tokenIdTracker.current();

        _safeMint(creator, currentTokenID);
        _setTokenURI(currentTokenID, metadataURI);
        _setTokenRoyalty(currentTokenID, royaltyaddress, royaltyPercentBasisPoint);

        emit TicketCreated(currentTokenID, creator, metadataURI);
        return currentTokenID;
    }

    /// @dev Redeem NFT Ticket
    function redeemTicket(uint256 tokenId, string memory info) public onlyRole(FLEXABLENFT_OPERATOR_ROLE) {
        TicketStatus[tokenId].redeemInfo = info;
        TicketStatus[tokenId].redeemCount++;

        emit TicketRedeemed(tokenId, TicketStatus[tokenId].redeemCount, info);
    }

    /**
     *  Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burnTicket(uint256 tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "FlexableNFT: Not Owner Or Approved");
        _burn(tokenId);
        emit TicketBurnt(tokenId, _msgSender());
        _resetTokenRoyalty(tokenId);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "FlexableNFT: Non-Existent Ticket");
        string memory _tokenURI = _tokenURIs[tokenId];

        return _tokenURI;
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "FlexableNFT: Non-Existent Ticket");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `FLEXABLENFT_OPERATOR_ROLE`.
     */
    function pause() public onlyRole(FLEXABLENFT_OPERATOR_ROLE) {
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `FLEXABLENFT_OPERATOR_ROLE`.
     */
    function unpause() public onlyRole(FLEXABLENFT_OPERATOR_ROLE) {
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenID,
        uint256 batchsize
    ) internal virtual override(ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenID, batchsize);
    }

    function updateDefaultRoyalty(address royaltyReciever, uint96 percentageBasisPoint) external onlyRole(FLEXABLENFT_ADMIN_ROLE) {
        _setDefaultRoyalty(royaltyReciever, percentageBasisPoint);
        emit RoyaltyUpdated(royaltyReciever, percentageBasisPoint);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(AccessControlEnumerable, ERC721, ERC721Enumerable, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
