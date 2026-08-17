#!/usr/bin/env node
/**
 * Genera el par de claves RSA (2048 bits) que firma/verifica los access tokens
 * con RS256, codificadas en base64 para que entren en una línea del .env.
 *
 *   npm run keys:generate            imprime las dos líneas por pantalla
 *   npm run keys:generate -- --write las escribe/reemplaza directamente en .env
 *
 * Preferí `--write`: así la clave privada nunca aparece en el historial de la
 * terminal. El archivo .env está en .gitignore.
 */
import { generateKeyPairSync } from 'node:crypto';
import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const escribir = process.argv.includes('--write');
const rutaEnv = resolve(dirname(fileURLToPath(import.meta.url)), '..', '.env');

const { privateKey, publicKey } = generateKeyPairSync('rsa', {
  modulusLength: 2048,
  publicKeyEncoding: { type: 'spki', format: 'pem' },
  privateKeyEncoding: { type: 'pkcs8', format: 'pem' },
});

const toBase64 = (pem) => Buffer.from(pem, 'utf8').toString('base64');
const lineas = {
  JWT_PRIVATE_KEY_BASE64: toBase64(privateKey),
  JWT_PUBLIC_KEY_BASE64: toBase64(publicKey),
};

if (!escribir) {
  console.log('\nPegá estas dos líneas en backend/.env:\n');
  for (const [clave, valor] of Object.entries(lineas)) {
    console.log(`${clave}=${valor}`);
  }
  console.log('\nLa clave privada es un secreto: no la compartas ni la subas al repo.\n');
  process.exit(0);
}

if (!existsSync(rutaEnv)) {
  console.error(`No existe ${rutaEnv}. Crealo primero (cp .env.example .env).`);
  process.exit(1);
}

let contenido = readFileSync(rutaEnv, 'utf8');

for (const [clave, valor] of Object.entries(lineas)) {
  const regex = new RegExp(`^${clave}=.*$`, 'm');
  const linea = `${clave}=${valor}`;
  contenido = regex.test(contenido)
    ? contenido.replace(regex, linea)
    : `${contenido.trimEnd()}\n${linea}\n`;
}

writeFileSync(rutaEnv, contenido, 'utf8');
console.log('Claves RSA escritas en backend/.env (JWT_PRIVATE_KEY_BASE64 / JWT_PUBLIC_KEY_BASE64).');
console.log('Si ya tenías sesiones abiertas, quedaron invalidadas: el par de claves cambió.');
