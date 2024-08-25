import { viem } from "hardhat";
import { parseEther, toHex } from "viem";

const PROPOSALS = ["Proposal 1", "Proposal 2", "Proposal 3"];
const MINT_VALUE = parseEther("10");
const TRANSFER_VALUE = parseEther("1");

async function main() {
  const customTokenContract = await viem.deployContract("MyToken");

  const publicClient = await viem.getPublicClient();
  const [deployer, acc1, acc2] = await viem.getWalletClients();
  const ballotContract = await viem.deployContract("TokenizedBallot", [
    PROPOSALS.map((prop) => toHex(prop, { size: 32 })),
    customTokenContract.address,
  ]);
  console.log(
    `TokenizedBallot contract deployed at ${ballotContract.address}\n`
  );
  //const customTokenContract = await viem.deployContract("MyToken");
  console.log(
    `Token contract deployed at ${await ballotContract.read.tokenContract()}\n`
  );

  const mintTx = await customTokenContract.write.mint([
    deployer.account.address,
    MINT_VALUE,
  ]);
  await publicClient.waitForTransactionReceipt({ hash: mintTx });
  console.log(
    `Minted ${MINT_VALUE.toString()} decimal units to account ${
      deployer.account.address
    }\n`
  );
  // Part1. Give vote tokens. Here we thansfer TRANSFER_VALUE from deployer to acc1
  // also we check the balance of deployer and his vote power.
  const delegateTx = await customTokenContract.write.delegate(
    [deployer.account.address],
    {
      account: deployer.account,
    }
  );
  await publicClient.waitForTransactionReceipt({ hash: delegateTx });

  const transferTx = await customTokenContract.write.transfer(
    [acc1.account.address, TRANSFER_VALUE],
    {
      account: deployer.account,
    }
  );
  await publicClient.waitForTransactionReceipt({ hash: transferTx });

  const deployerVotesAfterTransfer = await ballotContract.read.getVotes([
    deployer.account.address,
  ]);
  const deployerBalanceAfterTransfer = await customTokenContract.read.balanceOf(
    [deployer.account.address]
  );
  //

  // console.log(
  //   `Account ${
  //     deployer.account.address
  //   } has ${deployerBalanceAfterTransfer.toString()} decimal units of MyToken after transferring\n
  //   and balande is ${}`
  // );
  console.log(
    `Account ${
      deployer.account.address
    } has ${deployerVotesAfterTransfer.toString()} units of voting power after transferring and balance is ${deployerBalanceAfterTransfer.toString()}`
  );

  //   const votes2AfterTransfer = await contract.read.getVotes([
  //     acc2.account.address,
  //   ]);
  //   console.log(
  //     `Account ${
  //       acc2.account.address
  //     } has ${votes2AfterTransfer.toString()} units of voting power after receiving a transfer\n`
  //   );
  //   //6//
  //   const lastBlockNumber = await publicClient.getBlockNumber();
  //   for (let index = lastBlockNumber - 1n; index > 0n; index--) {
  //     const pastVotes = await contract.read.getPastVotes([
  //       acc1.account.address,
  //       index,
  //     ]);
  //     console.log(
  //       `Account ${
  //         acc1.account.address
  //       } had ${pastVotes.toString()} units of voting power at block ${index}\n`
  //     );
  //   }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
