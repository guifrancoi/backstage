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

/** Data a [n] dias de hoje (negativo = passado), à meia-noite local. */
function emDias(n) {
  const d = new Date();
  d.setHours(0, 0, 0, 0);
  d.setDate(d.getDate() + n);
  return d;
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

test('perfis_musicos: miniatura da foto até 200000 caracteres (Plano 14)', async () => {
  const dono = asUser('u1');
  const ref = doc(dono, 'perfis_musicos/u1');
  await assertSucceeds(setDoc(ref, { nomeArtistico: 'Banda X', foto: 'a'.repeat(200000) }));
  await assertSucceeds(setDoc(ref, { nomeArtistico: 'Banda X', foto: null }));
  await assertFails(setDoc(ref, { nomeArtistico: 'Banda X', foto: 'a'.repeat(200001) }));
  await assertFails(setDoc(ref, { nomeArtistico: 'Banda X', foto: 123 }));
  await assertSucceeds(deleteDoc(ref));
});

// --- assinantes (Plano 7) --------------------------------------------------

test('assinantes: autenticado lê; ninguém grava pelo app, nem o próprio uid', async () => {
  await seed((db) => setDoc(doc(db, 'assinantes/u1'), { desde: new Date() }));

  await assertSucceeds(getDocs(collection(asUser('u2'), 'assinantes')));
  await assertFails(getDoc(doc(asAnon(), 'assinantes/u1')));
  await assertFails(setDoc(doc(asUser('u2'), 'assinantes/u2'), { desde: new Date() }));
  await assertFails(deleteDoc(doc(asUser('u1'), 'assinantes/u1')));
  await assertFails(
    setDoc(doc(testEnv.authenticatedContext('adm', { admin: true }).firestore(), 'assinantes/u3'), {
      desde: new Date(),
    }),
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

// Plano 16: contato e CNPJ só em estabelecimentos/{uid}/privado/dados.
const privadoE1 = 'estabelecimentos/e1/privado/dados';

test('estabelecimentos: documento público não aceita contato nem CNPJ', async () => {
  const dono = asUser('e1');
  await assertFails(
    setDoc(doc(dono, 'estabelecimentos/e1'), { nome: 'Bar', contato: '16 9999' }),
  );
  await assertFails(
    setDoc(doc(dono, 'estabelecimentos/e1'), { nome: 'Bar', cnpj: '00.000' }),
  );
});

test('estabelecimentos/privado: o dono grava e lê; só contato e cnpj', async () => {
  const dono = asUser('e1');
  await assertSucceeds(setDoc(doc(dono, privadoE1), { contato: '16 9999', cnpj: '00.000' }));
  await assertSucceeds(getDoc(doc(dono, privadoE1)));
  await assertFails(setDoc(doc(dono, privadoE1), { contato: '1', outro: 'x' }));
  await assertFails(
    setDoc(doc(dono, 'estabelecimentos/e1/privado/outro'), { contato: '1' }),
  );
  await assertFails(setDoc(doc(asUser('m1'), privadoE1), { contato: '1' }));
});

test('estabelecimentos/privado: só lê quem já conversa com o dono', async () => {
  await seed((db) => setDoc(doc(db, privadoE1), { contato: '16 9999', cnpj: '00.000' }));

  // Sem conversa: nem músico nem anônimo leem.
  await assertFails(getDoc(doc(asUser('m1'), privadoE1)));
  await assertFails(getDoc(doc(asAnon(), privadoE1)));

  // Conversa do par (id = uids em ordem): libera só para esse par.
  await seed((db) => setDoc(doc(db, 'conversas/e1_m1'), { participantes: ['e1', 'm1'] }));
  await assertSucceeds(getDoc(doc(asUser('m1'), privadoE1)));
  await assertFails(getDoc(doc(asUser('m2'), privadoE1)));

  // Ordem inversa (uid do músico menor que o do dono) também vale.
  await seed(async (db) => {
    await setDoc(doc(db, 'estabelecimentos/z9/privado/dados'), { contato: '1' });
    await setDoc(doc(db, 'conversas/m1_z9'), { participantes: ['m1', 'z9'] });
  });
  await assertSucceeds(getDoc(doc(asUser('m1'), 'estabelecimentos/z9/privado/dados')));
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
    await setDoc(doc(db, 'oportunidades/o1'), { titulo: 'Show', donoId: 'e1', dataEvento: emDias(30) });
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

// Conversa por par: id = uids em ordem ('e1' < 'm1').
test('conversas: aceitar cria a conversa do par no mesmo batch', async () => {
  await seedPapeis();
  await seed((db) => setDoc(doc(db, 'interesses/m1_op_o1'), candidatura));

  const db = asUser('e1');
  const batch = writeBatch(db);
  batch.set(doc(db, 'conversas/e1_m1'), {
    participantes: ['e1', 'm1'],
    nomes: { m1: 'Músico', e1: 'Bar' },
    interesseId: 'm1_op_o1',
    interesseIds: ['m1_op_o1'],
    mensagens: [],
  });
  batch.update(doc(db, 'interesses/m1_op_o1'), {
    status: 'aceito',
    conversaId: 'e1_m1',
  });
  await assertSucceeds(batch.commit());
});

test('conversas: segundo aceite entre o mesmo par reaproveita a conversa', async () => {
  await seedPapeis();
  await seed(async (db) => {
    await setDoc(doc(db, 'interesses/e1_mu_m1'), convite);
    await setDoc(doc(db, 'conversas/e1_m1'), {
      participantes: ['e1', 'm1'],
      interesseId: 'm1_op_o1',
      interesseIds: ['m1_op_o1'],
      mensagens: [],
    });
  });

  const db = asUser('m1');
  const batch = writeBatch(db);
  batch.set(
    doc(db, 'conversas/e1_m1'),
    { participantes: ['e1', 'm1'], interesseId: 'e1_mu_m1', interesseIds: ['m1_op_o1', 'e1_mu_m1'] },
    { merge: true },
  );
  batch.update(doc(db, 'interesses/e1_mu_m1'), { status: 'aceito', conversaId: 'e1_m1' });
  await assertSucceeds(batch.commit());
});

test('conversas: parte de interesse já aceito recria a conversa do par', async () => {
  await seed((db) =>
    setDoc(doc(db, 'interesses/m1_op_o1'), { ...candidatura, status: 'aceito' }),
  );
  await assertSucceeds(
    setDoc(doc(asUser('m1'), 'conversas/e1_m1'), {
      participantes: ['e1', 'm1'],
      interesseId: 'm1_op_o1',
    }),
  );
});

test('conversas: não cria sem interesse aceito, fora do par ou com id errado', async () => {
  await seedPapeis();
  await seed(async (db) => {
    await setDoc(doc(db, 'interesses/m1_op_o1'), candidatura); // pendente
    await setDoc(doc(db, 'interesses/e1_mu_m1'), { ...convite, status: 'aceito' });
  });
  const base = { participantes: ['e1', 'm1'], interesseId: 'e1_mu_m1' };

  // Interesse ainda pendente.
  await assertFails(
    setDoc(doc(asUser('e1'), 'conversas/e1_m1'), { ...base, interesseId: 'm1_op_o1' }),
  );
  // Id que não é o do par, ou participantes fora de ordem.
  await assertFails(setDoc(doc(asUser('e1'), 'conversas/e1_mu_m1'), base));
  await assertFails(
    setDoc(doc(asUser('e1'), 'conversas/e1_m1'), { ...base, participantes: ['m1', 'e1'] }),
  );
  // Terceiro que não é parte do interesse.
  await assertFails(setDoc(doc(asUser('e2'), 'conversas/e1_m1'), base));
  // Sem interesse.
  await assertFails(
    setDoc(doc(asUser('e1'), 'conversas/e1_m1'), { participantes: ['e1', 'm1'] }),
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

test('bloqueios: só o próprio usuarioId', async () => {
  const db = asUser('u1');
  await assertSucceeds(
    setDoc(doc(db, 'bloqueios/u1_2026-05-10'), {
      usuarioId: 'u1',
    }),
  );
  await assertFails(
    setDoc(doc(db, 'bloqueios/u2_2026-05-10'), {
      usuarioId: 'u2',
    }),
  );
});

test('bloqueios: qualquer autenticado lê (agenda pública); anônimo não', async () => {
  await seed(async (db) => {
    await setDoc(doc(db, 'bloqueios/m1_2026-05-10'), {
      usuarioId: 'm1',
    });
  });
  await assertSucceeds(getDoc(doc(asUser('e1'), 'bloqueios/m1_2026-05-10')));
  await assertFails(getDoc(doc(asAnon(), 'bloqueios/m1_2026-05-10')));
});

test('músicos livres no dia (Plano 13): consulta por dia em bloqueios e ocupacoes', async () => {
  await seed(async (db) => {
    await setDoc(doc(db, 'bloqueios/m1_2026-05-10'), {
      usuarioId: 'm1',
      dia: '2026-05-10',
    });
    await setDoc(doc(db, 'ocupacoes/m2_2026-05-10'), {
      musicoId: 'm2',
      dia: '2026-05-10',
      contratacaoId: 'c1',
    });
  });
  const e1 = asUser('e1');
  await assertSucceeds(
    getDocs(query(collection(e1, 'bloqueios'), where('dia', '==', '2026-05-10'))),
  );
  await assertSucceeds(
    getDocs(query(collection(e1, 'ocupacoes'), where('dia', '==', '2026-05-10'))),
  );
  await assertFails(
    getDocs(query(collection(asAnon(), 'bloqueios'), where('dia', '==', '2026-05-10'))),
  );
});

// --- contratacoes / ocupacoes (Plano 9B) ----------------------------------

const proposta = {
  interesseId: 'i1',
  musicoId: 'm1',
  donoId: 'e1',
  dia: '2026-11-20',
  horaInicio: '20:00',
  horaFim: '23:00',
  cacheAcordado: 1500,
  status: 'proposta',
};

/** Convite e1 → m1 já aceito (i1) e, se [comProposta], a proposta c1. */
async function seedContratacao({ comProposta = true, status = 'proposta' } = {}) {
  await seed(async (db) => {
    await setDoc(doc(db, 'interesses/i1'), { ...convite, status: 'aceito' });
    if (comProposta) {
      await setDoc(doc(db, 'contratacoes/c1'), { ...proposta, status });
    }
    if (status === 'confirmada') {
      await setDoc(doc(db, 'ocupacoes/m1_2026-11-20'), {
        musicoId: 'm1',
        dia: '2026-11-20',
        contratacaoId: 'c1',
      });
    }
  });
}

function confirmar(db, contratacaoId = 'c1') {
  const batch = writeBatch(db);
  batch.update(doc(db, `contratacoes/${contratacaoId}`), {
    status: 'confirmada',
    respondidoEm: new Date(),
  });
  batch.set(doc(db, 'ocupacoes/m1_2026-11-20'), {
    musicoId: 'm1',
    dia: '2026-11-20',
    contratacaoId,
  });
  return batch.commit();
}

test('contratacoes: dono propõe a partir de interesse aceito seu', async () => {
  await seedContratacao({ comProposta: false });
  await assertSucceeds(setDoc(doc(asUser('e1'), 'contratacoes/nova'), proposta));
});

test('contratacoes: não propõe com interesse pendente, alheio ou em nome de outro', async () => {
  await seed(async (db) => {
    await setDoc(doc(db, 'interesses/i1'), convite); // ainda pendente
    await setDoc(doc(db, 'interesses/i2'), {
      ...convite,
      remetenteId: 'e2',
      status: 'aceito',
    });
  });
  const dono = asUser('e1');
  await assertFails(setDoc(doc(dono, 'contratacoes/a'), proposta));
  await assertFails(
    setDoc(doc(dono, 'contratacoes/b'), { ...proposta, interesseId: 'i2' }),
  );
  // Músico não propõe (o donoId teria que ser ele).
  await assertFails(
    setDoc(doc(asUser('m1'), 'contratacoes/c'), { ...proposta, donoId: 'm1' }),
  );
});

test('contratacoes: só as duas partes leem', async () => {
  await seedContratacao();
  await assertSucceeds(getDoc(doc(asUser('e1'), 'contratacoes/c1')));
  await assertSucceeds(getDoc(doc(asUser('m1'), 'contratacoes/c1')));
  await assertFails(getDoc(doc(asUser('x9'), 'contratacoes/c1')));
});

test('contratacoes: consultas por músico/dono (como o app faz) passam', async () => {
  await seedContratacao();
  const m1 = asUser('m1');
  await assertSucceeds(
    getDocs(query(collection(m1, 'contratacoes'), where('musicoId', '==', 'm1'))),
  );
  await assertSucceeds(
    getDocs(query(collection(m1, 'contratacoes'), where('donoId', '==', 'm1'))),
  );
});

test('contratacoes: músico confirma travando o dia no mesmo batch', async () => {
  await seedContratacao();
  await assertSucceeds(confirmar(asUser('m1')));
  await assertSucceeds(getDoc(doc(asUser('x9'), 'ocupacoes/m1_2026-11-20')));
});

test('contratacoes: confirmar sem a trava, ou pelo dono, falha', async () => {
  await seedContratacao();
  await assertFails(
    updateDoc(doc(asUser('m1'), 'contratacoes/c1'), { status: 'confirmada' }),
  );
  await assertFails(confirmar(asUser('e1')));
});

test('contratacoes: segundo show no mesmo dia não confirma', async () => {
  await seedContratacao({ status: 'confirmada' });
  await seed(async (db) => {
    await setDoc(doc(db, 'contratacoes/c2'), { ...proposta, donoId: 'e1' });
  });
  await assertFails(confirmar(asUser('m1'), 'c2'));
});

test('contratacoes: músico recusa; dono retira a proposta', async () => {
  await seedContratacao();
  await assertSucceeds(
    updateDoc(doc(asUser('m1'), 'contratacoes/c1'), { status: 'recusada' }),
  );
  await seedContratacao();
  await assertSucceeds(
    updateDoc(doc(asUser('e1'), 'contratacoes/c1'), {
      status: 'cancelada',
      canceladoPor: 'e1',
    }),
  );
});

test('contratacoes: resposta não altera cachê, dia nem partes', async () => {
  await seedContratacao();
  await assertFails(
    updateDoc(doc(asUser('m1'), 'contratacoes/c1'), {
      status: 'recusada',
      cacheAcordado: 1,
    }),
  );
  await assertFails(
    updateDoc(doc(asUser('e1'), 'contratacoes/c1'), { cacheAcordado: 99999 }),
  );
});

test('contratacoes: cancelar confirmada exige liberar o dia junto', async () => {
  await seedContratacao({ status: 'confirmada' });
  const m1 = asUser('m1');
  await assertFails(
    updateDoc(doc(m1, 'contratacoes/c1'), {
      status: 'cancelada',
      canceladoPor: 'm1',
    }),
  );

  const batch = writeBatch(m1);
  batch.update(doc(m1, 'contratacoes/c1'), {
    status: 'cancelada',
    canceladoPor: 'm1',
    motivoCancelamento: 'Imprevisto',
  });
  batch.delete(doc(m1, 'ocupacoes/m1_2026-11-20'));
  await assertSucceeds(batch.commit());
});

test('ocupacoes: não se cria nem apaga fora do fluxo da contratação', async () => {
  await seedContratacao({ status: 'confirmada' });
  // Trava avulsa (sem contratação confirmada) e de outro músico.
  await assertFails(
    setDoc(doc(asUser('m1'), 'ocupacoes/m1_2026-12-01'), {
      musicoId: 'm1',
      dia: '2026-12-01',
      contratacaoId: 'c1',
    }),
  );
  // Apagar a trava de contratação ainda confirmada.
  await assertFails(deleteDoc(doc(asUser('e1'), 'ocupacoes/m1_2026-11-20')));
  await assertFails(getDoc(doc(asAnon(), 'ocupacoes/m1_2026-11-20')));
});

// --- notificacoes / interesse cancelado (Plano 11) ---------------------------

const notificacao = {
  destinatarioId: 'm1',
  autorId: 'e1',
  autorNome: 'Bar Central',
  tipo: 'oportunidadeAlterada',
  titulo: 'Oportunidade alterada',
  texto: 'cachê mudou',
  interesseId: 'i1',
  lida: false,
  criadaEm: new Date(),
};

async function seedInteresseAceito() {
  await seed(async (db) => {
    await setDoc(doc(db, 'interesses/i1'), { ...convite, status: 'aceito' });
  });
}

test('notificacoes: notifica a outra parte do interesse', async () => {
  await seedInteresseAceito();
  await assertSucceeds(setDoc(doc(asUser('e1'), 'notificacoes/n1'), notificacao));
  // O músico também notifica o dono (ex.: confirmou o show).
  await assertSucceeds(
    setDoc(doc(asUser('m1'), 'notificacoes/n2'), {
      ...notificacao,
      destinatarioId: 'e1',
      autorId: 'm1',
    }),
  );
});

test('notificacoes: sem vínculo, com autor falso ou para si mesmo falha', async () => {
  await seedInteresseAceito();
  // Estranho notificando uma parte do interesse.
  await assertFails(
    setDoc(doc(asUser('x9'), 'notificacoes/a'), { ...notificacao, autorId: 'x9' }),
  );
  // Parte do interesse notificando um terceiro.
  await assertFails(
    setDoc(doc(asUser('e1'), 'notificacoes/b'), { ...notificacao, destinatarioId: 'x9' }),
  );
  // Autor falso.
  await assertFails(
    setDoc(doc(asUser('e1'), 'notificacoes/c'), { ...notificacao, autorId: 'm1' }),
  );
  // Para si mesmo, já lida ou com campo extra.
  await assertFails(
    setDoc(doc(asUser('e1'), 'notificacoes/d'), { ...notificacao, destinatarioId: 'e1' }),
  );
  await assertFails(
    setDoc(doc(asUser('e1'), 'notificacoes/e'), { ...notificacao, lida: true }),
  );
  await assertFails(
    setDoc(doc(asUser('e1'), 'notificacoes/f'), { ...notificacao, extra: 1 }),
  );
  // Interesse inexistente.
  await assertFails(
    setDoc(doc(asUser('e1'), 'notificacoes/g'), { ...notificacao, interesseId: 'nao' }),
  );
});

test('notificacoes: só o destinatário lê, marca como lida e apaga', async () => {
  await seed(async (db) => {
    await setDoc(doc(db, 'notificacoes/n1'), notificacao);
  });
  const m1 = asUser('m1');
  const e1 = asUser('e1');
  await assertSucceeds(getDoc(doc(m1, 'notificacoes/n1')));
  await assertFails(getDoc(doc(e1, 'notificacoes/n1')));
  await assertSucceeds(
    getDocs(query(collection(m1, 'notificacoes'), where('destinatarioId', '==', 'm1'))),
  );
  await assertFails(updateDoc(doc(m1, 'notificacoes/n1'), { texto: 'outro' }));
  await assertFails(updateDoc(doc(e1, 'notificacoes/n1'), { lida: true }));
  await assertSucceeds(updateDoc(doc(m1, 'notificacoes/n1'), { lida: true }));
  await assertFails(deleteDoc(doc(e1, 'notificacoes/n1')));
  await assertSucceeds(deleteDoc(doc(m1, 'notificacoes/n1')));
});

test('interesses: remetente encerra convite pendente como cancelado; destinatário não', async () => {
  await seed(async (db) => {
    await setDoc(doc(db, 'interesses/i1'), convite);
  });
  await assertFails(
    updateDoc(doc(asUser('m1'), 'interesses/i1'), { status: 'cancelado' }),
  );
  await assertSucceeds(
    updateDoc(doc(asUser('e1'), 'interesses/i1'), {
      status: 'cancelado',
      respondidoEm: new Date(),
    }),
  );
  // Depois de encerrado, nada mais muda.
  await assertFails(
    updateDoc(doc(asUser('m1'), 'interesses/i1'), { status: 'aceito' }),
  );
});

test('interesses: consulta por parte + oportunidade (remoção pelo dono) passa', async () => {
  await seed(async (db) => {
    await setDoc(doc(db, 'interesses/m1_op_o1'), candidatura);
  });
  const e1 = asUser('e1');
  await assertSucceeds(
    getDocs(
      query(
        collection(e1, 'interesses'),
        where('destinatarioId', '==', 'e1'),
        where('oportunidadeId', '==', 'o1'),
      ),
    ),
  );
});

test('conversas: participante registra a leitura (lidaEm)', async () => {
  await seed(async (db) => {
    await setDoc(doc(db, 'conversas/i1'), {
      participantes: ['e1', 'm1'],
      mensagens: [],
    });
  });
  await assertSucceeds(
    updateDoc(doc(asUser('m1'), 'conversas/i1'), { 'lidaEm.m1': new Date() }),
  );
  await assertFails(
    updateDoc(doc(asUser('x9'), 'conversas/i1'), { 'lidaEm.x9': new Date() }),
  );
});

test('oportunidades: dono remove encerrando interesses pendentes no mesmo batch', async () => {
  await seed(async (db) => {
    await setDoc(doc(db, 'oportunidades/o1'), { titulo: 'Show', donoId: 'e1', dataEvento: emDias(30) });
    await setDoc(doc(db, 'interesses/m1_op_o1'), candidatura);
    await setDoc(doc(db, 'interesses/e1_mu_m1_o1'), { ...convite, oportunidadeId: 'o1' });
  });
  const e1 = asUser('e1');
  const batch = writeBatch(e1);
  batch.update(doc(e1, 'interesses/m1_op_o1'), {
    status: 'recusado',
    respondidoEm: new Date(),
  });
  batch.update(doc(e1, 'interesses/e1_mu_m1_o1'), {
    status: 'cancelado',
    respondidoEm: new Date(),
  });
  batch.delete(doc(e1, 'oportunidades/o1'));
  await assertSucceeds(batch.commit());
});

// --- oportunidade vencida (Plano 12) ------------------------------------------

test('interesses: não se candidata nem convida para oportunidade que já passou', async () => {
  await seedPapeis();
  await seed(async (db) => {
    await setDoc(doc(db, 'oportunidades/o1'), {
      titulo: 'Show',
      donoId: 'e1',
      dataEvento: emDias(-1),
    });
  });
  await assertFails(
    setDoc(doc(asUser('m1'), `interesses/m1_op_o1`), candidatura),
  );
  await assertFails(
    setDoc(doc(asUser('e1'), 'interesses/e1_mu_m1_o1'), {
      ...convite,
      oportunidadeId: 'o1',
    }),
  );
  // Convite sem oportunidade continua valendo.
  await assertSucceeds(setDoc(doc(asUser('e1'), 'interesses/e1_mu_m1'), convite));
});

test('interesses: o próprio dia do evento ainda aceita candidatura', async () => {
  await seedPapeis();
  await seed(async (db) => {
    await setDoc(doc(db, 'oportunidades/o1'), {
      titulo: 'Show',
      donoId: 'e1',
      dataEvento: emDias(0),
    });
  });
  await assertSucceeds(
    setDoc(doc(asUser('m1'), 'interesses/m1_op_o1'), candidatura),
  );
});

test('disponibilidades (coleção antiga) não é mais acessível', async () => {
  await assertFails(
    setDoc(doc(asUser('u1'), 'disponibilidades/u1_2026-05-10'), { usuarioId: 'u1' }),
  );
});

// --- avaliacoes (Plano 17) ---------------------------------------------------

/** `yyyy-mm-dd` (fuso local) de [n] dias atrás. */
function diaHa(n) {
  const d = emDias(-n);
  const mm = String(d.getMonth() + 1).padStart(2, '0');
  const dd = String(d.getDate()).padStart(2, '0');
  return `${d.getFullYear()}-${mm}-${dd}`;
}

/** Contratação c1 (m1 × e1) com o show há [diasAtras] dias. */
async function seedShow({ diasAtras = 2, status = 'confirmada' } = {}) {
  await seed((db) =>
    setDoc(doc(db, 'contratacoes/c1'), { ...proposta, dia: diaHa(diasAtras), status }),
  );
}

function avaliacao(autorId, avaliadoId, extra = {}) {
  return {
    contratacaoId: 'c1',
    autorId,
    autorNome: autorId,
    avaliadoId,
    nota: 5,
    comentario: 'Ótimo show',
    criadaEm: new Date(),
    ...extra,
  };
}

test('avaliacoes: as duas partes avaliam a outra depois do show', async () => {
  await seedShow();
  await assertSucceeds(setDoc(doc(asUser('m1'), 'avaliacoes/c1_m1'), avaliacao('m1', 'e1')));
  await assertSucceeds(setDoc(doc(asUser('e1'), 'avaliacoes/c1_e1'), avaliacao('e1', 'm1')));
  // Leitura pública para autenticados; anônimo não.
  await assertSucceeds(getDoc(doc(asUser('x9'), 'avaliacoes/c1_m1')));
  await assertFails(getDoc(doc(asAnon(), 'avaliacoes/c1_m1')));
});

test('avaliacoes: não avalia antes do show acabar nem depois de 30 dias', async () => {
  await seedShow({ diasAtras: 0 });
  await assertFails(setDoc(doc(asUser('m1'), 'avaliacoes/c1_m1'), avaliacao('m1', 'e1')));

  await seedShow({ diasAtras: 1 });
  await assertSucceeds(setDoc(doc(asUser('m1'), 'avaliacoes/c1_m1'), avaliacao('m1', 'e1')));

  await seedShow({ diasAtras: 32 });
  await assertFails(setDoc(doc(asUser('e1'), 'avaliacoes/c1_e1'), avaliacao('e1', 'm1')));
});

test('avaliacoes: só quem participou, avaliando a outra parte, show confirmado', async () => {
  await seedShow();
  // Estranho.
  await assertFails(setDoc(doc(asUser('x9'), 'avaliacoes/c1_x9'), avaliacao('x9', 'e1')));
  // A si mesmo.
  await assertFails(setDoc(doc(asUser('m1'), 'avaliacoes/c1_m1'), avaliacao('m1', 'm1')));
  // Autor falso.
  await assertFails(setDoc(doc(asUser('m1'), 'avaliacoes/c1_e1'), avaliacao('e1', 'm1')));

  await seedShow({ status: 'cancelada' });
  await assertFails(setDoc(doc(asUser('m1'), 'avaliacoes/c1_m1'), avaliacao('m1', 'e1')));
});

test('avaliacoes: nota 1 a 5, comentário até 300, chaves fechadas, uma vez só', async () => {
  await seedShow();
  const m1 = asUser('m1');
  const ref = doc(m1, 'avaliacoes/c1_m1');
  await assertFails(setDoc(ref, avaliacao('m1', 'e1', { nota: 0 })));
  await assertFails(setDoc(ref, avaliacao('m1', 'e1', { nota: 6 })));
  await assertFails(setDoc(ref, avaliacao('m1', 'e1', { nota: 4.5 })));
  await assertFails(setDoc(ref, avaliacao('m1', 'e1', { comentario: 'x'.repeat(301) })));
  await assertFails(setDoc(ref, avaliacao('m1', 'e1', { extra: true })));
  await assertFails(setDoc(doc(m1, 'avaliacoes/outro_id'), avaliacao('m1', 'e1')));

  await assertSucceeds(setDoc(ref, avaliacao('m1', 'e1', { comentario: 'x'.repeat(300) })));
  // Sem editar nem apagar (criar de novo = update).
  await assertFails(setDoc(ref, avaliacao('m1', 'e1', { nota: 1 })));
  await assertFails(deleteDoc(ref));
});
