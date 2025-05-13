# AuctionHouse Smart Contract

This Solidity smart contract implements a simple auction house where users can bid on an item, and the highest bidder at the end of the auction wins.

## Features

* **Bidding:** Users can place bids on the item.
* **Higher Bid Requirement:** New bids must be higher than the current highest bid.
* **Automatic Refund for Outbid Bidders:** When a higher bid is placed, the previous highest bidder's funds are automatically marked for refund.
* **Withdrawal:** Bidders whose bids are no longer the highest can withdraw their funds.
* **Auction End Time:** The auction has a defined end time.
* **Auction End Function:** Only the contract owner can end the auction after the specified time.
* **Winner Determination:** Once the auction ends, the highest bidder is declared the winner.
* **Fund Transfer to Owner:** Upon auction end, the highest bid amount is transferred to the contract owner.
* **Event Logging:** Events are emitted for new bids, auction end, and withdrawals.
* **View Functions:** Public view functions to get the list of bidders, the winner details, and pending returns for a specific bidder.

## Getting Started

### Prerequisites

* Node.js and npm (or yarn) installed on your system.
* Hardhat or Truffle development environment.
* Metamask or another Ethereum wallet.

### Deployment

1.  **Clone the repository (if applicable):**
    ```bash
    git clone <repository_url>
    cd <repository_directory>
    ```

2.  **Install dependencies:**
    Using npm:
    ```bash
    npm install
    ```
    or using yarn:
    ```bash
    yarn install
    ```

3.  **Compile the contract:**
    Using Hardhat:
    ```bash
    npx hardhat compile
    ```
    or using Truffle:
    ```bash
    truffle compile
    ```

4.  **Deploy the contract to a network:**
    Configure your deployment script (e.g., in `scripts/deploy.js` for Hardhat or migrations for Truffle) with the desired item name and auction duration (in seconds).

    Using Hardhat (example):
    ```javascript
    // scripts/deploy.js
    const hre = require("hardhat");

    async function main() {
      const AuctionHouse = await hre.ethers.getContractFactory("AuctionHouse");
      const item = "Rare Digital Artwork";
      const duration = 60 * 60 * 24; // 24 hours
      const auctionHouse = await AuctionHouse.deploy(item, duration);

      await auctionHouse.deployed();

      console.log("AuctionHouse deployed to:", auctionHouse.address);
    }

    main().catch((error) => {
      console.error(error);
      process.exitCode = 1;
    });
    ```

    Then run the deployment script:
    ```bash
    npx hardhat run scripts/deploy.js --network <network_name>
    ```

    Using Truffle (example migration):
    ```javascript
    // migrations/2_deploy_contracts.js
    const AuctionHouse = artifacts.require("AuctionHouse");

    module.exports = function (deployer) {
      const item = "Collectible Trading Card";
      const duration = 60 * 60 * 48; // 48 hours
      deployer.deploy(AuctionHouse, item, duration);
    };
    ```

    Then run the migration:
    ```bash
    truffle migrate --network <network_name>
    ```

5.  **Interact with the contract:**
    Once deployed, you can interact with the contract using tools like Remix, Etherscan (on public testnets/mainnet), or by writing your own scripts using libraries like Ethers.js or Web3.js.

## Contract Details

### State Variables

* `owner`: (`address`) The address of the contract owner, set during deployment.
* `item`: (`string`) The name or description of the item being auctioned.
* `auctionEndTime`: (`uint`) The timestamp (in seconds since Unix epoch) when the auction will end.
* `highestBidder`: (`address` private) The address of the current highest bidder.
* `highestBid`: (`uint` private) The current highest bid amount in Wei.
* `ended`: (`bool` public) A flag indicating whether the auction has ended.
* `bids`: (`mapping(address => uint)` public) A mapping of bidder addresses to their total bid amount.
* `pendingReturns`: (`mapping(address => uint)` public) A mapping of bidder addresses to the amount of Ether they can withdraw.
* `biddersList`: (`address[]` public) An array containing the addresses of all participants who have placed a bid.

### Events

* `NewBid(address indexed bidder, uint amount)`: Emitted when a new bid is placed.
* `AuctionEnded(address indexed winner, uint amount)`: Emitted when the auction ends, indicating the winner and the winning bid amount.
* `Withdrawal(address indexed bidder, uint amount)`: Emitted when a bidder successfully withdraws their pending returns.

### Functions

* `constructor(string memory _item, uint _duration)`: Initializes the contract with the item name and the auction duration in seconds. Sets the `owner` to the deployer.
* `bid()` (`external` `payable`): Allows users to place a bid.
    * Requires the auction to not have ended.
    * Requires the bid amount (`msg.value`) to be greater than 0.
    * Requires the new total bid (including previous bids from the same address) to be higher than the current `highestBid`.
    * Updates the `bids` mapping for the bidder.
    * Updates `highestBidder` and `highestBid` if the new bid is the highest.
    * Automatically refunds the previous highest bidder (if any) by adding their bid to their `pendingReturns`.
    * Emits the `NewBid` event.
* `withdraw()` (`external`): Allows bidders to withdraw their `pendingReturns`.
    * Requires the bidder to have a non-zero amount in `pendingReturns`.
    * Resets the bidder's `pendingReturns` to 0.
    * Transfers the withdrawable amount to the bidder's address.
    * Emits the `Withdrawal` event.
* `endAuction()` (`external`): Allows the contract owner to end the auction.
    * Requires the current time to be greater than or equal to `auctionEndTime`.
    * Requires the auction not to have already ended (`ended` is false).
    * Sets the `ended` flag to true.
    * Transfers the `highestBid` to the `owner`.
    * Emits the `AuctionEnded` event.
* `getBiddersList()` (`external` `view` `returns (address[] memory)`): Returns the list of addresses that have placed bids.
* `getWinner()` (`external` `view` `returns (address, uint)`): Returns the address of the winner and the winning bid amount. Requires the auction to have ended.
* `getPendingReturns(address bidder)` (`external` `view` `returns (uint)`): Returns the amount of Ether that a specific bidder can withdraw.

## Security Considerations

* **Re-entrancy:** The `withdraw()` and `endAuction()` functions involve sending Ether. While the current implementation uses a low-level `call` with a check for success, it's generally recommended to follow the Checks-Effects-Interactions pattern to mitigate re-entrancy risks in more complex scenarios.
* **Denial of Service (DoS):** In extreme cases with a very large number of bidders, the `biddersList` could potentially grow large, which might impact gas costs for functions iterating over it (though this contract doesn't have such iterations).
* **Gas Limit:** Bidders should ensure their gas limit is sufficient for their transactions, especially for higher bids that might involve refunding a previous bidder.
* **Timestamp Dependence:** The auction end time relies on `block.timestamp`, which can be slightly manipulated by miners. For critical applications, more robust time mechanisms might be considered.

## Potential Improvements

* **Minimum Bid Increment:** Implement a minimum increment for new bids.
* **Extending Auction on Late Bids:** Allow the auction end time to be extended if a bid is placed very close to the original end time.
* **Support for Different Token Types (ERC-20, ERC-721):** Modify the contract to handle auctions for non-Ether assets.
* **Proxy Pattern:** For upgradability, consider deploying the contract behind a proxy.
* **Off-Chain Notifications:** Integrate with off-chain notification systems to inform bidders about being outbid or the auction ending.

## License

MIT
