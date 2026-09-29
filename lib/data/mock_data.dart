import '../models/conversa.dart';
import '../models/mensagem.dart';
import '../models/musico.dart';
import '../models/oportunidade.dart';

class MockData {
  /// Uid usado pelo `AuthProvider` no cadastro simulado.
  static const usuarioMockId = 'mock-user';

  static List<Musico> musicos = [
    Musico(
      id: '1',
      nomeArtistico: 'Banda Eclipse',
      generoMusical: 'Rock',
      cidade: 'Ribeirão Preto',
      descricao: 'Banda de rock para bares e eventos.',
      cacheMedio: 1200,
      portfolioLinks: ['instagram.com/bandaeclipse'],
      datasDisponiveis: ['2026-03-20', '2026-03-25'],
    ),
    Musico(
      id: '2',
      nomeArtistico: 'Duo Acústico Sol',
      generoMusical: 'MPB',
      cidade: 'Franca',
      descricao: 'Duo para eventos intimistas e restaurantes.',
      cacheMedio: 800,
      portfolioLinks: ['youtube.com/duosol'],
      datasDisponiveis: ['2026-03-18', '2026-03-22'],
    ),
  ];

  static List<Oportunidade> oportunidades = [
    Oportunidade(
      id: '1',
      titulo: 'Vaga para voz e violão',
      descricao: 'Apresentação em bar no sábado à noite.',
      cidade: 'Ribeirão Preto',
      generoMusical: 'MPB',
      dataEvento: DateTime(2026, 3, 21),
      cacheOferecido: 900,
      contratante: 'Bar Central',
      donoId: 'mock-estabelecimento-1',
      logradouro: 'Rua Barão do Amazonas',
      numero: '520',
      estado: 'SP',
      cep: '14010-120',
    ),
    Oportunidade(
      id: '2',
      titulo: 'Banda pop/rock para sexta',
      descricao: 'Show ao vivo em pub com repertório animado.',
      cidade: 'Sertãozinho',
      generoMusical: 'Rock',
      dataEvento: DateTime(2026, 3, 27),
      cacheOferecido: 1500,
      contratante: 'Pub Groove',
      donoId: 'mock-estabelecimento-2',
      logradouro: 'Avenida Getúlio Vargas',
      numero: '1100',
      estado: 'SP',
      cep: '14174-000',
    ),
  ];

  static List<Conversa> conversas = [
    Conversa(
      id: '1',
      participantes: [usuarioMockId, 'mock-estabelecimento-1'],
      nomes: {usuarioMockId: 'Você', 'mock-estabelecimento-1': 'Bar Central'},
      mensagens: [
        Mensagem(
          id: '1',
          remetenteId: 'mock-estabelecimento-1',
          texto: 'Olá, temos interesse no seu trabalho.',
          dataHora: DateTime.now(),
        ),
        Mensagem(
          id: '2',
          remetenteId: usuarioMockId,
          texto: 'Que ótimo! Podemos conversar sobre datas.',
          dataHora: DateTime.now(),
        ),
      ],
    ),
  ];
}
