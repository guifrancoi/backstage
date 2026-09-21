# Backstage

Aplicativo Flutter mobile Backstage. O app usa Firebase
Authentication e Cloud Firestore, com dados mock como fallback quando o
Firebase nao esta inicializado.

## Plataformas e configuracao Firebase

O alvo principal e mobile:

- Android: `android/app/google-services.json`
- iOS: `ios/Runner/GoogleService-Info.plist`
- Configuracao compartilhada do Flutter: `lib/core/firebase/firebase_options.dart`
- Inicializacao: `lib/core/firebase/firebase_bootstrap.dart`

As configuracoes foram geradas para o projeto Firebase `backstage-531a9`.
Chaves Firebase de cliente nao sao senhas, mas devem ser restringidas no
Google Cloud por aplicativo Android/iOS e pelas APIs necessarias.

O app Web nao e o alvo principal. No Chrome, o Flutter executa como Web mesmo
quando o `DevicePreview` esta configurado para mostrar um aparelho Android ou
iOS. O DevicePreview altera dimensoes e aparencia, mas nao simula APIs
nativas. Para testar Firebase e recursos nativos mobile, use um emulador ou
dispositivo Android/iOS.

## Pre-requisitos

Valide o Flutter e o Dart:

```powershell
flutter --version
dart --version
flutter doctor
```

No repositorio, instale as dependencias:

```powershell
flutter pub get
```

Para trabalhar com regras e deploy Firebase, instale tambem a Firebase CLI:

```powershell
npm install -g firebase-tools
firebase login
firebase --version
```

## Configuracao do Firebase

No Firebase Console:

1. Use o projeto `backstage-531a9` ou crie um projeto novo.
2. Em `Authentication > Sign-in method`, habilite `Email/Password`.
3. Crie o banco em `Firestore Database`.
4. Publique as regras deste repositorio:

```powershell
firebase deploy --only firestore:rules
```

O app usa login, cadastro, logout e recuperacao de senha por e-mail. O
Firestore armazena usuarios, perfis, agenda, interesses, oportunidades,
musicos e conversas.

Para regenerar as configuracoes nativas depois de trocar o projeto Firebase:

```powershell
dart pub global activate flutterfire_cli
flutterfire configure --project=backstage-531a9 --platforms=android,ios
```

Confirme o package Android `com.backstage.app`. No iOS, o Bundle ID registrado
no Firebase precisa ser igual ao Bundle ID do projeto Xcode. O arquivo
`GoogleService-Info.plist` deve permanecer em `ios/Runner/`.

## Android Emulator no Windows

Crie e inicialize um AVD pelo Android Studio uma unica vez em `Device Manager`,
por exemplo `Pixel_6`. Depois disso, o Android Studio nao precisa ser aberto
para iniciar o emulador.

Configure as variaveis do Android SDK no usuario:

```powershell
$sdk = "$env:LOCALAPPDATA\Android\Sdk"
[Environment]::SetEnvironmentVariable("ANDROID_HOME", $sdk, "User")
[Environment]::SetEnvironmentVariable("ANDROID_SDK_ROOT", $sdk, "User")
```

Adicione ao `Path` do usuario somente estes diretorios:

```text
C:\Users\<seu-usuario>\AppData\Local\Android\Sdk\platform-tools
C:\Users\<seu-usuario>\AppData\Local\Android\Sdk\emulator
```

Ou execute este comando uma vez para adiciona-los automaticamente sem
duplicar entradas existentes:

```powershell
$sdk = "$env:LOCALAPPDATA\Android\Sdk"
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
$entries = $userPath -split ";" | Where-Object { $_ }
$entries += "$sdk\platform-tools"
$entries += "$sdk\emulator"
[Environment]::SetEnvironmentVariable(
  "Path",
  ($entries | Select-Object -Unique) -join ";",
  "User"
)
```

Feche e abra o PowerShell depois de alterar o `Path`. Confirme o AVD:

```powershell
emulator -list-avds
adb devices
flutter devices
```

### Execucao rapida do projeto

**Para iniciar seu emulador:**

```powershell
emulator -avd Pixel_6
```

**Em outro terminal:**

```powershell
flutter run
```

Para selecionar explicitamente o emulador:

```powershell
flutter run -d emulator-5554
```

O `google-services.json` configura o Firebase Android. Nao e necessario
passar `--dart-define` para executar o app Android configurado.

## iOS

O simulador iOS requer macOS e Xcode; ele nao pode ser executado nativamente
no Windows.

Em um Mac:

```bash
open -a Simulator
flutter doctor
flutter devices
flutter run -d <id-do-simulador>
```

Instale as dependencias iOS quando necessario:

```bash
cd ios
pod install
cd ..
```

O Firebase iOS usa `ios/Runner/GoogleService-Info.plist` e a configuracao Dart
compartilhada. O Bundle ID precisa estar registrado como aplicativo iOS no
Firebase.

## Primeiro teste funcional

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

## Colecoes do Firestore

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

## Regras de seguranca

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

## Web e Firebase Hosting (opcional)

O Hosting permanece configurado para `build/web`, mas o projeto atualmente nao
tem um aplicativo Web Firebase como alvo principal. Para usar Firebase real no
Chrome, registre um app Web no Console e configure `FIREBASE_WEB_API_KEY` e
`FIREBASE_WEB_APP_ID` por `--dart-define`. Sem isso, o Chrome usa o fallback
local/mock e nao testa a configuracao Android ou iOS.

Para gerar um build Web sem Firebase real:

```powershell
flutter build web
```

O build final sera gerado em:

```text
build/web
```

O `firebase.json` ja aponta o Hosting para esse diretorio.

## Deploy no Firebase Hosting

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

## Validacao antes de publicar

Rode:

```powershell
flutter analyze
flutter build apk --debug
flutter build web
```

Para validar Firebase real, prefira executar o build Android em um emulador ou
dispositivo. O build Web so usara Firebase real depois que um app Web for
registrado e os defines Web forem fornecidos.

## Problemas comuns

### O login mostra falha de conexao no Chrome

Chrome executa o app como Web. `DevicePreview` nao muda a plataforma. Se o app
Web Firebase nao estiver configurado, `FirebaseBootstrap.isEnabled` fica falso
e o login usa o caminho mock. Teste em Android com:

```powershell
emulator -avd Pixel_6
```

Em outro terminal:

```powershell
flutter run
```

### O emulador nao e encontrado

Reabra o PowerShell depois de alterar o `Path` e confirme:

```powershell
emulator -list-avds
flutter devices
```

### App mobile usa dados mocados

Verifique se o emulador Android esta realmente conectado e se o app foi
executado com `flutter run -d emulator-5554`. Confirme tambem se o
`android/app/google-services.json` pertence ao projeto Firebase correto.

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
