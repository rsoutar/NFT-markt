// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IERC721.sol";

contract Market {
    enum ListingStatus {
        Active,
        Sold,
        Cancelled
    }

    struct Listing {
        ListingStatus status;
        address seller;
        address token;
        uint tokenId;
        uint price;
    }

    event Listed(
        uint listingId,
        address seller,
        address token,
        uint tokenId,
        uint price
    );

    event Sold(
        uint listingId,
        address buyer,
        address token,
        uint tokenId,
        uint price
    );

    event Cancelled(
        uint listingId,
        address seller
    );

    uint private _listingId = 0;
    mapping(uint => Listing) private _listings;

    function listToken(address token, uint tokenId, uint price) external {
        IERC721(token).transferFrom(msg.sender, address(this), tokenId);
        Listing memory listing = Listing(
            ListingStatus.Active,
            msg.sender,
            token,
            tokenId,
            price
        );

        _listingId++;

        _listings[_listingId] = listing;

        emit Listed(
            _listingId,
            msg.sender,
            token,
            tokenId,
            price
        );
    }

    // function can read and write
    // view - read-only
    // pure - no read, no write
    // payable - read and write

    function getListing(uint listingId) public view returns (Listing memory) {
        return _listings[listingId];
    }

    function buyToken(uint listingId) external payable {
        Listing storage listing = _listings[listingId];

        require(msg.sender != listing.seller, "Cannot buy your own listing");
        require(listing.status == ListingStatus.Active, "Listing is not active");
        require(msg.value >= listing.price, "Not enough ETH");

        IERC721(listing.token).transferFrom(address(this), msg.sender, listing.tokenId);
        payable(listing.seller).transfer(listing.price);

        emit Sold(
            listingId,
            msg.sender,
            listing.token,
            listing.tokenId,
            listing.price
        );
    }

    function cancel(uint listingId) public {
        Listing storage listing = _listings[listingId];

        require(msg.sender == listing.seller, "Only the seller can cancel the listing");
        require(listing.status == ListingStatus.Active, "Listing is not active");
        
        listing.status = ListingStatus.Cancelled;

        IERC721(listing.token).transferFrom(address(this), listing.seller, listing.tokenId);

        emit Cancelled(
            listingId,
            listing.seller
        );
    }
}