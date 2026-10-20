# Nexus Energy Grid

A decentralized peer-to-peer energy trading marketplace built on the Base L2 ecosystem. This protocol connects renewable energy producers directly with consumers, allowing the tokenized exchange of surplus kilowatt-hours (kWh) without centralized utility intermediaries.

## Core Mechanics
* **Automated Settlement & Refunds:** Buyers can purchase exact kWh amounts. The smart contract automatically calculates the total cost, routes the payment minus a platform fee to the producer, and instantly refunds any excess ETH sent by the buyer.
* **Producer Verification:** Implements strict access control to ensure only audited hardware endpoints (e.g., IoT-enabled solar inverters) or verified prosumers can list energy credits on the grid.
* **State-Locked Listings:** Ensures that energy listings accurately reflect real-world capacity. Listings auto-deactivate upon depletion to prevent over-purchasing.

## Architecture
Developed using Solidity `0.8.37`. The contract optimizes gas utilization during micro-transactions by tightly packing structural data and leveraging the `call` opcode for secure fund transfers.
