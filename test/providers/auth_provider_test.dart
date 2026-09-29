import 'package:backstage/providers/auth_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/firebase_fake.dart';

// Login, erros mapeados, onboarding e admin: providers_firebase_test.dart.
void main() {
  late AuthProvider provider;

  setUp(() => provider = AuthProvider(service: servicoFake(uid: null)));
  tearDown(() => provider.dispose());

  test('inicia deslogado sem sessão no Firebase', () {
    expect(provider.isLoggedIn, isFalse);
    expect(provider.isLoading, isFalse);
    expect(provider.userId, isNull);
  });

  test('cadastrar loga o usuário novo', () async {
    final ok = await provider.cadastrar(
      nome: 'Músico',
      email: 'musico@backstage.com',
      telefone: '16999999999',
      senha: '123456',
    );

    expect(ok, isTrue);
    expect(provider.isLoggedIn, isTrue);
    expect(provider.userId, isNotNull);
    expect(provider.userEmail, 'musico@backstage.com');
    expect(provider.errorMessage, isNull);
  });

  test('recuperarSenha retorna sucesso', () async {
    expect(await provider.recuperarSenha('a@b.com'), isTrue);
    expect(provider.isLoading, isFalse);
  });

  test('logout limpa a sessão e a mensagem de erro', () async {
    await provider.cadastrar(
      nome: 'Músico',
      email: 'musico@backstage.com',
      telefone: '16999999999',
      senha: '123456',
    );

    await provider.logout();

    expect(provider.isLoggedIn, isFalse);
    expect(provider.userId, isNull);
    expect(provider.userEmail, isNull);
    expect(provider.errorMessage, isNull);
  });
}
