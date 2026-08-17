import { Module } from '@nestjs/common';
import { DespensasController } from './despensas.controller';
import { DespensasService } from './despensas.service';

@Module({
  controllers: [DespensasController],
  providers: [DespensasService],
  exports: [DespensasService],
})
export class DespensasModule {}
