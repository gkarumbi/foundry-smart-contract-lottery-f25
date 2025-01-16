## Foundry Smart Contract Lottery

**This is a smart contract lottery that make use of Chainlink VRF to pick winners and Chainlink Automation to automatically intiate a lottery run after a certain amount of time has passed.**

Foundry consists of:

-   **src/Raffle.sol**: Logic for the main raffle contract
-   **test/unit/Raffle.t.sol**: Unit tests for the raffle contract.
-   **script/DeployRaffle.s.sol**: To programmatically deploy our raffle contract to the Sepolia testnet.
-   

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ make build
```

### Test

```shell
$ make test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ make deploy-sepolia
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
