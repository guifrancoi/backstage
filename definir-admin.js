// Marca (ou desmarca) uma conta como admin via custom claim do Firebase Auth.
// As regras do Firestore e o app leem `request.auth.token.admin`; um campo em
// `usuarios` não serve, porque o próprio usuário consegue escrever lá.
//
// Uso:
//   BACKSTAGE_SERVICE_ACCOUNT_KEY=<chave> node definir-admin.js admin@email.com
//   BACKSTAGE_SERVICE_ACCOUNT_KEY=<chave> node definir-admin.js admin@email.com --remover
//
// A claim só passa a valer no app depois de um novo login (token renovado).
const fs = require('fs');
const path = require('path');
const { initializeApp, cert } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');

async function main() {
  const email = process.argv[2];
  const remover = process.argv.includes('--remover');
  if (!email || email.startsWith('--')) {
    console.error('Informe o e-mail: node definir-admin.js <email> [--remover]');
    process.exit(1);
  }

  const caminhoChave =
    process.env.BACKSTAGE_SERVICE_ACCOUNT_KEY ||
    path.join(__dirname, 'serviceAccountKey.json');
  if (!fs.existsSync(caminhoChave)) {
    console.error(
      `Chave de serviço não encontrada em ${caminhoChave}. ` +
        'Aponte BACKSTAGE_SERVICE_ACCOUNT_KEY para a chave do projeto.',
    );
    process.exit(1);
  }

  initializeApp({ credential: cert(require(path.resolve(caminhoChave))) });
  const auth = getAuth();

  const usuario = await auth.getUserByEmail(email);
  const claims = { ...(usuario.customClaims || {}) };
  if (remover) {
    delete claims.admin;
  } else {
    claims.admin = true;
  }
  await auth.setCustomUserClaims(usuario.uid, claims);

  const atualizado = await auth.getUser(usuario.uid);
  console.log(
    `${email} (${usuario.uid}): claims = ${JSON.stringify(atualizado.customClaims || {})}`,
  );
}

main().catch((erro) => {
  console.error(erro.message);
  process.exit(1);
});
