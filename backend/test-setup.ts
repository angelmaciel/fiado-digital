import { Logger } from '@nestjs/common';

/**
 * Los servicios registran lo que hacen, y está bien que lo hagan. Pero en una
 * corrida de tests esos mensajes tapan los fallos reales, así que se apagan.
 */
beforeAll(() => {
  jest.spyOn(Logger.prototype, 'log').mockImplementation(() => undefined);
  jest.spyOn(Logger.prototype, 'warn').mockImplementation(() => undefined);
  jest.spyOn(Logger.prototype, 'error').mockImplementation(() => undefined);
});
