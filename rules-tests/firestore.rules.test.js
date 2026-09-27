'use strict';

const fs = require('node:fs');
const path = require('node:path');
const test = require('node:test');
const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require('@firebase/rules-unit-testing');
const { doc, getDoc, setDoc, updateDoc, deleteDoc } = require('firebase/firestore');

const [emulatorHost, emulatorPort] = (
  process.env.FIRESTORE_EMULATOR_HOST || 'localhost:8080'
).split(':');

let testEnv;

test.before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'backstage-rules-test',
    firestore: {
      host: emulatorHost,
      port: Number(emulatorPort),
      rules: fs.readFileSync(
        path.join(__dirname, '..', 'firestore.rules'),
        'utf8',
      ),
    },
  });
});

test.after(async () => {
  await testEnv.cleanup();
});

test.beforeEach(async () => {
  await testEnv.clearFirestore();
});

function asUser(uid) {
  return testEnv.authenticatedContext(uid).firestore();
}

function asAnon() {
  return testEnv.unauthenticatedContext().firestore();
}

async function seed(setupFn) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setupFn(context.firestore());
  });
}

// --- usuarios ------------------------------------------------------------

test('usuarios: dono cria o próprio documento', async () => {
  const db = asUser('u1');
  await assertSucceeds(
    setDoc(doc(db, 'usuarios/u1'), { nome: 'Guilherme', email: 'g@a.com' }),
  );
});

test('usuarios: não-dono não lê nem escreve o documento de outro uid', async () => {
  await seed((db) => setDoc(doc(db, 'usuarios/u1'), { nome: 'Guilherme' }));

  const db = asUser('u2');
  await assertFails(getDoc(doc(db, 'usuarios/u1')));
  await assertFails(setDoc(doc(db, 'usuarios/u1'), { nome: 'Invasor' }));
});

test('usuarios: usuário anônimo não lê nem escreve', async () => {
  await seed((db) => setDoc(doc(db, 'usuarios/u1'), { nome: 'Guilherme' }));

  const db = asAnon();
  await assertFails(getDoc(doc(db, 'usuarios/u1')));
  await assertFails(setDoc(doc(db, 'usuarios/u1'), { nome: 'X' }));
});

test('usuarios: dono define tipoUsuario pela primeira vez', async () => {
  await seed((db) => setDoc(doc(db, 'usuarios/u1'), { nome: 'Guilherme' }));

  const db = asUser('u1');
  await assertSucceeds(
    updateDoc(doc(db, 'usuarios/u1'), { tipoUsuario: 'musico' }),
  );
});

test('usuarios: dono não pode trocar tipoUsuario depois de definido', async () => {
  await seed((db) =>
    setDoc(doc(db, 'usuarios/u1'), { nome: 'Guilherme', tipoUsuario: 'musico' }),
  );

  const db = asUser('u1');
  await assertFails(
    updateDoc(doc(db, 'usuarios/u1'), { tipoUsuario: 'casaShow' }),
  );
});

test('usuarios: dono edita outros campos sem tocar em tipoUsuario', async () => {
  await seed((db) =>
    setDoc(doc(db, 'usuarios/u1'), { nome: 'Guilherme', tipoUsuario: 'musico' }),
  );

  const db = asUser('u1');
  await assertSucceeds(
    setDoc(doc(db, 'usuarios/u1'), { nome: 'Guilherme Franco' }, { merge: true }),
  );
});

// --- perfis_musicos --------------------------------------------------------

test('perfis_musicos: qualquer autenticado lê o perfil de outro uid', async () => {
  await seed((db) =>
    setDoc(doc(db, 'perfis_musicos/u1'), { nomeArtistico: 'Banda X' }),
  );

  const db = asUser('u2');
  await assertSucceeds(getDoc(doc(db, 'perfis_musicos/u1')));
});

test('perfis_musicos: anônimo não lê', async () => {
  await seed((db) =>
    setDoc(doc(db, 'perfis_musicos/u1'), { nomeArtistico: 'Banda X' }),
  );

  await assertFails(getDoc(doc(asAnon(), 'perfis_musicos/u1')));
});

test('perfis_musicos: só o dono escreve o próprio perfil', async () => {
  const dono = asUser('u1');
  await assertSucceeds(
    setDoc(doc(dono, 'perfis_musicos/u1'), { nomeArtistico: 'Banda X' }),
  );

  const outro = asUser('u2');
  await assertFails(
    setDoc(doc(outro, 'perfis_musicos/u1'), { nomeArtistico: 'Invasor' }),
  );
});

// --- estabelecimentos -------------------------------------------------------

test('estabelecimentos: só o dono escreve o próprio perfil', async () => {
  const dono = asUser('e1');
  await assertSucceeds(
    setDoc(doc(dono, 'estabelecimentos/e1'), { nome: 'Bar Central' }),
  );

  const outro = asUser('e2');
  await assertFails(
    setDoc(doc(outro, 'estabelecimentos/e1'), { nome: 'Invasor' }),
  );
});

test('estabelecimentos: qualquer autenticado lê', async () => {
  await seed((db) => setDoc(doc(db, 'estabelecimentos/e1'), { nome: 'Bar Central' }));

  await assertSucceeds(getDoc(doc(asUser('u2'), 'estabelecimentos/e1')));
});

// --- oportunidades -----------------------------------------------------------

test('oportunidades: criar exige donoId == uid autenticado', async () => {
  const db = asUser('e1');
  await assertSucceeds(
    setDoc(doc(db, 'oportunidades/o1'), { titulo: 'Show', donoId: 'e1' }),
  );
});

test('oportunidades: não cria com donoId de outro usuário', async () => {
  const db = asUser('e1');
  await assertFails(
    setDoc(doc(db, 'oportunidades/o1'), { titulo: 'Show', donoId: 'e2' }),
  );
});

test('oportunidades: qualquer autenticado lê o catálogo', async () => {
  await seed((db) =>
    setDoc(doc(db, 'oportunidades/o1'), { titulo: 'Show', donoId: 'e1' }),
  );

  await assertSucceeds(getDoc(doc(asUser('u2'), 'oportunidades/o1')));
});

test('oportunidades: só o dono atualiza ou remove', async () => {
  await seed((db) =>
    setDoc(doc(db, 'oportunidades/o1'), { titulo: 'Show', donoId: 'e1' }),
  );

  const outro = asUser('e2');
  await assertFails(updateDoc(doc(outro, 'oportunidades/o1'), { titulo: 'Hackeado' }));
  await assertFails(deleteDoc(doc(outro, 'oportunidades/o1')));

  const dono = asUser('e1');
  await assertSucceeds(updateDoc(doc(dono, 'oportunidades/o1'), { titulo: 'Novo título' }));
  await assertSucceeds(deleteDoc(doc(dono, 'oportunidades/o1')));
});

// --- smoke tests: coleções que não deveriam ter mudado de comportamento ----

test('conversas: autenticado lê e escreve; anônimo não', async () => {
  const db = asUser('u1');
  await assertSucceeds(setDoc(doc(db, 'conversas/c1'), { nomeContato: 'Bar Central' }));
  await assertSucceeds(getDoc(doc(db, 'conversas/c1')));
  await assertFails(getDoc(doc(asAnon(), 'conversas/c1')));
});

test('interesses_oportunidades: só o próprio usuarioId', async () => {
  const db = asUser('u1');
  await assertSucceeds(
    setDoc(doc(db, 'interesses_oportunidades/u1_o1'), {
      oportunidadeId: 'o1',
      usuarioId: 'u1',
    }),
  );
  await assertFails(
    setDoc(doc(db, 'interesses_oportunidades/u2_o1'), {
      oportunidadeId: 'o1',
      usuarioId: 'u2',
    }),
  );
});

test('disponibilidades: só o próprio usuarioId', async () => {
  const db = asUser('u1');
  await assertSucceeds(
    setDoc(doc(db, 'disponibilidades/u1_2026-05-10'), {
      usuarioId: 'u1',
      disponivel: true,
    }),
  );
  await assertFails(
    setDoc(doc(db, 'disponibilidades/u2_2026-05-10'), {
      usuarioId: 'u2',
      disponivel: true,
    }),
  );
});
