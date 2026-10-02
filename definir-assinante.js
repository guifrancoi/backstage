// Marca (ou desmarca) uma conta como assinante (Plano 7): grava/apaga
// `assinantes/{uid}`. As regras deixam qualquer autenticado ler e ninguém
// gravar pelo app — só o Admin SDK, que ignora as regras. O campo antigo
// `usuarios.assinante` não serve, porque o próprio usuário escreve lá.
//
// Uso:
//   BACKSTAGE_SERVICE_ACCOUNT_KEY=<chave> node definir-assinante.js musico@email.com
//   BACKSTAGE_SERVICE_ACCOUNT_KEY=<chave> node definir-assinante.js musico@email.com --dias=30
//   BACKSTAGE_SERVICE_ACCOUNT_KEY=<chave> node definir-assinante.js musico@email.com --remover
//
// Sem --dias a assinatura não expira. Vale no app na hora (a lista é em
// tempo real), sem novo login.
const fs = require('fs');
const path = require('path');
const { initializeApp, cert } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore, Timestamp } = require('firebase-admin/firestore');

async function main() {
  const email = process.argv[2];
  const remover = process.argv.includes('--remover');
  const argDias = process.argv.find((a) => a.startsWith('--dias='));
  const dias = argDias ? Number(argDias.split('=')[1]) : null;
  if (!email || email.startsWith('--')) {
    console.error(
      'Informe o e-mail: node definir-assinante.js <email> [--dias=N] [--remover]',
    );
    process.exit(1);
  }
  if (dias !== null && !(dias > 0)) {
    console.error('--dias precisa ser um número maior que zero.');
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
  const usuario = await getAuth().getUserByEmail(email);
  const ref = getFirestore().collection('assinantes').doc(usuario.uid);

  if (remover) {
    await ref.delete();
    console.log(`${email} (${usuario.uid}): assinatura removida`);
    return;
  }

  const agora = new Date();
  await ref.set({
    desde: Timestamp.fromDate(agora),
    expiraEm: dias
      ? Timestamp.fromDate(new Date(agora.getTime() + dias * 24 * 60 * 60 * 1000))
      : null,
  });
  console.log(
    `${email} (${usuario.uid}): assinante ${dias ? `por ${dias} dias` : 'sem expiração'}`,
  );
}

main().catch((erro) => {
  console.error(erro.message);
  process.exit(1);
});
