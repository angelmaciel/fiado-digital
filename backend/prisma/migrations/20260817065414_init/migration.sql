-- CreateEnum
CREATE TYPE "MetodoAuth" AS ENUM ('GOOGLE', 'EMAIL_PASSWORD');

-- CreateEnum
CREATE TYPE "RolUsuario" AS ENUM ('DUENO', 'EMPLEADO');

-- CreateTable
CREATE TABLE "usuarios" (
    "id" UUID NOT NULL,
    "nombre" VARCHAR(120) NOT NULL,
    "email" VARCHAR(180) NOT NULL,
    "metodo_auth" "MetodoAuth" NOT NULL,
    "google_uid" VARCHAR(64),
    "password_hash" TEXT,
    "rol" "RolUsuario" NOT NULL DEFAULT 'DUENO',
    "despensa_id" UUID,
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(3) NOT NULL,

    CONSTRAINT "usuarios_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "despensas" (
    "id" UUID NOT NULL,
    "nombre_comercial" VARCHAR(160) NOT NULL,
    "propietario_id" UUID NOT NULL,
    "dias_mora_config" INTEGER NOT NULL DEFAULT 30,
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(3) NOT NULL,

    CONSTRAINT "despensas_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "clientes" (
    "id" UUID NOT NULL,
    "despensa_id" UUID NOT NULL,
    "nombre" VARCHAR(120) NOT NULL,
    "telefono" VARCHAR(30),
    "limite_credito" INTEGER,
    "saldo_actual" INTEGER NOT NULL DEFAULT 0,
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(3) NOT NULL,

    CONSTRAINT "clientes_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "refresh_tokens" (
    "id" UUID NOT NULL,
    "usuario_id" UUID NOT NULL,
    "token_hash" VARCHAR(64) NOT NULL,
    "expires_at" TIMESTAMPTZ(3) NOT NULL,
    "revoked_at" TIMESTAMPTZ(3),
    "user_agent" VARCHAR(255),
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "refresh_tokens_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "usuarios_email_key" ON "usuarios"("email");

-- CreateIndex
CREATE UNIQUE INDEX "usuarios_google_uid_key" ON "usuarios"("google_uid");

-- CreateIndex
CREATE INDEX "usuarios_despensa_id_idx" ON "usuarios"("despensa_id");

-- CreateIndex
CREATE INDEX "despensas_propietario_id_idx" ON "despensas"("propietario_id");

-- CreateIndex
CREATE INDEX "clientes_despensa_id_nombre_idx" ON "clientes"("despensa_id", "nombre");

-- CreateIndex
CREATE UNIQUE INDEX "refresh_tokens_token_hash_key" ON "refresh_tokens"("token_hash");

-- CreateIndex
CREATE INDEX "refresh_tokens_usuario_id_idx" ON "refresh_tokens"("usuario_id");

-- AddForeignKey
ALTER TABLE "usuarios" ADD CONSTRAINT "usuarios_despensa_id_fkey" FOREIGN KEY ("despensa_id") REFERENCES "despensas"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "despensas" ADD CONSTRAINT "despensas_propietario_id_fkey" FOREIGN KEY ("propietario_id") REFERENCES "usuarios"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "clientes" ADD CONSTRAINT "clientes_despensa_id_fkey" FOREIGN KEY ("despensa_id") REFERENCES "despensas"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "refresh_tokens" ADD CONSTRAINT "refresh_tokens_usuario_id_fkey" FOREIGN KEY ("usuario_id") REFERENCES "usuarios"("id") ON DELETE CASCADE ON UPDATE CASCADE;
