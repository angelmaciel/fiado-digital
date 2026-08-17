import { Type } from 'class-transformer';
import { IsInt, IsOptional, IsString, Length, Max, Min } from 'class-validator';

export class CrearDespensaDto {
  @IsString()
  @Length(2, 160, { message: 'El nombre comercial debe tener entre 2 y 160 caracteres' })
  nombreComercial: string;

  /** Días sin pagar tras los cuales un cliente entra en mora (HU-06). */
  @IsOptional()
  @Type(() => Number)
  @IsInt({ message: 'Los días de mora deben ser un número entero' })
  @Min(1)
  @Max(365)
  diasMoraConfig?: number;
}
