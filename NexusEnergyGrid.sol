// SPDX-License-Identifier: MIT
pragma solidity 0.8.37;

contract NexusEnergyGrid {
    struct EnergyListing {
        address payable producer;
        uint256 pricePerKwhWei;
        uint256 availableKwh;
        bool isActive;
        bytes32 sourceHash;
    }

    address payable public immutable gridAdmin;
    string public gridDescriptor;
    uint256 public platformFeeBps; // 250 = 2.5%
    uint256 public listingCounter;
    uint256 public accumulatedFees;
    bool public isGridHalted;

    mapping(address => bool) public verifiedProducers;
    mapping(uint256 => EnergyListing) public energyListings;

    event ProducerAdded(address indexed producer);
    event EnergyPurchased(uint256 indexed listingId, address indexed buyer, uint256 amountKwh, uint256 totalCost);
    event ListingCanceled(uint256 indexed listingId);
    event TreasuryDeposited(address indexed funder, uint256 amount);
    event ReservesEmptied(address indexed admin, uint256 amount);
    event FeesGathered(address indexed admin, uint256 amount);
    event GridHaltToggled(bool isHalted);
    event EnergyListed(uint256 indexed listingId, address indexed producer, uint256 price, uint256 amountKwh);
    event ProducerRevoked(address indexed producer);
    event DescriptorUpdated(string newDescriptor);

    modifier onlyAdmin() {
        require(msg.sender == gridAdmin, "NexusGrid: Access denied");
        _;
    }

    modifier whenNotHalted() {
        require(!isGridHalted, "NexusGrid: Grid is halted");
        _;
    }

    constructor() {
        gridAdmin = payable(msg.sender);
        gridDescriptor = "Nexus Base P2P Energy Grid v1";
        platformFeeBps = 250; // 2.5%
        isGridHalted = false;
        verifiedProducers[msg.sender] = true;
    }

    // 1. addVerifiedProducer
    function addVerifiedProducer(address producer) external onlyAdmin {
        require(!verifiedProducers[producer], "NexusGrid: Already verified");
        verifiedProducers[producer] = true;
        emit ProducerAdded(producer);
    }

    // 2. buyEnergyCredits
    function buyEnergyCredits(uint256 listingId, uint256 amountKwh) external payable whenNotHalted {
        EnergyListing storage e = energyListings[listingId];
        require(listingId > 0 && listingId <= listingCounter, "NexusGrid: Invalid ID");
        require(e.isActive, "NexusGrid: Listing inactive");
        require(amountKwh > 0 && amountKwh <= e.availableKwh, "NexusGrid: Invalid amount");

        uint256 totalCost = amountKwh * e.pricePerKwhWei;
        require(msg.value >= totalCost, "NexusGrid: Insufficient payment");

        uint256 fee = (totalCost * platformFeeBps) / 10000;
        uint256 producerShare = totalCost - fee;

        accumulatedFees += fee;
        e.availableKwh -= amountKwh;

        if (e.availableKwh == 0) {
            e.isActive = false;
        }

        if (producerShare > 0) {
            (bool sent, ) = e.producer.call{value: producerShare}("");
            require(sent, "NexusGrid: Payout failed");
        }

        if (msg.value > totalCost) {
            (bool refunded, ) = payable(msg.sender).call{value: msg.value - totalCost}("");
            require(refunded, "NexusGrid: Refund failed");
        }

        emit EnergyPurchased(listingId, msg.sender, amountKwh, totalCost);
    }

    // 3. cancelEnergyListing
    function cancelEnergyListing(uint256 listingId) external {
        EnergyListing storage e = energyListings[listingId];
        require(listingId > 0 && listingId <= listingCounter, "NexusGrid: Invalid ID");
        require(msg.sender == e.producer || msg.sender == gridAdmin, "NexusGrid: Unauthorized");
        require(e.isActive, "NexusGrid: Already inactive");

        e.isActive = false;
        emit ListingCanceled(listingId);
    }

    // 4. depositGridTreasury
    function depositGridTreasury() external payable whenNotHalted {
        require(msg.value > 0, "NexusGrid: Zero deposit");
        accumulatedFees += msg.value;
        emit TreasuryDeposited(msg.sender, msg.value);
    }

    // 5. emptyGridReserves
    function emptyGridReserves() external onlyAdmin {
        uint256 balance = address(this).balance;
        require(balance > 0, "NexusGrid: Zero balance");

        accumulatedFees = 0;
        (bool sent, ) = gridAdmin.call{value: balance}("");
        require(sent, "NexusGrid: Sweep failed");

        emit ReservesEmptied(gridAdmin, balance);
    }

    // 6. gatherPlatformFees
    function gatherPlatformFees() external onlyAdmin {
        uint256 amount = accumulatedFees;
        require(amount > 0, "NexusGrid: Zero fees");

        accumulatedFees = 0;
        (bool sent, ) = gridAdmin.call{value: amount}("");
        require(sent, "NexusGrid: Harvest failed");

        emit FeesGathered(gridAdmin, amount);
    }

    // 7. haltEnergyGrid
    function haltEnergyGrid(bool isHalted) external onlyAdmin {
        isGridHalted = isHalted;
        emit GridHaltToggled(isHalted);
    }

    // 8. listEnergyCredits
    function listEnergyCredits(uint256 pricePerKwhWei, uint256 availableKwh, bytes32 sourceHash) external whenNotHalted returns (uint256) {
        require(verifiedProducers[msg.sender], "NexusGrid: Not a verified producer");
        require(pricePerKwhWei > 0 && availableKwh > 0, "NexusGrid: Invalid parameters");

        listingCounter++;
        energyListings[listingCounter] = EnergyListing({
            producer: payable(msg.sender),
            pricePerKwhWei: pricePerKwhWei,
            availableKwh: availableKwh,
            isActive: true,
            sourceHash: sourceHash
        });

        emit EnergyListed(listingCounter, msg.sender, pricePerKwhWei, availableKwh);
        return listingCounter;
    }

    // 9. revokeProducerStatus
    function revokeProducerStatus(address producer) external onlyAdmin {
        require(verifiedProducers[producer], "NexusGrid: Not a producer");
        require(producer != msg.sender, "NexusGrid: Cannot revoke self");
        verifiedProducers[producer] = false;
        emit ProducerRevoked(producer);
    }

    // 10. updateGridDescriptor
    function updateGridDescriptor(string calldata newDescriptor) external onlyAdmin {
        require(bytes(newDescriptor).length > 0, "NexusGrid: Empty string");
        gridDescriptor = newDescriptor;
        emit DescriptorUpdated(newDescriptor);
    }
}