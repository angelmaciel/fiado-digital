-- CreateEnum
CREATE TYPE "TipoMetodoPago" AS ENUM ('TRANSFERENCIA', 'ALIAS', 'BILLETERA_DIGITAL');

-- CreateTable
CREATE TABLE "metodos_pago" (
    "id" UUID NOT NULL,
    "despensa_id" UUID NOT NULL,
    "tipo" "TipoMetodoPago" NOT NULL,
    "banco" VARCHAR(120),
    "titular" VARCHAR(160) NOT NULL,
    "alias" VARCHAR(120),
    "numero_cuenta" VARCHAR(60),
    "nota" VARCHAR(255),
    "es_principal" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(3) NOT NULL,

    CONSTRAINT "metodos_pago_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "metodos_pago_despensa_id_idx" ON "metodos_pago"("despensa_id");

-- AddForeignKey
ALTER TABLE "metodos_pago" ADD CONSTRAINT "metodos_pago_despensa_id_fkey" FOREIGN KEY ("despensa_id") REFERENCES "despensas"("id") ON DELETE CASCADE ON UPDATE CASCADE;
