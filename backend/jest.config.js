/**
 * Pruebas unitarias del backend.
 *
 * Se testea la lógica de negocio con Prisma simulado, no contra la base real:
 * así corren en la CI sin necesitar PostgreSQL, tardan segundos y no dependen
 * del estado de los datos. Lo que exige base de verdad -las migraciones, las
 * restricciones de unicidad- se verifica aparte.
 */
module.exports = {
  moduleFileExtensions: ['js', 'json', 'ts'],
  rootDir: 'src',
  testRegex: '.*\.spec\.ts$',
  transform: { '^.+\.ts$': 'ts-jest' },
  // Silencia los logs de Nest: en una corrida de tests solo estorban.
  setupFilesAfterEnv: ['<rootDir>/../test-setup.ts'],
  collectCoverageFrom: ['**/*.(t|j)s'],
  coverageDirectory: '../coverage',
  testEnvironment: 'node',
};
