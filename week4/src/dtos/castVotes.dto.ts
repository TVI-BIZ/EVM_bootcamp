import { ApiProperty } from '@nestjs/swagger';

export class CastVotesDto {
  @ApiProperty({ type: Number, required: true, default: 1 })
  proposal: number;
  @ApiProperty({ type: Number, required: true, default: 1 })
  amount: number;
}
