import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/denuncia.dart';
import '../services/firebase_data_service.dart';

/// Denúncias (Plano 22): qualquer usuário envia; a conta admin acompanha a
/// lista e marca como analisada (as regras só deixam o admin ler).
class DenunciaProvider extends ChangeNotifier {
  DenunciaProvider({FirebaseDataService? service})
    : _service = service ?? FirebaseDataService() {
    _authSubscription = _service.authUserIds.listen(_escutar);
  }

  final FirebaseDataService _service;
  StreamSubscription<String?>? _authSubscription;
  StreamSubscription<List<Denuncia>>? _denunciasSubscription;

  List<Denuncia> _denuncias = [];
  String? _errorMessage;

  /// Só para o admin; mais recentes primeiro.
  List<Denuncia> get denuncias => _denuncias;
  int get pendentes => _denuncias.where((d) => !d.analisada).length;
  String? get errorMessage => _errorMessage;

  void _escutar(String? uid) {
    _denunciasSubscription?.cancel();
    _denunciasSubscription = null;
    _denuncias = [];
    notifyListeners();
    if (uid == null) return;

    // Só o admin lê a coleção; para os outros nem assina.
    _service.ehAdmin().then((admin) {
      if (!admin || _service.currentUserId != uid) return;
      _denunciasSubscription = _service.streamDenuncias().listen((lista) {
        _denuncias = [...lista]
          ..sort((a, b) => b.criadaEm.compareTo(a.criadaEm));
        notifyListeners();
      }, onError: (_) {});
    }, onError: (_) {});
  }

  /// Envia a denúncia do usuário logado. Devolve se gravou.
  Future<bool> denunciar({
    required String autorNome,
    required TipoAlvoDenuncia tipoAlvo,
    required String alvoId,
    required String alvoUid,
    required String descricaoAlvo,
    required MotivoDenuncia motivo,
    String texto = '',
  }) async {
    final uid = _service.currentUserId;
    if (uid == null || uid == alvoUid) return false;
    return _executar(
      () => _service.denunciar(
        Denuncia(
          autorId: uid,
          autorNome: autorNome,
          tipoAlvo: tipoAlvo,
          alvoId: alvoId,
          alvoUid: alvoUid,
          descricaoAlvo: descricaoAlvo,
          motivo: motivo,
          texto: texto.trim(),
          criadaEm: DateTime.now(),
        ),
      ),
      erro: 'Não foi possível enviar a denúncia.',
    );
  }

  Future<bool> marcarAnalisada(Denuncia denuncia) => _executar(
    () => _service.marcarDenunciaAnalisada(denuncia.id),
    erro: 'Não foi possível atualizar a denúncia.',
  );

  Future<bool> _executar(
    Future<void> Function() acao, {
    required String erro,
  }) async {
    _errorMessage = null;
    try {
      await acao();
      return true;
    } on FirebaseException {
      _errorMessage = erro;
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _denunciasSubscription?.cancel();
    super.dispose();
  }
}
