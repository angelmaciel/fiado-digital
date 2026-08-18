import { Type, plainToInstance } from 'class-transformer';
import {
  IsEnum,
  IsIn,
  IsInt,
  IsOptional,
  IsString,
  Max,
  Min,
  validateSync,
} from 'class-validator';

export enum Entorno {
  Development = 'development',
  Test = 'test',
  Production = 'production',
}

/**
 * Contrato de las variables de entorno. Si falta alguna obligatoria, la app
 * falla al arrancar en vez de romperse recién cuando alguien intenta loguearse.
 */
class VariablesDeEntorno {
  @IsEnum(Entorno)
  NODE_ENV: Entorno = Entorno.Development;

  // Todo lo que viene del entorno es string. `enableImplicitConversion` no
  // alcanza acá: sin anotación de tipo, TypeScript emite `design:type = Object`
  // y class-transformer no sabe a qué convertir. Por eso el @Type() explícito.
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(65535)
  PORT: number = 3000;

  @IsOptional()
  @IsString()
  CORS_ORIGINS?: string;

  @IsString()
  DATABASE_URL: string;

  @IsOptional()
  @IsString()
  DIRECT_URL?: string;

  @IsString()
  JWT_PRIVATE_KEY_BASE64: string;

  @IsString()
  JWT_PUBLIC_KEY_BASE64: string;

  @IsString()
  JWT_ISSUER: string;

  @IsString()
  JWT_AUDIENCE: string;

  @IsString()
  JWT_ACCESS_TOKEN_TTL: string = '15m';

  @Type(() => Number)
  @IsInt()
  @Min(1)
  JWT_REFRESH_TOKEN_TTL_DAYS: number = 30;

  @IsString()
  GOOGLE_CLIENT_ID: string;

  @IsString()
  GOOGLE_CLIENT_SECRET: string;

  @IsString()
  GOOGLE_CALLBACK_URL: string;

  @IsOptional()
  @IsString()
  GOOGLE_ADDITIONAL_CLIENT_IDS?: string;

  @IsOptional()
  @IsString()
  OAUTH_SUCCESS_REDIRECT_URL?: string;

  // --- Envio de correo -------------------------------------------------------
  // 'consola' (por defecto) imprime el codigo en el log; 'smtp' lo manda.
  // Las variables SMTP_* solo hacen falta con 'smtp', y el servicio las exige
  // con getOrThrow al construirse: si faltan, el servidor no arranca en vez de
  // fallar recien cuando alguien intenta registrarse.
  @IsOptional()
  @IsIn(['consola', 'smtp'])
  EMAIL_PROVIDER?: string;

  @IsOptional()
  @IsString()
  SMTP_HOST?: string;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(65535)
  SMTP_PORT?: number;

  @IsOptional()
  @IsString()
  SMTP_USER?: string;

  @IsOptional()
  @IsString()
  SMTP_PASSWORD?: string;

  @IsOptional()
  @IsString()
  EMAIL_REMITENTE?: string;
}

export function validarEntorno(config: Record<string, unknown>): VariablesDeEntorno {
  const validado = plainToInstance(VariablesDeEntorno, config, {
    enableImplicitConversion: true,
    exposeDefaultValues: true,
  });

  const errores = validateSync(validado, { skipMissingProperties: false });

  if (errores.length > 0) {
    const detalle = errores
      .map((e) => `  - ${e.property}: ${Object.values(e.constraints ?? {}).join(', ')}`)
      .join('\n');
    throw new Error(
      `Configuración de entorno inválida. Revisá tu archivo .env (usá .env.example como guía):\n${detalle}`,
    );
  }

  return validado;
}
