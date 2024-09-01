import { Body, Controller, Get, Param, Post } from '@nestjs/common';
import { AppService } from './app.service';
import { MintTokenDto } from './dtos/mintToken.dto';
import { CastVotesDto } from './dtos/castVotes.dto';
//import { Address } from 'cluster';
import { Address } from 'viem';

@Controller()
export class AppController {
  constructor(private readonly appService: AppService) {}

  @Get('get_hello')
  getHello(): string {
    return this.appService.getHello();
  }

  @Get('contract-address')
  getContractAddress() {
    return this.appService.getContractAddress();
  }

  @Get('token-address')
  getTokenAddress() {
    return this.appService.getTokenAddress();
  }

  @Post('cast_votes')
  async castVotes(@Body() body: CastVotesDto) {
    return { result: this.appService.castVotes(body.proposal, body.amount) };
  }

  @Get('get_votes/:voter')
  async getVotes(@Param('voter') voter: Address) {
    return { result: await this.appService.getVotes(voter) };
  }

  @Post('delegate_votes/:to')
  async delegateVotes(@Param('to') to: Address) {
    return { result: this.appService.delegateVotes(to) };
  }

  @Post('mint-tokens')
  async mintTokens(@Body() body: MintTokenDto) {
    return {
      result: await this.appService.mintTokens(body.address, body.amount),
    };
  }
}
