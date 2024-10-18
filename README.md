# ERC721 NFT with Merkle Distributor

This project implements an ERC721 NFT contract with a Merkle distributor for whitelisted addresses using the Diamond Standard (EIP-2535). It's built using the Diamond Standard, Foundry framework and includes a presale mechanism.

## Features

- ERC721 NFT implementation
- Merkle-based whitelist distribution
- Presale functionality
- Diamond Standard (EIP-2535) for upgradeable contracts
- Foundry for testing and deployment

## Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation.html)
- [Node.js](https://nodejs.org/) (for Merkle tree generation script)

## Installation

1. Clone the repository:
   ```
   git clone https://github.com/DonGuillotine/ERC721_merkle_diamond_standard.git
   cd ERC721_merkle_diamond_standard
   ```

2. Install Node.js dependencies:
   ```
   npm install
   ```

3. Install Foundry dependencies:
   ```
   forge install
   ```

## Usage

### Generate Merkle Tree

To generate the Merkle tree and proofs:

```
npx ts-node scripts/generateMerkleTree.ts
```

This will create a `merkleData.json` file in the root directory.

### Run Tests

To run the Foundry tests:

```
forge test
```

For more detailed output:

```
forge test -vv
```

All Tests Passed

![Screenshot 2024-10-18 175045](https://github.com/user-attachments/assets/4eeb324c-fb71-49f4-a8f1-e515b8910c04)


### Deployment

To deploy the contracts (make sure to set up your .env file first):

```
forge script script/deploy.s.sol:DeployDiamond --rpc-url <YOUR_RPC_URL> --broadcast --verify
```

## Project Structure

- `contracts/`: Solidity smart contracts
  - `facets/`: Diamond facets (ERC721Facet, MerkleFacet, PresaleFacet)
  - `interfaces/`: Contract interfaces
  - `libraries/`: Helper libraries
- `scripts/`: TypeScript and deployment scripts
- `test/`: Foundry test files

## Key Components

1. **Diamond.sol**: The main contract implementing the Diamond Standard.
2. **ERC721Facet.sol**: Implements the ERC721 standard.
3. **MerkleFacet.sol**: Handles the Merkle-based whitelist distribution.
4. **PresaleFacet.sol**: Manages the presale functionality.
5. **generateMerkleTree.ts**: Script to generate Merkle tree and proofs.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
