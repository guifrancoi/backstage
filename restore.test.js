'use strict';

const fs = require('node:fs');
const path = require('node:path');
const test = require('node:test');
const assert = require('node:assert/strict');

// Aponta o restore para uma pasta de fixtures isolada, não a Banco/ real.
const FIXTURES_DIR = path.join(__dirname, '.restore-test-fixtures');
process.env.BACKSTAGE_BACKUP_DIR = FIXTURES_DIR;

const { restaurarColecao, inicializarFirestore } = require('./restore.js');

let db;
let Timestamp;

test.before(async () => {
  fs.mkdirSync(FIXTURES_DIR, { recursive: true });
  fs.writeFileSync(
    path.join(FIXTURES_DIR, 'usuarios.json'),
    JSON.stringify([
      {
        id: 'u1',
        nome: 'Guilherme',
        email: 'g@a.com',
        updatedAt: { _seconds: 1780848782, _nanoseconds: 59000000 },
      },
    ]),
  );

  ({ db, Timestamp } = inicializarFirestore());
});

test.after(() => {
  fs.rmSync(FIXTURES_DIR, { recursive: true, force: true });
});

const USUARIOS = { arquivo: 'usuarios', colecao: 'usuarios' };

test('restaurarColecao grava o documento com o id do JSON', async () => {
  await restaurarColecao(db, Timestamp, USUARIOS, { dryRun: false });

  const doc = await db.collection('usuarios').doc('u1').get();
  assert.equal(doc.exists, true);
  assert.equal(doc.data().nome, 'Guilherme');
});

test('reconstrói Timestamp em vez de deixar {_seconds,_nanoseconds} cru', async () => {
  await restaurarColecao(db, Timestamp, USUARIOS, { dryRun: false });

  const doc = await db.collection('usuarios').doc('u1').get();
  const updatedAt = doc.data().updatedAt;

  assert.ok(updatedAt instanceof Timestamp, 'updatedAt deveria ser um Timestamp');
  assert.equal(typeof updatedAt.toDate, 'function');
  assert.equal(updatedAt.seconds, 1780848782);
});

test('rodar duas vezes é idempotente (merge, sem duplicar)', async () => {
  await restaurarColecao(db, Timestamp, USUARIOS, { dryRun: false });
  await restaurarColecao(db, Timestamp, USUARIOS, { dryRun: false });

  const snapshot = await db.collection('usuarios').get();
  assert.equal(snapshot.docs.length, 1);
});

test('dryRun não grava nada', async () => {
  await db.collection('usuarios').doc('u1').delete();

  const total = await restaurarColecao(db, Timestamp, USUARIOS, { dryRun: true });

  assert.equal(total, 1);
  const doc = await db.collection('usuarios').doc('u1').get();
  assert.equal(doc.exists, false);
});

test('coleção sem arquivo correspondente é ignorada sem erro', async () => {
  const total = await restaurarColecao(
    db,
    Timestamp,
    { arquivo: 'colecao_inexistente', colecao: 'colecao_inexistente' },
    { dryRun: false },
  );

  assert.equal(total, 0);
});

test('arquivo musicos.json restaura em perfis_musicos (unificação)', async () => {
  fs.writeFileSync(
    path.join(FIXTURES_DIR, 'musicos.json'),
    JSON.stringify([{ id: '1', nomeArtistico: 'Banda Catálogo' }]),
  );

  await restaurarColecao(
    db,
    Timestamp,
    { arquivo: 'musicos', colecao: 'perfis_musicos' },
    { dryRun: false },
  );

  const doc = await db.collection('perfis_musicos').doc('1').get();
  assert.equal(doc.exists, true);
  assert.equal(doc.data().nomeArtistico, 'Banda Catálogo');
  const naoDeveExistir = await db.collection('musicos').doc('1').get();
  assert.equal(naoDeveExistir.exists, false);
});
