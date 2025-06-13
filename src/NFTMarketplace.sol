// License
// SPDX-License-Identifier: MIT

// Solidity Compiler Version
pragma solidity 0.8.24;

// Libraries
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "../lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";

// Contract
contract NFTMarketplace is ReentrancyGuard{

    // Variables
    mapping(address => mapping(uint256 => Listing)) public listing;

    // Structs
    struct Listing{
        address seller;
        address nftaddress;
        uint256 tokenId;
        uint256 price;
    }

    // Events
    event NFTListed(address indexed seller, address indexed nftAddress, uint256 indexed tokenId, uint256 price);
    event NFTCancelled(address indexed seller, address indexed nftAddress, uint256 indexed tokenId);
    event NFTSold(address indexed buyer, address indexed seller, address indexed nftAddress, uint256 tokenId, uint256 price);

    // Constructor

    constructor(){

    }

    // Functions

    function listNFT(address nftAddress_, uint256 tokenId_, uint256 price_) external nonReentrant {
        require(price_ > 0, "Price can not be 0");
        address owner_ = IERC721(nftAddress_).ownerOf(tokenId_);
        require(owner_ == msg.sender, "You are not the owner of the NFT");
        Listing memory listing_ = Listing({
            seller: msg.sender,
            nftaddress: nftAddress_,
            tokenId: tokenId_,
            price: price_
        });
        listing[nftAddress_][tokenId_] = listing_;
        emit NFTListed(msg.sender, nftAddress_, tokenId_, price_);
    }
    
    function buyNFT(address nftAddress_, uint256 tokenId_) external payable nonReentrant {
        Listing memory listing_ = listing[nftAddress_][tokenId_];
        require(listing_.price > 0, "Listing not exists");
        require(msg.value == listing_.price, "Incorrect amount");
        delete listing[nftAddress_][tokenId_];
        (bool success, ) = listing_.seller.call{value: msg.value}("");
        require(success, "Fail payment");
        IERC721(nftAddress_).safeTransferFrom(listing_.seller, msg.sender, listing_.tokenId);
        emit NFTSold(msg.sender, listing_.seller, listing_.nftaddress, listing_.tokenId, listing_.price);
    }

    function cancelList(address nftAddress_, uint256 tokenId_) external nonReentrant {
        Listing memory listing_ = listing[nftAddress_][tokenId_];
        require(listing_.seller == msg.sender, "You are not the listing owner");
        delete listing[nftAddress_][tokenId_];
        emit NFTCancelled(msg.sender, nftAddress_, tokenId_);
    }
}