const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const fs = require('fs');

// Carrega as credenciais baixadas do console do Firebase
const serviceAccount = require('./serviceAccountKey.json');

// Inicialização moderna do SDK Admin
initializeApp({
  credential: cert(serviceAccount)
});

const db = getFirestore();

async function exportarColecao(nomeColecao) {
  try {
    console.log(`Iniciando a leitura da coleção: ${nomeColecao}...`);
    const snapshot = await db.collection(nomeColecao).get();
    
    if (snapshot.empty) {
      console.log('Nenhum documento encontrado.');
      return;
    }

    const dados = [];
    snapshot.forEach(doc => {
      dados.push({
        id: doc.id,
        ...doc.data()
      });
    });

    // Salva o JSON formatado
    fs.writeFileSync(`${nomeColecao}.json`, JSON.stringify(dados, null, 2), 'utf-8');
    console.log(`Sucesso! A coleção "${nomeColecao}" foi salva em ${nomeColecao}.json`);
  } catch (erro) {
    console.error('Ocorreu um erro durante a exportação:', erro);
  }
}

// Executa a função para a sua coleção de usuários
exportarColecao('usuarios');
