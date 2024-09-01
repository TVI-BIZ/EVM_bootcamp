# Lesson 16 - Oracles

## Review

* Frontend
* Integrating frontend with blockchain
* Coupling frontend in API
* Using off-chain data in dApps

## Oracles

* Using off-chain data in Smart Contracts
* Trust and decentralization in data sources
* Oracle patterns

### References for Oracles

<https://fravoll.github.io/solidity-patterns/oracle.html>

<https://ethereum.org/en/developers/docs/oracles/>

## Tellor

* Tellor oracle network
* Getting data
* Data sources
* Query IDs
* Tests

### References for Tellor

<https://docs.tellor.io/tellor/the-basics/readme>

<https://docs.tellor.io/tellor/getting-data/solidity-integration>

<https://docs.tellor.io/tellor/the-basics/contracts-reference#ethereum>

### Code reference

* Installing Tellor:

```bash
npm install usingtellor
```

* Contract for CallOracle.sol:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "usingtellor/contracts/UsingTellor.sol";

contract CallOracle is UsingTellor {
    constructor(address payable _tellorAddress) UsingTellor(_tellorAddress) {}

    function getBtcSpotPrice(uint256 maxTime) external view returns (uint256) {
        bytes memory _queryData = abi.encode(
            "SpotPrice",
            abi.encode("btc", "usd")
        );
        bytes32 _queryId = keccak256(_queryData);

        (bytes memory _value, uint256 _timestampRetrieved) = _getDataBefore(
            _queryId,
            block.timestamp - 20 minutes
        );
        if (_timestampRetrieved == 0) return 0;
        require(
            block.timestamp - _timestampRetrieved < maxTime,
            "Maximum time elapsed"
        );
        return abi.decode(_value, (uint256));
    }
}
```

* Script for `DeployCallOracle.ts`:

```typescript
import {
  createPublicClient,
  http,
  createWalletClient,
  formatEther,
} from "viem";
import { privateKeyToAccount } from "viem/accounts";
import { sepolia } from "viem/chains";
import {
  abi,
  bytecode,
} from "../artifacts/contracts/CallOracle.sol/CallOracle.json";
import * as dotenv from "dotenv";
dotenv.config();

const providerApiKey = process.env.ALCHEMY_API_KEY || "";
const deployerPrivateKey = process.env.PRIVATE_KEY || "";

const TELLOR_ORACLE_ADDRESS = "0xB19584Be015c04cf6CFBF6370Fe94a58b7A38830";

async function main() {
  const publicClient = createPublicClient({
    chain: sepolia,
    transport: http(`https://eth-sepolia.g.alchemy.com/v2/${providerApiKey}`),
  });
  const account = privateKeyToAccount(`0x${deployerPrivateKey}`);
  const deployer = createWalletClient({
    account,
    chain: sepolia,
    transport: http(`https://eth-sepolia.g.alchemy.com/v2/${providerApiKey}`),
  });
  console.log("Deployer address:", deployer.account.address);
  const balance = await publicClient.getBalance({
    address: deployer.account.address,
  });
  console.log(
    "Deployer balance:",
    formatEther(balance),
    deployer.chain.nativeCurrency.symbol
  );
  console.log("Deploying CallOracle contract");
  const hash = await deployer.deployContract({
    abi,
    bytecode: bytecode as `0x${string}`,
    args: [TELLOR_ORACLE_ADDRESS],
  });
  console.log("Transaction hash:", hash);
  console.log("Waiting for confirmations...");
  const receipt = await publicClient.waitForTransactionReceipt({ hash });
  console.log("CallOracle contract deployed to:", receipt.contractAddress);

  const btcSpotPrice = await publicClient.readContract({
    address: receipt.contractAddress as `0x${string}`,
    abi,
    functionName: "getBtcSpotPrice",
    args: [180 * 24 * 60 * 60],
  });

  console.log(
    `The last value for BTC Spot Price for the ${
      sepolia.name
    } network is ${formatEther(btcSpotPrice as bigint)} USD`
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
```

## Homework

* Create Github Issues with your questions about this lesson
* Read the references

## Weekend Project

This is a group activity for at least 3 students:

* Complete the projects together with your group
* Create a voting dApp to cast votes, delegate and query results on chain
* Request voting tokens to be minted using the API
* (bonus) Store a list of recent votes in the backend and display that on frontend
* (bonus) Use an oracle to fetch off-chain data
  * Use an oracle to fetch information from a data source of your preference
  * Use the data fetched to create the proposals in the constructor of the ballot

### Voting dApp integration guidelines

* Single POST method:
  * Request voting tokens from API
* Use these tokens to interact with the tokenized ballot
* All other interactions must be made directly on-chain
