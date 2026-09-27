import 'package:backstage/providers/auth_provider.dart';
import 'package:flutter_test/flutter_test.dart';

// Modo mock: cada operação espera 1s (Future.delayed) antes de responder.
void main() {
  late AuthProvider provider;

  setUp(() => provider = AuthProvider());
  tearDown(() => provider.dispose());

  test('inicia deslogado', () {
    expect(provider.isLoggedIn, isFalse);
    expect(provider.isLoading, isFalse);
    expect(provider.userId, isNull);
  });

  test('login falha de propósito sem Firebase e expõe mensagem de erro', () async {
    final resultado = provider.login(email: 'a@b.com', senha: '123456');

    expect(provider.isLoading, isTrue);
    expect(await resultado, isFalse);
    expect(provider.isLoading, isFalse);
    expect(provider.isLoggedIn, isFalse);
    expect(provider.errorMessage, contains('Falha na conexão'));
  });

  test('cadastrar simula sucesso e loga o usuário mock', () async {
    final ok = await provider.cadastrar(
      nome: 'Músico',
      email: 'musico@backstage.com',
      telefone: '16999999999',
      senha: '123456',
    );

    expect(ok, isTrue);
    expect(provider.isLoggedIn, isTrue);
    expect(provider.userId, 'mock-user');
    expect(provider.userEmail, 'musico@backstage.com');
    expect(provider.errorMessage, isNull);
  });

  test('precisaCompletarPerfil nunca bloqueia navegação sem Firebase', () async {
    await provider.cadastrar(
      nome: 'Músico',
      email: 'musico@backstage.com',
      telefone: '16999999999',
      senha: '123456',
    );

    expect(await provider.precisaCompletarPerfil(), isFalse);
  });

  test('recuperarSenha simula sucesso', () async {
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
