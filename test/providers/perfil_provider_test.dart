import 'package:backstage/providers/perfil_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late PerfilProvider provider;

  setUp(() => provider = PerfilProvider());
  tearDown(() => provider.dispose());

  test('não carrega perfil automaticamente no modo mock', () {
    expect(provider.perfilMusico, isNull);
    expect(provider.isLoading, isFalse);
  });

  test('carregarPerfil cria o perfil inicial do usuário mock', () async {
    await provider.carregarPerfil();

    expect(provider.perfilMusico?.id, 'mock-user');
    expect(provider.perfilMusico?.nomeArtistico, isNotEmpty);
    expect(provider.isLoading, isFalse);
  });

  test('atualizarPerfil substitui os campos editáveis', () async {
    await provider.carregarPerfil();

    await provider.atualizarPerfil(
      nomeArtistico: 'Novo Nome',
      generoMusical: 'Jazz',
      cidade: 'Franca',
      cacheMedio: 2500,
      descricao: 'Nova descrição',
      portfolioLinks: ['https://exemplo.com'],
      fotoPath: '/foto.jpg',
    );

    final perfil = provider.perfilMusico!;
    expect(perfil.id, 'mock-user');
    expect(perfil.nomeArtistico, 'Novo Nome');
    expect(perfil.generoMusical, 'Jazz');
    expect(perfil.cidade, 'Franca');
    expect(perfil.cacheMedio, 2500);
    expect(perfil.portfolioLinks, ['https://exemplo.com']);
    expect(perfil.fotoPath, '/foto.jpg');
  });

  test('atualizarPerfil sem perfil carregado não faz nada', () async {
    await provider.atualizarPerfil(
      nomeArtistico: 'X',
      generoMusical: 'Rock',
      cidade: 'Y',
      cacheMedio: 1,
      descricao: 'Z',
      portfolioLinks: const [],
    );

    expect(provider.perfilMusico, isNull);
  });
}
