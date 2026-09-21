# Backstage

Aplicativo Flutter do prototipo Backstage, preparado para rodar com dados
locais durante desenvolvimento e com integracao real usando Firebase
Authentication, Cloud Firestore e Firebase Hosting.

## O que ja esta integrado

- Firebase Core para inicializar o app.
- Firebase Authentication com login, cadastro, logout e recuperacao de senha
  por e-mail.
- Cloud Firestore para persistir usuarios, perfis, agenda, interesses,
  oportunidades, musicos e conversas.
- Firebase Hosting para publicar o build web em `build/web`.
- Fallback local com dados mocados quando as credenciais Firebase nao forem
  informadas.

## Pre-requisitos

Instale e valide:

```powershell
flutter --version
dart --version
node --version
npm --version
firebase --version
```

Se a Firebase CLI nao estiver instalada:

```powershell
npm install -g firebase-tools
firebase login
```

No repositorio, instale as dependencias Flutter:

```powershell
flutter pub get
```

## 1. Criar o projeto no Firebase

1. Acesse o Firebase Console.
2. Clique em `Add project`.
3. Crie um projeto, por exemplo `backstage`.
4. Guarde o `Project ID`; ele sera usado como `FIREBASE_PROJECT_ID`.

## 2. Habilitar Authentication

1. No Firebase Console, abra `Authentication`.
2. Clique em `Get started`.
3. Abra a aba `Sign-in method`.
4. Habilite o provedor `Email/Password`.
5. Salve.

O app usa esses metodos:

- `signInWithEmailAndPassword`
- `createUserWithEmailAndPassword`
- `sendPasswordResetEmail`
- `signOut`

## 3. Criar o Cloud Firestore

1. No Firebase Console, abra `Firestore Database`.
2. Clique em `Create database`.
3. Escolha uma regiao.
4. Para comecar com seguranca, escolha modo bloqueado ou producao.
5. Depois publique as regras locais deste repositorio com:

```powershell
firebase deploy --only firestore:rules
```

As regras estao em `firestore.rules`.

## 4. Registrar um app Web no Firebase

1. No Firebase Console, abra `Project settings`.
2. Em `Your apps`, clique no icone Web `</>`.
3. Informe um nome, por exemplo `backstage-web`.
4. Registre o app.
5. Copie os campos do objeto `firebaseConfig`.

Mapeie os campos assim:

| Firebase config | Dart define |
| --- | --- |
| `apiKey` | `FIREBASE_API_KEY` |
| `appId` | `FIREBASE_APP_ID` e `FIREBASE_WEB_APP_ID` |
| `projectId` | `FIREBASE_PROJECT_ID` |
| `messagingSenderId` | `FIREBASE_MESSAGING_SENDER_ID` |
| `authDomain` | `FIREBASE_AUTH_DOMAIN` |
| `storageBucket` | `FIREBASE_STORAGE_BUCKET` |
| `measurementId` | `FIREBASE_MEASUREMENT_ID` |

`FIREBASE_MEASUREMENT_ID` e opcional para este app.

## 5. Configurar o projeto local

Copie o arquivo de exemplo:

```powershell
Copy-Item .firebaserc.example .firebaserc
```

Edite `.firebaserc` e troque `seu-project-id` pelo Project ID real:

```json
{
  "projects": {
    "default": "backstage"
  }
}
```

O arquivo `.firebaserc` deve ficar local no seu ambiente. O exemplo pode ser
versionado, mas o arquivo real normalmente varia por projeto/ambiente.

## 6. Rodar localmente com Firebase real

Execute o app web passando as credenciais por `--dart-define`:

```powershell
flutter run -d chrome `
  --dart-define=FIREBASE_API_KEY=sua-api-key `
  --dart-define=FIREBASE_APP_ID=seu-web-app-id `
  --dart-define=FIREBASE_WEB_APP_ID=seu-web-app-id `
  --dart-define=FIREBASE_PROJECT_ID=seu-project-id `
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=seu-sender-id `
  --dart-define=FIREBASE_AUTH_DOMAIN=seu-project-id.firebaseapp.com `
  --dart-define=FIREBASE_STORAGE_BUCKET=seu-project-id.firebasestorage.app `
  --dart-define=FIREBASE_MEASUREMENT_ID=seu-measurement-id
```

Se nao passar esses defines, o app roda em modo local com os mocks. Isso e
intencional para facilitar desenvolvimento sem Firebase.

## 7. Primeiro teste funcional

Com o app rodando com Firebase real:

1. Abra a tela de cadastro.
2. Crie um usuario com e-mail e senha.
3. Confirme no Firebase Console em `Authentication > Users`.
4. Abra `Firestore Database`.
5. Verifique se foi criado um documento em `usuarios`.
6. Acesse listas de musicos, oportunidades e conversas.

No primeiro uso, o app cria dados iniciais em:

- `musicos`
- `oportunidades`
- `conversas`

Isso acontece somente se essas colecoes estiverem vazias.

## 8. Colecoes do Firestore

O app usa estas colecoes:

| Colecao | Uso |
| --- | --- |
| `usuarios` | dados basicos do usuario autenticado |
| `perfis_musicos` | perfil editavel do artista |
| `musicos` | lista publica de artistas do prototipo |
| `oportunidades` | lista publica de oportunidades do prototipo |
| `interesses_oportunidades` | interesses do usuario em oportunidades |
| `interesses_musicos` | interesses do usuario em artistas |
| `disponibilidades` | datas disponiveis da agenda do usuario |
| `conversas` | conversas e mensagens simples do prototipo |

## 9. Regras de seguranca

As regras locais ficam em:

```text
firestore.rules
```

Publicar regras:

```powershell
firebase deploy --only firestore:rules
```

Resumo das regras atuais:

- exige usuario autenticado para acessar o Firestore;
- `usuarios/{uid}` so pode ser lido/escrito pelo proprio usuario;
- `perfis_musicos/{uid}` pode ser lido por usuarios autenticados e escrito
  pelo proprio dono;
- interesses e disponibilidades ficam limitados ao proprio `request.auth.uid`;
- `musicos`, `oportunidades` e `conversas` estao liberados para usuarios
  autenticados no prototipo.

Para producao, revise principalmente permissoes de escrita em `musicos`,
`oportunidades` e `conversas`, criando perfis de admin/contratante/artista.

## 10. Build web para Hosting

Gere o build web com as mesmas credenciais:

```powershell
flutter build web `
  --dart-define=FIREBASE_API_KEY=sua-api-key `
  --dart-define=FIREBASE_APP_ID=seu-web-app-id `
  --dart-define=FIREBASE_WEB_APP_ID=seu-web-app-id `
  --dart-define=FIREBASE_PROJECT_ID=seu-project-id `
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=seu-sender-id `
  --dart-define=FIREBASE_AUTH_DOMAIN=seu-project-id.firebaseapp.com `
  --dart-define=FIREBASE_STORAGE_BUCKET=seu-project-id.firebasestorage.app `
  --dart-define=FIREBASE_MEASUREMENT_ID=seu-measurement-id
```

O build final sera gerado em:

```text
build/web
```

O `firebase.json` ja aponta o Hosting para esse diretorio.

## 11. Deploy no Firebase Hosting

Deploy completo de Hosting e regras:

```powershell
firebase deploy --only hosting,firestore:rules
```

Deploy apenas do Hosting:

```powershell
firebase deploy --only hosting
```

Deploy apenas das regras:

```powershell
firebase deploy --only firestore:rules
```

Depois do deploy, a Firebase CLI exibira a URL publicada.

## 12. Validacao antes de publicar

Rode:

```powershell
flutter analyze
flutter build web
```

Para validar com Firebase real, rode o `flutter build web` com os
`--dart-define` da secao de build.

## 13. Problemas comuns

### App abre, mas continua usando dados mocados

Algum `--dart-define` obrigatorio nao foi passado. Confira:

- `FIREBASE_API_KEY`
- `FIREBASE_APP_ID`
- `FIREBASE_PROJECT_ID`
- `FIREBASE_MESSAGING_SENDER_ID`

### Login/cadastro falha

Verifique:

- o provedor Email/Password esta habilitado;
- o e-mail tem formato valido;
- a senha atende ao minimo do Firebase;
- o app esta usando o `projectId` correto.

### Firestore retorna erro de permissao

Verifique:

- o usuario esta autenticado;
- as regras foram publicadas com `firebase deploy --only firestore:rules`;
- os documentos de usuario usam o mesmo `uid` do Firebase Auth.

### Deploy mostra a pagina padrao do Firebase

Isso normalmente indica que o Hosting nao esta apontando para `build/web` ou
que o build nao foi gerado antes do deploy.

Rode novamente:

```powershell
flutter build web
firebase deploy --only hosting
```

### Rotas quebram ao atualizar a pagina

O `firebase.json` tem rewrite para `index.html`:

```json
{
  "source": "**",
  "destination": "/index.html"
}
```

Mantenha esse rewrite para apps Flutter Web com navegacao client-side.

## Referencias oficiais

- Firebase Hosting para Flutter Web:
  https://firebase.google.com/docs/hosting/frameworks/flutter
- Firebase CLI:
  https://firebase.google.com/docs/cli
- Build e deploy Flutter Web:
  https://docs.flutter.dev/deployment/web
