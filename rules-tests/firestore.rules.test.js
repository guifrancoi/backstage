'use strict';

const fs = require('node:fs');
const path = require('node:path');
const test = require('node:test');
const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require('@firebase/rules-unit-testing');
const {
  doc,
  getDoc,
  setDoc,
  updateDoc,
  deleteDoc,
  writeBatch,
  collection,
  query,
  where,
  getDocs,
} = require('firebase/firestore');

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

/** Usuário com a custom claim `admin: true` no token (definir-admin.js). */
function asAdmin(uid = 'adm') {
  return testEnv.authenticatedContext(uid, { admin: true }).firestore();
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

// --- interesses ----------------------------------------------------------------
// m1 = músico, e1 = dono de estabelecimento (dono de o1), e2 = outro dono, x = terceiro.

async function seedPapeis() {
  await seed(async (db) => {
    await setDoc(doc(db, 'usuarios/m1'), { tipoUsuario: 'musico' });
    await setDoc(doc(db, 'usuarios/m2'), { tipoUsuario: 'musico' });
    await setDoc(doc(db, 'usuarios/e1'), { tipoUsuario: 'casaShow' });
    await setDoc(doc(db, 'usuarios/e2'), { tipoUsuario: 'casaShow' });
    await setDoc(doc(db, 'oportunidades/o1'), { titulo: 'Show', donoId: 'e1' });
  });
}

const candidatura = {
  tipo: 'candidatura',
  remetenteId: 'm1',
  destinatarioId: 'e1',
  musicoId: 'm1',
  oportunidadeId: 'o1',
  status: 'pendente',
};

const convite = {
  tipo: 'convite',
  remetenteId: 'e1',
  destinatarioId: 'm1',
  musicoId: 'm1',
  status: 'pendente',
};

test('interesses: músico se candidata a oportunidade de outro dono', async () => {
  await seedPapeis();
  await assertSucceeds(
    setDoc(doc(asUser('m1'), 'interesses/m1_op_o1'), candidatura),
  );
});

test('interesses: dono não pode se candidatar (papel errado)', async () => {
  await seedPapeis();
  await assertFails(
    setDoc(doc(asUser('e2'), 'interesses/e2_op_o1'), {
      ...candidatura,
      remetenteId: 'e2',
      musicoId: 'e2',
    }),
  );
});

test('interesses: candidatura com destinatário que não é o dono da oportunidade falha', async () => {
  await seedPapeis();
  await assertFails(
    setDoc(doc(asUser('m1'), 'interesses/m1_op_o1'), {
      ...candidatura,
      destinatarioId: 'e2',
    }),
  );
});

test('interesses: não cria em nome de outro nem já respondido', async () => {
  await seedPapeis();
  await assertFails(
    setDoc(doc(asUser('m2'), 'interesses/m1_op_o1'), candidatura),
  );
  await assertFails(
    setDoc(doc(asUser('m1'), 'interesses/m1_op_o1'), {
      ...candidatura,
      status: 'aceito',
    }),
  );
});

test('interesses: dono convida músico; músico não pode convidar', async () => {
  await seedPapeis();
  await assertSucceeds(setDoc(doc(asUser('e1'), 'interesses/e1_mu_m1'), convite));
  await assertFails(
    setDoc(doc(asUser('m2'), 'interesses/m2_mu_m1'), {
      ...convite,
      remetenteId: 'm2',
    }),
  );
});

test('interesses: convite para perfil sem conta de músico (catálogo) falha', async () => {
  await seedPapeis();
  await assertFails(
    setDoc(doc(asUser('e1'), 'interesses/e1_mu_1'), {
      ...convite,
      destinatarioId: '1',
      musicoId: '1',
    }),
  );
  // Nem para outro dono.
  await assertFails(
    setDoc(doc(asUser('e1'), 'interesses/e1_mu_e2'), {
      ...convite,
      destinatarioId: 'e2',
      musicoId: 'e2',
    }),
  );
});

test('interesses: convite citando oportunidade de outro dono falha', async () => {
  await seedPapeis();
  await assertFails(
    setDoc(doc(asUser('e2'), 'interesses/e2_mu_m1_o1'), {
      ...convite,
      remetenteId: 'e2',
      oportunidadeId: 'o1',
    }),
  );
});

test('interesses: só remetente e destinatário leem', async () => {
  await seedPapeis();
  await seed((db) => setDoc(doc(db, 'interesses/m1_op_o1'), candidatura));

  await assertSucceeds(getDoc(doc(asUser('m1'), 'interesses/m1_op_o1')));
  await assertSucceeds(getDoc(doc(asUser('e1'), 'interesses/m1_op_o1')));
  await assertFails(getDoc(doc(asUser('e2'), 'interesses/m1_op_o1')));
});

test('interesses: consultas por remetente/destinatário (como o app faz) passam', async () => {
  await seedPapeis();
  await seed((db) => setDoc(doc(db, 'interesses/m1_op_o1'), candidatura));

  const m1 = asUser('m1');
  const e1 = asUser('e1');
  await assertSucceeds(
    getDocs(query(collection(m1, 'interesses'), where('remetenteId', '==', 'm1'))),
  );
  await assertSucceeds(
    getDocs(query(collection(e1, 'interesses'), where('destinatarioId', '==', 'e1'))),
  );
  await assertFails(getDocs(collection(e1, 'interesses')));
});

test('conversas: consulta por participante (como o app faz) passa', async () => {
  await seed((db) =>
    setDoc(doc(db, 'conversas/c1'), { participantes: ['m1', 'e1'], mensagens: [] }),
  );

  const m1 = asUser('m1');
  await assertSucceeds(
    getDocs(
      query(collection(m1, 'conversas'), where('participantes', 'array-contains', 'm1')),
    ),
  );
  await assertFails(getDocs(collection(m1, 'conversas')));
});

test('interesses: só o destinatário responde, uma vez, e só a resposta', async () => {
  await seedPapeis();
  await seed((db) => setDoc(doc(db, 'interesses/m1_op_o1'), candidatura));

  await assertFails(
    updateDoc(doc(asUser('m1'), 'interesses/m1_op_o1'), { status: 'aceito' }),
  );
  await assertFails(
    updateDoc(doc(asUser('e1'), 'interesses/m1_op_o1'), {
      status: 'recusado',
      destinatarioId: 'e2',
    }),
  );
  await assertSucceeds(
    updateDoc(doc(asUser('e1'), 'interesses/m1_op_o1'), { status: 'recusado' }),
  );
  await assertFails(
    updateDoc(doc(asUser('e1'), 'interesses/m1_op_o1'), { status: 'aceito' }),
  );
});

test('interesses: só o remetente cancela, e só enquanto pendente', async () => {
  await seedPapeis();
  await seed(async (db) => {
    await setDoc(doc(db, 'interesses/m1_op_o1'), candidatura);
    await setDoc(doc(db, 'interesses/e1_mu_m1'), { ...convite, status: 'aceito' });
  });

  await assertFails(deleteDoc(doc(asUser('e1'), 'interesses/m1_op_o1')));
  await assertSucceeds(deleteDoc(doc(asUser('m1'), 'interesses/m1_op_o1')));
  await assertFails(deleteDoc(doc(asUser('e1'), 'interesses/e1_mu_m1')));
});

// --- conversas -------------------------------------------------------------------

test('conversas: aceitar cria a conversa no mesmo batch', async () => {
  await seedPapeis();
  await seed((db) => setDoc(doc(db, 'interesses/m1_op_o1'), candidatura));

  const db = asUser('e1');
  const batch = writeBatch(db);
  batch.set(doc(db, 'conversas/m1_op_o1'), {
    participantes: ['m1', 'e1'],
    nomes: { m1: 'Músico', e1: 'Bar' },
    mensagens: [],
  });
  batch.update(doc(db, 'interesses/m1_op_o1'), {
    status: 'aceito',
    conversaId: 'm1_op_o1',
  });
  await assertSucceeds(batch.commit());
});

test('conversas: não cria sem interesse aceito', async () => {
  await seedPapeis();
  await seed((db) => setDoc(doc(db, 'interesses/m1_op_o1'), candidatura));

  await assertFails(
    setDoc(doc(asUser('e1'), 'conversas/m1_op_o1'), {
      participantes: ['m1', 'e1'],
      nomes: {},
      mensagens: [],
    }),
  );
  await assertFails(
    setDoc(doc(asUser('e2'), 'conversas/qualquer'), {
      participantes: ['m1', 'e2'],
      nomes: {},
      mensagens: [],
    }),
  );
});

test('conversas: só participantes leem e escrevem; participantes não mudam', async () => {
  await seed((db) =>
    setDoc(doc(db, 'conversas/c1'), {
      participantes: ['m1', 'e1'],
      nomes: {},
      mensagens: [],
    }),
  );

  await assertSucceeds(getDoc(doc(asUser('m1'), 'conversas/c1')));
  await assertFails(getDoc(doc(asUser('e2'), 'conversas/c1')));
  await assertFails(getDoc(doc(asAnon(), 'conversas/c1')));
  await assertSucceeds(
    updateDoc(doc(asUser('m1'), 'conversas/c1'), { mensagens: [{ texto: 'oi' }] }),
  );
  await assertFails(
    updateDoc(doc(asUser('e2'), 'conversas/c1'), { mensagens: [] }),
  );
  await assertFails(
    updateDoc(doc(asUser('m1'), 'conversas/c1'), { participantes: ['m1', 'e2'] }),
  );
});

// --- admin (custom claim) ------------------------------------------------------

test('admin: edita e remove oportunidade de outro dono', async () => {
  await seed((db) =>
    setDoc(doc(db, 'oportunidades/o1'), { titulo: 'Show', donoId: 'e1' }),
  );

  const db = asAdmin();
  await assertSucceeds(updateDoc(doc(db, 'oportunidades/o1'), { titulo: 'Corrigido' }));
  await assertSucceeds(deleteDoc(doc(db, 'oportunidades/o1')));
});

test('admin: se candidata e convida sem ter tipoUsuario', async () => {
  await seedPapeis();
  await seed((db) => setDoc(doc(db, 'usuarios/adm'), { nome: 'Admin' }));

  const db = asAdmin();
  await assertSucceeds(
    setDoc(doc(db, 'interesses/adm_op_o1'), {
      ...candidatura,
      remetenteId: 'adm',
      musicoId: 'adm',
    }),
  );
  await assertSucceeds(
    setDoc(doc(db, 'interesses/adm_mu_m1'), { ...convite, remetenteId: 'adm' }),
  );
});

test('admin: campo admin gravado no próprio usuarios não dá poder', async () => {
  await seedPapeis();
  const e2 = asUser('e2');
  await assertSucceeds(
    setDoc(doc(e2, 'usuarios/e2'), { tipoUsuario: 'casaShow', admin: true }, { merge: true }),
  );

  await assertFails(updateDoc(doc(e2, 'oportunidades/o1'), { titulo: 'Hackeado' }));
  await assertFails(deleteDoc(doc(e2, 'oportunidades/o1')));
});

// --- smoke tests: coleções que não deveriam ter mudado de comportamento ----

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
