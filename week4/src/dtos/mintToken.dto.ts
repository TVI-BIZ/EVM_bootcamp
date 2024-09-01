import { ApiProperty } from '@nestjs/swagger';
import { Address } from 'viem';

export class MintTokenDto {
  @ApiProperty({ type: String, required: true, default: '0x12345' })
  address: string;
  @ApiProperty({ type: Number, required: true, default: 10 })
  amount: number;
}
