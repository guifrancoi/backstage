import 'package:backstage/models/casa_show.dart';
import 'package:backstage/models/musico.dart';
import 'package:backstage/providers/perfil_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late PerfilProvider provider;

  setUp(() => provider = PerfilProvider());
  tearDown(() => provider.dispose());

  test('estado inicial sem perfis', () {
    expect(provider.perfilMusico, isNull);
    expect(provider.perfilEstabelecimento, isNull);
    expect(provider.isLoading, isFalse);
  });

  test('carregarPerfil usa um perfil de artista em branco no mock', () async {
    await provider.carregarPerfil();

    expect(provider.perfilMusico?.id, 'mock-user');
    expect(provider.perfilMusico?.completo, isFalse);
    expect(provider.isLoading, isFalse);
  });

  test('salvarPerfilMusico substitui o perfil com o id do usuário', () async {
    final ok = await provider.salvarPerfilMusico(
      Musico(
        id: '',
        nomeArtistico: 'Nova Banda',
        generoMusical: 'Jazz',
        cidade: 'Franca',
        descricao: 'Trio',
        cacheMedio: 2500,
        portfolioLinks: const ['https://exemplo.com'],
        datasDisponiveis: const [],
      ),
    );

    expect(ok, isTrue);
    final perfil = provider.perfilMusico!;
    expect(perfil.id, 'mock-user');
    expect(perfil.nomeArtistico, 'Nova Banda');
    expect(perfil.completo, isTrue);
    expect(perfil.oculto, isFalse);
  });

  test('salvarPerfilEstabelecimento guarda o perfil do dono', () async {
    final ok = await provider.salvarPerfilEstabelecimento(
      CasaShow(
        id: '',
        nome: 'Bar Central',
        cidade: 'Franca',
        logradouro: 'Rua A',
        numero: '10',
        estado: 'SP',
        capacidade: 0,
        estilosDesejados: const [],
        descricao: '',
        contato: '16 99999-9999',
        cnpj: '',
      ),
    );

    expect(ok, isTrue);
    expect(provider.perfilEstabelecimento?.id, 'mock-user');
    expect(provider.perfilEstabelecimento?.completo, isTrue);
  });
}
