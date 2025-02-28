# Bitcoin Name Service (BNS) - Smart Contract

## Overview

The Bitcoin Name Service (BNS) is a decentralized naming system built on the Stacks blockchain. It allows users to register human-readable names and associate them with Bitcoin addresses. This smart contract provides the core functionality for name registration, expiration, and Bitcoin address mapping.

## Features

- **Name Registration**: Users can register a unique name and associate it with a Bitcoin address.
- **Name Expiration**: Registered names have a validity period and can be renewed.
- **Bitcoin Address Mapping**: Each name is mapped to a Bitcoin address, which can be updated by the name owner.
- **Grace Period**: After a name expires, it enters a grace period during which the original owner can renew it.
- **Name Validation**: Names must meet specific criteria (e.g., minimum length, valid characters).
- **Registration Fee**: A fee is required to register or renew a name, which is paid in STX tokens.

## Contract Details

### Constants

- `contract-owner`: The principal (address) that deployed the contract.
- Error Codes:
  - `err-owner-only`: Operation restricted to the contract owner.
  - `err-not-found`: Name not found.
  - `err-name-taken`: Name is already registered.
  - `err-name-expired`: Name has expired.
  - `err-insufficient-payment`: Insufficient STX balance to pay the fee.
  - `err-not-name-owner`: Operation restricted to the name owner.
  - `err-in-grace-period`: Name is in the grace period.
  - `err-invalid-name`: Name does not meet validation criteria.

### Configuration Variables

- `registration-fee`: The fee required to register or renew a name (default: 10 STX).
- `name-validity-period`: The number of blocks a name remains valid (default: ~1 year).
- `grace-period`: The number of blocks a name remains in the grace period after expiration (default: ~30 days).

### Data Structures

- `name-records`: A map storing name records, including:
  - `owner`: The principal who owns the name.
  - `bitcoin-address`: The Bitcoin address associated with the name.
  - `registered-at`: The block height when the name was registered.
  - `expires-at`: The block height when the name expires.
  - `renewal-count`: The number of times the name has been renewed.
- `principal-to-names`: A map storing the list of names owned by a principal.

### Functions

#### Read-Only Functions

- `get-registration-fee`: Returns the current registration fee.
- `get-name-validity-period`: Returns the current name validity period.
- `is-name-available`: Checks if a name is available for registration.
- `is-in-grace-period`: Checks if a name is in the grace period.
- `get-name-owner`: Returns the owner of a name.
- `get-name-details`: Returns the details of a name.
- `get-names-by-owner`: Returns the list of names owned by a principal.

#### Public Functions

- `set-registration-fee`: Sets the registration fee (restricted to the contract owner).
- `register-name`: Registers a new name and associates it with a Bitcoin address.
- `renew-name`: Renews an existing name.
- `update-bitcoin-address`: Updates the Bitcoin address associated with a name (restricted to the name owner).

### Helper Functions

- `is-valid-name`: Validates a name according to specific criteria.
- `is-valid-name-chars`: Helper function to validate name characters.
- `is-name-expired`: Checks if a name has expired.

## Usage

### Registering a Name

To register a new name, call the `register-name` function with the desired name and a valid Bitcoin address. The name must be unique and meet the validation criteria. The registration fee must be paid in STX.

```clarity
(register-name "example-name" 0x1a2b3c4d5e6f7g8h9i0j1k2l3m4n5o6p7q8r9s0t)
```

### Renewing a Name

To renew an existing name, call the `renew-name` function with the name. The name must be owned by the caller or be in the grace period. The renewal fee must be paid in STX.

```clarity
(renew-name "example-name")
```

### Updating a Bitcoin Address

To update the Bitcoin address associated with a name, call the `update-bitcoin-address` function with the name and the new Bitcoin address. The caller must be the owner of the name.

```clarity
(update-bitcoin-address "example-name" 0x9s0t1a2b3c4d5e6f7g8h9i0j1k2l3m4n5o6p7q8r)
```

### Checking Name Availability

To check if a name is available for registration, call the `is-name-available` function with the desired name.

```clarity
(is-name-available "example-name")
```

### Getting Name Details

To retrieve the details of a registered name, call the `get-name-details` function with the name.

```clarity
(get-name-details "example-name")
```

## Deployment

1. **Compile the Contract**: Use a Clarity-compatible toolchain to compile the contract.
2. **Deploy the Contract**: Deploy the contract to the Stacks blockchain using a compatible wallet or CLI tool.
3. **Initialize the Contract**: Call the initialization function (if any) to set up the contract.

## Testing

Before deploying the contract to the mainnet, thoroughly test it on a testnet or local development environment. Use unit tests to verify the functionality of each function and edge cases.

## Security Considerations

- **Access Control**: Ensure that only the contract owner can set the registration fee.
- **Name Validation**: Implement robust name validation to prevent invalid or malicious names.
- **Grace Period**: Handle the grace period carefully to avoid name squatting.
- **Error Handling**: Provide clear error messages for failed transactions.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please open an issue or submit a pull request for any improvements or bug fixes.

## Contact

For any questions or support, please contact the project maintainers.
