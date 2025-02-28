# Bitcoin Name Service (BNS) - Enhanced Smart Contract

## Overview

The Bitcoin Name Service (BNS) is a decentralized naming system built on the Stacks blockchain. It allows users to register human-readable names and associate them with Bitcoin addresses. This enhanced version of the BNS smart contract introduces multi-address support, metadata storage, and improved name management features.

## Features

- **Name Registration**: Register a unique name and associate it with a primary Bitcoin address and Stacks address.
- **Multi-Address Support**: Add up to 5 additional Bitcoin addresses and Stacks addresses to a name.
- **Metadata Storage**: Store metadata (e.g., a URI) associated with a name.
- **Name Expiration and Renewal**: Names have a validity period and can be renewed before or during the grace period.
- **Name Transfer**: Transfer ownership of a name to another principal.
- **Grace Period**: After a name expires, it enters a grace period during which the original owner can renew it.
- **Admin Controls**: The contract owner can update configuration parameters.

## Contract Details

### Data Structures

- **`registered-names`**: A map storing name records, including:
  - `owner`: The principal who owns the name.
  - `primary-btc-address`: The primary Bitcoin address associated with the name.
  - `primary-stacks-address`: The primary Stacks address associated with the name.
  - `additional-btc-addresses`: A list of up to 5 additional Bitcoin addresses.
  - `additional-stacks-addresses`: A list of up to 5 additional Stacks addresses.
  - `expiration`: The block height when the name expires.
  - `grace-period-end`: The block height when the grace period ends.
  - `metadata-uri`: Optional metadata (e.g., a URI) associated with the name.

### Constants

- `REGISTRATION_PERIOD_DAYS`: The validity period of a name in days (default: 365 days).
- `GRACE_PERIOD_DAYS`: The grace period after expiration in days (default: 30 days).
- `REGISTRATION_COST_STX`: The cost to register or renew a name (default: 10,000 STX).
- `NAME_TRANSFER_FEE_STX`: The fee to transfer a name to a new owner (default: 1,000 STX).

### Functions

#### Public Functions

- **`register-name`**: Register a new name with a primary Bitcoin address and optional metadata.
  ```clarity
  (define-public (register-name (name (string-ascii 64)) (btc-address (buff 33)) (metadata-uri (optional (string-utf8 256))))
  ```

- **`add-btc-address`**: Add an additional Bitcoin address to a name.
  ```clarity
  (define-public (add-btc-address (name (string-ascii 64)) (btc-address (buff 33))))
  ```

- **`add-stacks-address`**: Add an additional Stacks address to a name.
  ```clarity
  (define-public (add-stacks-address (name (string-ascii 64)) (stacks-address principal))
  ```

- **`update-metadata`**: Update the metadata URI associated with a name.
  ```clarity
  (define-public (update-metadata (name (string-ascii 64)) (new-metadata-uri (optional (string-utf8 256))))
  ```

- **`transfer-name`**: Transfer ownership of a name to another principal.
  ```clarity
  (define-public (transfer-name (name (string-ascii 64)) (new-owner principal))
  ```

- **`renew-name`**: Renew an existing name before or during the grace period.
  ```clarity
  (define-public (renew-name (name (string-ascii 64)))
  ```

#### Read-Only Functions

- **`get-name-status`**: Check the status of a name (active, grace-period, expired, or available).
  ```clarity
  (define-read-only (get-name-status (name (string-ascii 64))))
  ```

---

## Usage

### Registering a Name

To register a new name, call the `register-name` function with the desired name, a Bitcoin address, and optional metadata.

```clarity
(register-name "example-name" 0x1a2b3c4d5e6f7g8h9i0j1k2l3m4n5o6p7q8r9s0t none)
```

### Adding Additional Addresses

To add an additional Bitcoin address or Stacks address to a name, call the `add-btc-address` or `add-stacks-address` function.

```clarity
(add-btc-address "example-name" 0x9s0t1a2b3c4d5e6f7g8h9i0j1k2l3m4n5o6p7q8r)
(add-stacks-address "example-name" 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
```

### Updating Metadata

To update the metadata URI associated with a name, call the `update-metadata` function.

```clarity
(update-metadata "example-name" (some "https://example.com/metadata.json"))
```

### Transferring a Name

To transfer ownership of a name to another principal, call the `transfer-name` function.

```clarity
(transfer-name "example-name" 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
```

### Renewing a Name

To renew an existing name, call the `renew-name` function.

```clarity
(renew-name "example-name")
```

### Checking Name Status

To check the status of a name, call the `get-name-status` function.

```clarity
(get-name-status "example-name")
```

---

## Deployment

1. **Compile the Contract**: Use a Clarity-compatible toolchain to compile the contract.
2. **Deploy the Contract**: Deploy the contract to the Stacks blockchain using a compatible wallet or CLI tool.
3. **Initialize the Contract**: Call the initialization function (if any) to set up the contract.

---

## Testing

Before deploying the contract to the mainnet, thoroughly test it on a testnet or local development environment. Use unit tests to verify the functionality of each function and edge cases.

---

## Security Considerations

- **Access Control**: Ensure that only the contract owner can update configuration parameters.
- **Name Validation**: Implement robust name validation to prevent invalid or malicious names.
- **Grace Period**: Handle the grace period carefully to avoid name squatting.
- **Error Handling**: Provide clear error messages for failed transactions.

---

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

---

## Contributing

Contributions are welcome! Please open an issue or submit a pull request for any improvements or bug fixes.

---

## Contact

For any questions or support, please contact the project maintainers.
