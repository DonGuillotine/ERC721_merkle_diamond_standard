import { MerkleTree } from 'merkletreejs';
import keccak256 from 'keccak256';
import fs from 'fs';

interface Claim {
  address: string;
  amount: number;
}

// Whitelist data
const whitelist: Claim[] = [
  { address: '0x1111111111111111111111111111111111111111', amount: 100 },
  { address: '0x2222222222222222222222222222222222222222', amount: 200 },
  { address: '0x3333333333333333333333333333333333333333', amount: 300 },
  { address: '0x4444444444444444444444444444444444444444', amount: 400 },
  { address: '0x5555555555555555555555555555555555555555', amount: 500 },
];

// Generate leaves
const leaves = whitelist.map((claim) =>
  keccak256(Buffer.concat([
    Buffer.from(claim.address.slice(2), 'hex'),
    Buffer.from(claim.amount.toString(16).padStart(64, '0'), 'hex')
  ]))
);

// Create tree
const tree = new MerkleTree(leaves, keccak256, { sort: true });

// Get root
const root = tree.getHexRoot();

// Generate proofs
const proofs = whitelist.map((claim, index) => ({
  address: claim.address,
  amount: claim.amount,
  proof: tree.getHexProof(leaves[index])
}));

// Create output object
const output = {
    root: root,
    addresses: whitelist.map(w => w.address),
    amounts: whitelist.map(w => w.amount),
    proofs: proofs.map(p => p.proof)
  };
  
  // Write to file
  fs.writeFileSync('merkleData.json', JSON.stringify(output, null, 2));

console.log('Merkle root:', root);
console.log('Merkle data written to merkleData.json');