import { Injectable, Param } from '@nestjs/common';
//import { Address } from 'cluster';
import * as tokenJson from './assets/MyToken.json';
import * as contractJson from './assets/TokenizedBallot.json';
import { sepolia } from 'viem/chains';
import { privateKeyToAccount } from 'viem/accounts';
import { createPublicClient, createWalletClient, http, Address } from 'viem';

@Injectable()
export class AppService {
  publicClient;
  walletClient;

  constructor() {
    const account = privateKeyToAccount(`0x${process.env.PRIVATE_KEY}`);
    this.publicClient = createPublicClient({
      chain: sepolia,
      transport: http(process.env.RPC_ENDPOINT_URL),
    });
    this.walletClient = createWalletClient({
      chain: sepolia,
      transport: http(process.env.RPC_ENDPOINT_URL),
      account: account,
    });
  }
  getContractAddress(): Address {
    return process.env.TOKEN_BALLOUT_ADDRESS as Address;
  }
  getTokenAddress(): Address {
    return process.env.TOKEN_ADDRESS as Address;
  }

  async delegateVotes(delegate_to: Address) {
    const delegateVote = await this.publicClient.readContract({
      address: this.getContractAddress(),
      abi: contractJson.abi,
      functionName: 'delegate',
      args: [delegate_to],
    });
    return { result: true };
  }
  async castVotes(proposal: any, amount: any) {
    const hasRole = await this.publicClient.readContract({
      address: this.getContractAddress(),
      abi: contractJson.abi,
      functionName: 'vote',
      args: [proposal, amount],
    });
    return { result: true };
  }
  async getVotes(voter: Address) {
    const final_votes = await this.publicClient.readContract({
      address: this.getContractAddress(),
      abi: contractJson.abi,
      functionName: 'getVotes',
      args: [voter],
    });
    return { final_votes };
  }
  async mintTokens(address_to: string, amount: number) {
    const minted_token = await this.publicClient.readContract({
      address: this.getTokenAddress(),
      abi: tokenJson.abi,
      functionName: 'mint',
      args: [address_to, amount],
    });
    return { result: true };
  }
  getHello(): string {
    return 'Hello World!';
  }
}
