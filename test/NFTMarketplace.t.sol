// License
// SPDX-License-Identifier: MIT

// Solidity Compiler Version
pragma solidity 0.8.24;

// Libraries
import "forge-std/Test.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "../src/NFTMarketplace.sol";

// Contracts
contract mockNFT is ERC721{

    // Constructor
    constructor() ERC721("MockNFT", "MNFT"){
        
    }

    // Functions
    function mint(address to_, uint256 tokenId_) external {
        _mint(to_, tokenId_);
    }

}

contract NFTMarketplaceTest is Test {

    NFTMarketplace marketplaceTesting;
    mockNFT mockNFTTesting;
    address deployer = vm.addr(1);
    address user = vm.addr(2);
    uint256 tokenId = 0;

    function setUp() public {
        vm.startPrank(deployer);
        marketplaceTesting = new NFTMarketplace();
        mockNFTTesting = new mockNFT();
        vm.stopPrank();
        
        vm.startPrank(user);
        mockNFTTesting.mint(user, tokenId);
        vm.stopPrank();
    }

    function testMintNFT() public view  {
        address ownerNFT = mockNFTTesting.ownerOf(tokenId);
        assert(ownerNFT == user);
    }

    function testShouldRevertIfPriceIsZero() public {
        vm.startPrank(user);
        vm.expectRevert("Price can not be 0");
        marketplaceTesting.listNFT(address(mockNFTTesting), tokenId, 0);
        vm.stopPrank();
    }

    function testShouldRevertIfNotOwner() public {
        vm.startPrank(user);
        address user2_ = vm.addr(3);
        uint256 tokenId_ = 1;
        mockNFTTesting.mint(user2_, tokenId_);
        vm.expectRevert("You are not the owner of the NFT");
        marketplaceTesting.listNFT(address(mockNFTTesting), tokenId_, 1);
        vm.stopPrank();
    }

    function testListNFTCorrectly() public{
        vm.startPrank(user);
        (address sellerBefore,,,) = marketplaceTesting.listing(address(mockNFTTesting), tokenId);
        marketplaceTesting.listNFT(address(mockNFTTesting), tokenId, 1);
        (address sellerAfter,,,) = marketplaceTesting.listing(address(mockNFTTesting), tokenId);
        assert(sellerBefore == address(0) && sellerAfter == user);
        vm.stopPrank();
    }
    
    function testCancelListShouldRevertIfNotOwner() public {
        vm.startPrank(user);
        (address sellerBefore,,,) = marketplaceTesting.listing(address(mockNFTTesting), tokenId);
        marketplaceTesting.listNFT(address(mockNFTTesting), tokenId, 1);
        (address sellerAfter,,,) = marketplaceTesting.listing(address(mockNFTTesting), tokenId);
        assert(sellerBefore == address(0) && sellerAfter == user);
        vm.stopPrank();

        address user2 = vm.addr(3);
        vm.startPrank(user2);
        vm.expectRevert("You are not the listing owner");
        marketplaceTesting.cancelList(address(mockNFTTesting), tokenId);
        vm.stopPrank();
    }

    function testCancelListShouldWorkCorrectly() public {
        vm.startPrank(user);
        (address sellerBefore,,,) = marketplaceTesting.listing(address(mockNFTTesting), tokenId);
        marketplaceTesting.listNFT(address(mockNFTTesting), tokenId, 1);
        (address sellerAfter,,,) = marketplaceTesting.listing(address(mockNFTTesting), tokenId);
        assert(sellerBefore == address(0) && sellerAfter == user);
        marketplaceTesting.cancelList(address(mockNFTTesting), tokenId);
        (address sellerAfter2,,,) = marketplaceTesting.listing(address(mockNFTTesting), tokenId);
        assert(sellerAfter2 == address(0));
        vm.stopPrank();
    }

    function testCanNotBuyUnlistedNFT() public {
        address user2 = vm.addr(3);
        vm.startPrank(user2);
        vm.expectRevert("Listing not exists");
        marketplaceTesting.buyNFT(address(mockNFTTesting), tokenId);
        vm.stopPrank();
    }

    function testCanNotBuyWithIncorrectPay() public {
        vm.startPrank(user);
        uint256 price = 1e18;
        (address sellerBefore,,,) = marketplaceTesting.listing(address(mockNFTTesting), tokenId);
        marketplaceTesting.listNFT(address(mockNFTTesting), tokenId, price);
        (address sellerAfter,,,) = marketplaceTesting.listing(address(mockNFTTesting), tokenId);
        assert(sellerBefore == address(0) && sellerAfter == user);
        vm.stopPrank();

        address user2 = vm.addr(3);
        vm.startPrank(user2);
        vm.deal(user2, price);
        vm.expectRevert("Incorrect amount");
        marketplaceTesting.buyNFT{value: price -1}(address(mockNFTTesting), tokenId);
        vm.stopPrank();
    }

    function testShouldBuyNFTCorrectly() public {
        vm.startPrank(user);
        uint256 price = 1e18;
        (address sellerBefore,,,) = marketplaceTesting.listing(address(mockNFTTesting), tokenId);
        marketplaceTesting.listNFT(address(mockNFTTesting), tokenId, price);
        (address sellerAfter,,,) = marketplaceTesting.listing(address(mockNFTTesting), tokenId);
        assert(sellerBefore == address(0) && sellerAfter == user);
        mockNFTTesting.approve(address(marketplaceTesting), tokenId);
        vm.stopPrank();

        address user2 = vm.addr(3);
        vm.startPrank(user2);
        vm.deal(user2, price);
        uint256 balanceBefore = address(user).balance;
        address ownerBefore = mockNFTTesting.ownerOf(tokenId);
        (address sellerBefore2,,,) = marketplaceTesting.listing(address(mockNFTTesting), tokenId);
        marketplaceTesting.buyNFT{value: price}(address(mockNFTTesting), tokenId);
        (address sellerAfter2,,,) = marketplaceTesting.listing(address(mockNFTTesting), tokenId);   
        address ownerAfter = mockNFTTesting.ownerOf(tokenId);  
        uint256 balanceAfter = address(user).balance;
        assert(sellerBefore2 == user && sellerAfter2 == address(0));
        assert(ownerBefore == user && ownerAfter == user2);
        assert(balanceAfter == balanceBefore + price);
        vm.stopPrank();
    }
}
