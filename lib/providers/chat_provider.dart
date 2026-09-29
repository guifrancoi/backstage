import 'dart:async';

import 'package:flutter/material.dart';

import '../models/conversa.dart';
import '../models/mensagem.dart';
import '../services/firebase_data_service.dart';

/// Conversas do usuário logado. Uma conversa nasce quando um interesse é
/// aceito (`InteresseProvider.aceitar`); aqui só se lê e se envia mensagem.
class ChatProvider extends ChangeNotifier {
  ChatProvider({FirebaseDataService? service})
    : _service = service ?? FirebaseDataService() {
    _authSubscription = _service.authUserIds.listen(_escutar);
  }

  final FirebaseDataService _service;
  StreamSubscription<String?>? _authSubscription;
  StreamSubscription<List<Conversa>>? _conversasSubscription;

  List<Conversa> _conversas = [];
  String? _uid;

  /// Mais recentes primeiro.
  List<Conversa> get conversas {
    final lista = [..._conversas];
    lista.sort((a, b) {
      final dataA = a.atualizadoEm ?? DateTime(0);
      final dataB = b.atualizadoEm ?? DateTime(0);
      return dataB.compareTo(dataA);
    });
    return lista;
  }

  String? get meuUid => _uid;

  void _escutar(String? uid) {
    _conversasSubscription?.cancel();
    _uid = uid;
    _conversas = [];
    notifyListeners();
    if (uid == null) return;

    _conversasSubscription = _service.streamConversas(uid).listen((lista) {
      _conversas = lista;
      notifyListeners();
    });
  }

  /// Mensagens do outro participante que eu ainda não vi nesta conversa.
  int naoLidas(Conversa conversa) => conversa.naoLidas(_uid);

  /// Soma de todas as conversas (selo da Home).
  int get totalNaoLidas =>
      _conversas.fold(0, (total, c) => total + c.naoLidas(_uid));

  /// Conversas com gravação de leitura em andamento: evita repetir a escrita
  /// enquanto o stream não traz o `lidaEm` novo.
  final Set<String> _marcando = {};

  /// Registra a leitura, só se houver não lidas (a tela chama a cada build).
  Future<void> marcarComoLida(String conversaId) async {
    final uid = _uid;
    final conversa = buscarConversaPorId(conversaId);
    if (uid == null ||
        conversa == null ||
        conversa.naoLidas(uid) == 0 ||
        !_marcando.add(conversaId)) {
      return;
    }
    try {
      await _service.marcarConversaLida(conversaId, uid);
    } catch (_) {
      // Sem registro, o selo só continua aceso; não atrapalha a conversa.
    } finally {
      _marcando.remove(conversaId);
    }
  }

  Conversa? buscarConversaPorId(String id) {
    for (final conversa in _conversas) {
      if (conversa.id == id) return conversa;
    }
    return null;
  }

  Future<void> enviarMensagem(String conversaId, String texto) async {
    final remetenteId = meuUid;
    final conversa = buscarConversaPorId(conversaId);
    if (conversa == null || remetenteId == null) return;

    final mensagem = Mensagem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      remetenteId: remetenteId,
      texto: texto,
      dataHora: DateTime.now(),
    );

    // O stream traz a mensagem de volta; não duplica localmente.
    await _service.enviarMensagem(conversaId, mensagem);
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _conversasSubscription?.cancel();
    super.dispose();
  }
}
