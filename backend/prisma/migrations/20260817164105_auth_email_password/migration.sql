-- CreateEnum
CREATE TYPE "TipoCodigo" AS ENUM ('VERIFICACION_EMAIL', 'RESET_PASSWORD');

-- AlterTable
ALTER TABLE "usuarios" ADD COLUMN     "email_verificado" BOOLEAN NOT NULL DEFAULT false;

-- CreateTable
CREATE TABLE "codigos_verificacion" (
    "id" UUID NOT NULL,
    "usuario_id" UUID NOT NULL,
    "tipo" "TipoCodigo" NOT NULL,
    "codigo_hash" VARCHAR(64) NOT NULL,
    "expires_at" TIMESTAMPTZ(3) NOT NULL,
    "used_at" TIMESTAMPTZ(3),
    "intentos" INTEGER NOT NULL DEFAULT 0,
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "codigos_verificacion_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "codigos_verificacion_usuario_id_tipo_idx" ON "codigos_verificacion"("usuario_id", "tipo");

-- AddForeignKey
ALTER TABLE "codigos_verificacion" ADD CONSTRAINT "codigos_verificacion_usuario_id_fkey" FOREIGN KEY ("usuario_id") REFERENCES "usuarios"("id") ON DELETE CASCADE ON UPDATE CASCADE;
