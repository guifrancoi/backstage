const fs = require('fs');
const path = require('path');

// `arquivo` = nome do JSON em Banco/; `colecao` = coleção de destino no Firestore.
// `musicos.json` é o catálogo de demonstração do backup antigo (sem uid dono) —
// desde a unificação de 27/09/2026 ele também vai para `perfis_musicos`, não
// existe mais uma coleção `musicos` separada no Firestore.
const FONTES = [
  { arquivo: 'usuarios', colecao: 'usuarios' },
  { arquivo: 'perfis_musicos', colecao: 'perfis_musicos' },
  { arquivo: 'musicos', colecao: 'perfis_musicos' },
  { arquivo: 'oportunidades', colecao: 'oportunidades' },
  { arquivo: 'conversas', colecao: 'conversas' },
  { arquivo: 'interesses_musicos', colecao: 'interesses_musicos' },
  { arquivo: 'interesses_oportunidades', colecao: 'interesses_oportunidades' },
];

const BANCO_DIR =
  process.env.BACKSTAGE_BACKUP_DIR || path.join(__dirname, '..', 'Banco');

/** Reconstrói Timestamps do Admin SDK a partir do formato serializado em JSON. */
function reviverTimestamps(valor, Timestamp) {
  if (Array.isArray(valor)) {
    return valor.map((item) => reviverTimestamps(item, Timestamp));
  }
  if (valor && typeof valor === 'object') {
    if (
      typeof valor._seconds === 'number' &&
      typeof valor._nanoseconds === 'number'
    ) {
      return new Timestamp(valor._seconds, valor._nanoseconds);
    }
    const resultado = {};
    for (const [chave, valorInterno] of Object.entries(valor)) {
      resultado[chave] = reviverTimestamps(valorInterno, Timestamp);
    }
    return resultado;
  }
  return valor;
}

function lerArquivo(nomeArquivo) {
  const caminho = path.join(BANCO_DIR, `${nomeArquivo}.json`);
  if (!fs.existsSync(caminho)) {
    return null;
  }
  return JSON.parse(fs.readFileSync(caminho, 'utf-8'));
}

async function restaurarColecao(db, Timestamp, { arquivo, colecao }, { dryRun }) {
  const registros = lerArquivo(arquivo);
  if (registros === null) {
    console.log(`${arquivo}: arquivo não encontrado em ${BANCO_DIR}, pulando.`);
    return 0;
  }

  console.log(`${arquivo}: ${registros.length} documento(s) no arquivo.`);
  if (dryRun) return registros.length;

  const batch = db.batch();
  for (const registro of registros) {
    const { id, ...dados } = registro;
    batch.set(
      db.collection(colecao).doc(id),
      reviverTimestamps(dados, Timestamp),
      { merge: true },
    );
  }
  await batch.commit();
  console.log(`${arquivo}: restaurado em ${colecao}.`);
  return registros.length;
}

/**
 * Inicializa o Admin SDK só quando necessário: contra o emulador não precisa
 * de credencial real; contra um projeto de verdade, exige serviceAccountKey.json.
 */
function inicializarFirestore() {
  const { initializeApp, cert } = require('firebase-admin/app');
  const { getFirestore, Timestamp } = require('firebase-admin/firestore');

  if (process.env.FIRESTORE_EMULATOR_HOST) {
    initializeApp({ projectId: process.env.GCLOUD_PROJECT || 'backstage-restore-test' });
    return { db: getFirestore(), Timestamp };
  }

  const caminhoChave =
    process.env.BACKSTAGE_SERVICE_ACCOUNT_KEY ||
    path.join(__dirname, 'serviceAccountKey.json');
  if (!fs.existsSync(caminhoChave)) {
    console.error(
      `serviceAccountKey.json não encontrado em ${caminhoChave}.\n` +
        'Baixe a chave em: Console do Firebase > Configurações do projeto > Contas de serviço > Gerar nova chave privada,\n' +
        'ou aponte BACKSTAGE_SERVICE_ACCOUNT_KEY para o caminho da chave.',
    );
    process.exit(1);
  }

  initializeApp({ credential: cert(require(path.resolve(caminhoChave))) });
  return { db: getFirestore(), Timestamp };
}

function fontesAlvo() {
  const arg = process.argv.find((a) => a.startsWith('--colecoes='));
  if (!arg) return FONTES;

  const pedidas = arg.slice('--colecoes='.length).split(',');
  const invalidas = pedidas.filter(
    (nome) => !FONTES.some((f) => f.arquivo === nome),
  );
  if (invalidas.length > 0) {
    console.error(`Arquivo(s) desconhecido(s): ${invalidas.join(', ')}`);
    process.exit(1);
  }
  return FONTES.filter((f) => pedidas.includes(f.arquivo));
}

async function main() {
  const dryRun = process.argv.includes('--dry-run');
  const alvo = fontesAlvo();

  if (dryRun) {
    for (const { arquivo } of alvo) {
      const registros = lerArquivo(arquivo);
      if (registros === null) {
        console.log(`${arquivo}: arquivo não encontrado em ${BANCO_DIR}, pulando.`);
      } else {
        console.log(`${arquivo}: ${registros.length} documento(s) no arquivo.`);
      }
    }
    return;
  }

  const { db, Timestamp } = inicializarFirestore();
  for (const fonte of alvo) {
    await restaurarColecao(db, Timestamp, fonte, { dryRun: false });
  }
}

if (require.main === module) {
  main();
}

module.exports = { FONTES, BANCO_DIR, reviverTimestamps, restaurarColecao, inicializarFirestore };
