🧬 Genome Market – Tokenized DNA Licensing Marketplace

Overview

Genome Market is a decentralized marketplace built on the Stacks blockchain, enabling users to tokenize DNA snippets and license them for research or commercial use.
It introduces an innovative model for scientific collaboration and intellectual property protection by allowing genetic data owners to control access and monetize usage rights transparently.

🌟 Features

DNA Tokenization – Users can mint unique tokens representing DNA snippets with metadata including sequence hash, length, and description.

Dynamic Pricing – Owners can update listing prices anytime.

License Purchases – Researchers can purchase usage licenses for specific DNA snippets using STX.

Earnings Tracking – Total owner earnings are tracked and viewable on-chain.

Platform Fees – A configurable platform fee (default 5%) ensures sustainability for the marketplace operator.

Ownership Control – Snippet owners can toggle sale availability and adjust prices as needed.

🧩 Contract Details
Item	Description
Title	genome-market
Version	1.0.0
Language	Clarity
Summary	Marketplace for tokenizing and licensing DNA snippets for research
Owner	The contract deployer (tx-sender during deployment)
Platform Fee	Default: 5% (modifiable up to 20%)
⚙️ Data Structures
1. dna-snippets

Stores metadata for each DNA snippet.

{ snippet-id: uint } => {
  owner: principal,
  dna-hash: (buff 32),
  description: (string-ascii 256),
  sequence-length: uint,
  price: uint,
  for-sale: bool,
  created-at: uint
}

2. licenses

Tracks license purchases by researchers.

{ snippet-id: uint, licensee: principal } => {
  purchased-at: uint,
  price-paid: uint
}

3. owner-earnings

Records total earnings per snippet owner.

{ owner: principal } => { total-earned: uint }

🚀 Public Functions
tokenize-snippet (dna-hash description sequence-length price)

Tokenizes a new DNA snippet for sale.

update-price (snippet-id new-price)

Allows snippet owner to change the listing price.

toggle-for-sale (snippet-id)

Turns the snippet’s “for sale” status on or off.

purchase-license (snippet-id)

Allows a researcher to buy a license for a snippet.
Automatically distributes payments to the owner and platform, and records ownership of the license.

update-platform-fee (new-fee)

Only callable by the contract owner to update the platform fee (max 20%).

🔍 Read-Only Functions
Function	Description
get-snippet(snippet-id)	Returns snippet metadata
has-license(snippet-id, user)	Checks if a user owns a license
get-license(snippet-id, licensee)	Retrieves details of a specific license
get-owner-earnings(owner)	Returns total earnings of an owner
get-snippet-count()	Returns total number of snippets created
get-platform-fee()	Returns the current platform fee percentage
💰 Payment Logic

Buyer pays full snippet price (price).

Platform fee = (price * platform-fee-percentage) / 100.

Snippet owner receives price - platform-fee.

Payments are processed using stx-transfer?.

🔒 Error Codes
Code	Error	Description
u100	err-owner-only	Only contract owner can call
u101	err-not-token-owner	Caller isn’t snippet owner
u102	err-snippet-not-found	Invalid snippet ID
u103	err-snippet-already-exists	Duplicate snippet
u104	err-not-for-sale	Snippet not available
u105	err-insufficient-payment	Payment mismatch
u106	err-already-licensed	User already licensed snippet
u107	err-invalid-price	Invalid (zero) price or length
🧪 Example Flow

User A tokenizes a DNA snippet:

(contract-call? .genome-market tokenize-snippet 0xabc... "Human Mitochondrial DNA" u16569 u10000)


User A lists it for sale automatically (for-sale = true).

Researcher B purchases a license:

(contract-call? .genome-market purchase-license u0)


Researcher B verifies ownership:

(contract-call? .genome-market has-license u0 tx-sender)


User A checks total earnings:

(contract-call? .genome-market get-owner-earnings tx-sender)

🧠 Future Enhancements

Add royalty tiers for commercial vs. academic licensing.

Implement data anonymization or encrypted snippet storage.

Support secondary license transfers or sublicensing.

Integrate with off-chain genomic storage or IPFS.

📜 License

MIT License