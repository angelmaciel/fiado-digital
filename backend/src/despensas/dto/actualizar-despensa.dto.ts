import { Type } from 'class-transformer';
import { IsInt, IsOptional, IsString, Length, Max, Min } from 'class-validator';

export class ActualizarDespensaDto {
  @IsOptional()
  @IsString()
  @Length(2, 160)
  nombreComercial?: string;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(365)
  diasMoraConfig?: number;
}
