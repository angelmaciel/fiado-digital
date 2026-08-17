-- CreateEnum
CREATE TYPE "TipoMovimiento" AS ENUM ('FIADO', 'PAGO', 'AJUSTE');

-- CreateTable
CREATE TABLE "movimientos" (
    "id" UUID NOT NULL,
    "cliente_id" UUID NOT NULL,
    "usuario_id" UUID NOT NULL,
    "tipo" "TipoMovimiento" NOT NULL,
    "monto" INTEGER NOT NULL,
    "detalle" VARCHAR(255),
    "movimiento_reversa_de" UUID,
    "sincronizado" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "movimientos_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "movimientos_movimiento_reversa_de_key" ON "movimientos"("movimiento_reversa_de");

-- CreateIndex
CREATE INDEX "movimientos_cliente_id_created_at_idx" ON "movimientos"("cliente_id", "created_at");

-- AddForeignKey
ALTER TABLE "movimientos" ADD CONSTRAINT "movimientos_cliente_id_fkey" FOREIGN KEY ("cliente_id") REFERENCES "clientes"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "movimientos" ADD CONSTRAINT "movimientos_usuario_id_fkey" FOREIGN KEY ("usuario_id") REFERENCES "usuarios"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "movimientos" ADD CONSTRAINT "movimientos_movimiento_reversa_de_fkey" FOREIGN KEY ("movimiento_reversa_de") REFERENCES "movimientos"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
