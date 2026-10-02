import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/avaliacao.dart';
import '../models/contratacao.dart';
import '../models/notificacao.dart';
import '../services/firebase_data_service.dart';

/// Avaliações pós-show (Plano 17): todas as avaliações (leitura pública),
/// para mostrar a média de qualquer pessoa, e o envio da avaliação do
/// usuário logado, que avisa a outra parte.
class AvaliacaoProvider extends ChangeNotifier {
  AvaliacaoProvider({FirebaseDataService? service})
    : _service = service ?? FirebaseDataService() {
    _authSubscription = _service.authUserIds.listen(_escutar);
  }

  final FirebaseDataService _service;
  StreamSubscription<String?>? _authSubscription;
  StreamSubscription<List<Avaliacao>>? _avaliacoesSubscription;

  List<Avaliacao> _todas = [];
  String? _uid;
  String? _errorMessage;

  String? get errorMessage => _errorMessage;

  /// Como o catálogo, reassina a cada troca de conta (o listener morre no
  /// logout, porque as regras exigem login).
  void _escutar(String? uid) {
    _avaliacoesSubscription?.cancel();
    _uid = uid;
    _todas = [];
    notifyListeners();
    if (uid == null) return;

    _avaliacoesSubscription = _service.streamAvaliacoes().listen((lista) {
      _todas = lista;
      notifyListeners();
    }, onError: (_) {});
  }

  /// Média e quantidade das avaliações recebidas por [uid].
  ResumoAvaliacoes resumoDe(String uid) =>
      ResumoAvaliacoes.de(_todas.where((a) => a.avaliadoId == uid));

  /// Avaliações recebidas por [uid], mais recentes primeiro.
  List<Avaliacao> recebidasPor(String uid, {int? limite}) {
    final lista = _todas.where((a) => a.avaliadoId == uid).toList()
      ..sort((a, b) => b.criadaEm.compareTo(a.criadaEm));
    return limite == null ? lista : lista.take(limite).toList();
  }

  /// A avaliação que o usuário logado fez desse show, se fez.
  Avaliacao? minhaAvaliacao(String contratacaoId) {
    for (final a in _todas) {
      if (a.contratacaoId == contratacaoId && a.autorId == _uid) return a;
    }
    return null;
  }

  /// Shows do usuário logado com avaliação pendente e dentro do prazo
  /// (aviso da Home e botão "Avaliar").
  List<Contratacao> paraAvaliar(Iterable<Contratacao> contratacoes) {
    final agora = DateTime.now();
    return [
      for (final c in contratacoes)
        if ((c.musicoId == _uid || c.donoId == _uid) &&
            c.podeAvaliarEm(agora) &&
            minhaAvaliacao(c.id) == null)
          c,
    ];
  }

  /// Avalia a outra parte do show e avisa (convidando a avaliar também, se
  /// ela ainda não avaliou). Devolve se gravou.
  Future<bool> avaliar(
    Contratacao contratacao, {
    required int nota,
    required String comentario,
  }) async {
    final uid = _uid;
    if (uid == null) return false;
    final souMusico = uid == contratacao.musicoId;
    final avaliacao = Avaliacao(
      contratacaoId: contratacao.id,
      autorId: uid,
      autorNome: souMusico ? contratacao.musicoNome : contratacao.donoNome,
      avaliadoId: souMusico ? contratacao.donoId : contratacao.musicoId,
      nota: nota,
      comentario: comentario.trim(),
      criadaEm: DateTime.now(),
    );

    _errorMessage = null;
    try {
      await _service.avaliar(avaliacao);
    } on FirebaseException catch (error) {
      _errorMessage = error.code == 'permission-denied'
          ? 'Não foi possível avaliar: o prazo terminou ou o show já foi '
                'avaliado.'
          : 'Não foi possível enviar a avaliação. Tente novamente.';
      notifyListeners();
      return false;
    }

    final outraParteJaAvaliou = _todas.any(
      (a) =>
          a.contratacaoId == contratacao.id && a.autorId == avaliacao.avaliadoId,
    );
    await _service.tentarNotificar([
      Notificacao.avaliacaoRecebida(
        contratacao,
        autorId: uid,
        nota: nota,
        outraParteJaAvaliou: outraParteJaAvaliou,
      ),
    ]);
    return true;
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _avaliacoesSubscription?.cancel();
    super.dispose();
  }
}
