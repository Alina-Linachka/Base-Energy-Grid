// SPDX-License-Identifier: MIT
pragma solidity 0.8.37;
interface INexusEnergyGrid {
    function buyEnergyCredits(uint256 listingId, uint256 amountKwh) external payable;
    function listEnergyCredits(uint256 pricePerKwhWei, uint256 availableKwh, bytes32 sourceHash) external returns (uint256);
}
