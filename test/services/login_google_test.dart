import 'package:backstage/models/usuario.dart';
import 'package:backstage/providers/auth_provider.dart';
import 'package:backstage/services/conta_google.dart';
import 'package:backstage/services/firebase_data_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../helpers/conta_google_falsa.dart';

/// Usuário do Google: nome e e-mail vêm da conta, e o provedor é google.com.
MockUser _usuarioGoogle() => MockUser(
  uid: 'g1',
  email: 'ana@gmail.com',
  displayName: 'Ana Vieira',
  providerData: [
    UserInfo.fromJson({
      'uid': 'g1',
      'providerId': 'google.com',
      'isAnonymous': false,
      'isEmailVerified': true,
    }),
  ],
);

FirebaseDataService _servico(
  FakeFirebaseFirestore firestore,
  ContaGoogle google,
) => FirebaseDataService(
  auth: MockFirebaseAuth(mockUser: _usuarioGoogle()),
  firestore: firestore,
  google: google,
);

void main() {
  late FakeFirebaseFirestore firestore;

  setUp(() => firestore = FakeFirebaseFirestore());

  group('FirebaseDataService.entrarComGoogle', () {
    test(
      '1º acesso cria o usuário com nome e e-mail, sem tipo nem telefone',
      () async {
        final credential = await _servico(
          firestore,
          ContaGoogleFalsa(),
        ).entrarComGoogle();

        expect(credential?.user?.uid, 'g1');
        final dados = (await firestore.collection('usuarios').doc('g1').get())
            .data();
        expect(dados?['nome'], 'Ana Vieira');
        expect(dados?['email'], 'ana@gmail.com');
        expect(dados?['telefone'], '');
        expect(dados?.containsKey('tipoUsuario'), isFalse);
      },
    );

    test('acesso seguinte não mexe no cadastro que já existe', () async {
      await firestore.collection('usuarios').doc('g1').set({
        'nome': 'Ana (banda)',
        'email': 'ana@gmail.com',
        'telefone': '16999990000',
        'tipoUsuario': 'musico',
      });

      await _servico(firestore, ContaGoogleFalsa()).entrarComGoogle();

      final dados = (await firestore.collection('usuarios').doc('g1').get())
          .data();
      expect(dados?['nome'], 'Ana (banda)');
      expect(dados?['telefone'], '16999990000');
      expect(dados?['tipoUsuario'], 'musico');
    });

    test('fechar a escolha de conta não entra nem cria nada', () async {
      final servico = _servico(firestore, ContaGoogleFalsa(token: null));

      expect(await servico.entrarComGoogle(), isNull);
      expect(servico.currentUserId, isNull);
      expect(
        (await firestore.collection('usuarios').doc('g1').get()).exists,
        isFalse,
      );
    });

    test(
      'logout de quem entrou pelo Google esquece a conta escolhida',
      () async {
        final google = ContaGoogleFalsa();
        final servico = _servico(firestore, google);
        await servico.entrarComGoogle();

        await servico.logout();

        expect(servico.currentUserId, isNull);
        expect(google.saidas, 1);
      },
    );
  });

  group('AuthProvider.entrarComGoogle', () {
    test('entra e pede o onboarding com telefone no 1º acesso', () async {
      final auth = AuthProvider(
        service: _servico(firestore, ContaGoogleFalsa()),
      );
      addTearDown(auth.dispose);

      expect(await auth.entrarComGoogle(), isTrue);
      expect(auth.isLoggedIn, isTrue);
      expect(auth.userId, 'g1');
      expect(await auth.precisaCompletarPerfil(), isTrue);
      expect(auth.precisaTelefone, isTrue);

      // O passo 1 grava o tipo e o telefone juntos.
      expect(
        await auth.completarCadastro(
          TipoUsuario.musico,
          telefone: '16999990000',
        ),
        isTrue,
      );
      expect(auth.precisaTelefone, isFalse);
      final dados = (await firestore.collection('usuarios').doc('g1').get())
          .data();
      expect(dados?['telefone'], '16999990000');
      expect(dados?['tipoUsuario'], 'musico');
    });

    test('desistir não é erro: sem mensagem e deslogado', () async {
      final auth = AuthProvider(
        service: _servico(firestore, ContaGoogleFalsa(token: null)),
      );
      addTearDown(auth.dispose);

      expect(await auth.entrarComGoogle(), isFalse);
      expect(auth.isLoggedIn, isFalse);
      expect(auth.errorMessage, isNull);
      expect(auth.isLoading, isFalse);
      expect(auth.entrandoComGoogle, isFalse);
    });

    test('falha do Google vira mensagem em português', () async {
      final auth = AuthProvider(
        service: _servico(
          firestore,
          ContaGoogleFalsa(
            erro: const GoogleSignInException(
              code: GoogleSignInExceptionCode.clientConfigurationError,
            ),
          ),
        ),
      );
      addTearDown(auth.dispose);

      expect(await auth.entrarComGoogle(), isFalse);
      expect(
        auth.errorMessage,
        'Não foi possível entrar com o Google. Tente novamente.',
      );
    });
  });
}
