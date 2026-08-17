import { Type } from 'class-transformer';
import { IsIn, IsInt, IsOptional, IsString, Max, MaxLength, Min } from 'class-validator';

export class ListarClientesDto {
  /** Búsqueda parcial por nombre o teléfono, sin distinguir mayúsculas. */
  @IsOptional()
  @IsString()
  @MaxLength(120)
  buscar?: string;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  pagina = 1;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(100)
  limite = 20;

  @IsOptional()
  @IsIn(['nombre', 'saldoActual', 'createdAt'])
  ordenarPor: 'nombre' | 'saldoActual' | 'createdAt' = 'nombre';

  @IsOptional()
  @IsIn(['asc', 'desc'])
  orden: 'asc' | 'desc' = 'asc';
}

export interface PaginaDto<T> {
  datos: T[];
  total: number;
  pagina: number;
  limite: number;
  totalPaginas: number;
}
