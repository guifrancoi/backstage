import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/contratacao.dart';
import '../models/notificacao.dart';
import '../services/firebase_data_service.dart';

/// Filtro por situação na tela de Contratações.
enum FiltroContratacao { todas, propostas, confirmadas, encerradas }

enum OrdemContratacao {
  /// Última movimentação primeiro (padrão).
  maisRecentes,

  /// Dia do show, do mais próximo ao mais distante.
  dataDoShow,
}

/// Contratações do usuário logado: propostas que o dono fez (`enviadas`) e
/// as que o músico recebeu (`recebidas`). O dono propõe a partir de um
/// interesse aceito; o músico confirma (ocupa o dia) ou recusa.
class ContratacaoProvider extends ChangeNotifier {
  ContratacaoProvider({FirebaseDataService? service})
    : _service = service ?? FirebaseDataService() {
    _authSubscription = _service.authUserIds.listen(_escutar);
  }

  final FirebaseDataService _service;
  StreamSubscription<String?>? _authSubscription;
  StreamSubscription<List<Contratacao>>? _contratacoesSubscription;

  List<Contratacao> _contratacoes = [];
  String? _uid;
  String? _errorMessage;

  String? get errorMessage => _errorMessage;

  /// Todas as contratações em que o usuário é parte, mais recentes primeiro.
  List<Contratacao> get todas => _contratacoes;

  /// Sou o músico.
  List<Contratacao> get recebidas =>
      _contratacoes.where((c) => c.musicoId == _uid).toList();

  /// Sou o dono.
  List<Contratacao> get enviadas =>
      _contratacoes.where((c) => c.donoId == _uid).toList();

  /// O que espera a minha resposta (selo da Home): propostas recebidas
  /// (sou o músico) e contrapropostas recebidas (sou o dono, Plano 21).
  int get propostasPendentes =>
      recebidas.where((c) => c.status == StatusContratacao.proposta).length +
      enviadas
          .where((c) => c.status == StatusContratacao.contraproposta)
          .length;

  void _escutar(String? uid) {
    _contratacoesSubscription?.cancel();
    _uid = uid;
    _contratacoes = [];
    notifyListeners();
    if (uid == null) return;

    _contratacoesSubscription = _service.streamContratacoes(uid).listen((
      lista,
    ) {
      _contratacoes = lista;
      notifyListeners();
    });
  }

  /// Aplica situação, busca (título, nomes, cidade; sem diferenciar
  /// maiúsculas) e ordem sobre [lista] — `recebidas`, `enviadas` ou `todas`.
  List<Contratacao> filtrar(
    List<Contratacao> lista, {
    FiltroContratacao filtro = FiltroContratacao.todas,
    String termo = '',
    OrdemContratacao ordem = OrdemContratacao.maisRecentes,
  }) {
    final busca = termo.trim().toLowerCase();
    final resultado = lista.where((c) {
      final situacaoOk = switch (filtro) {
        FiltroContratacao.todas => true,
        FiltroContratacao.propostas => c.emNegociacao,
        FiltroContratacao.confirmadas =>
          c.status == StatusContratacao.confirmada && !c.realizada,
        FiltroContratacao.encerradas => c.encerrada,
      };
      if (!situacaoOk) return false;
      if (busca.isEmpty) return true;
      return [
        c.titulo,
        c.musicoNome,
        c.donoNome,
        c.cidade,
      ].any((campo) => campo.toLowerCase().contains(busca));
    }).toList();

    switch (ordem) {
      case OrdemContratacao.maisRecentes:
        resultado.sort((a, b) => b.atualizadoEm.compareTo(a.atualizadoEm));
      case OrdemContratacao.dataDoShow:
        resultado.sort((a, b) => a.dia.compareTo(b.dia));
    }
    return resultado;
  }

  /// Contratação ainda ativa (proposta ou confirmada) nascida do interesse.
  Contratacao? ativaParaInteresse(String interesseId) {
    for (final c in _contratacoes) {
      if (c.interesseId == interesseId && c.ativa) return c;
    }
    return null;
  }

  /// Contratações ativas no dia (para a agenda).
  List<Contratacao> doDia(DateTime data) {
    final dia = Contratacao.diaDe(data);
    return _contratacoes.where((c) => c.dia == dia && c.ativa).toList();
  }

  Future<bool> propor(Contratacao contratacao) async {
    String? id;
    final ok = await _executar(
      () async => id = await _service.proporContratacao(contratacao),
    );
    if (ok) {
      await _avisar(
        contratacao.copyWith(id: id),
        TipoNotificacao.contratacaoProposta,
      );
    }
    return ok;
  }

  Future<bool> confirmar(Contratacao contratacao) async {
    final ok = await _executar(
      () => _service.confirmarContratacao(contratacao),
      confirmando: true,
    );
    if (ok) await _avisar(contratacao, TipoNotificacao.contratacaoConfirmada);
    return ok;
  }

  /// Plano 21: o músico pede [valor] em vez do cachê proposto.
  Future<bool> contrapropor(Contratacao contratacao, double valor) async {
    final ok = await _executar(
      () => _service.contraproporContratacao(contratacao.id, valor),
    );
    if (ok) {
      await _avisar(
        contratacao.copyWith(cacheContraproposto: valor),
        TipoNotificacao.contrapropostaEnviada,
      );
    }
    return ok;
  }

  /// Plano 21: o dono aceita o valor pedido.
  Future<bool> aceitarContraproposta(Contratacao contratacao) async {
    final ok = await _executar(
      () => _service.aceitarContraproposta(contratacao),
    );
    if (ok) {
      await _avisar(
        contratacao.copyWith(cacheAcordado: contratacao.cacheContraproposto),
        TipoNotificacao.contrapropostaAceita,
      );
    }
    return ok;
  }

  /// Plano 21: o dono recusa a contraproposta — a contratação é cancelada
  /// (para outro valor, conversam e ele faz uma nova proposta).
  Future<bool> recusarContraproposta(
    Contratacao contratacao, {
    String? motivo,
  }) {
    return cancelar(
      contratacao,
      motivo: motivo,
      tipo: TipoNotificacao.contrapropostaRecusada,
    );
  }

  Future<bool> recusar(Contratacao contratacao) async {
    final ok = await _executar(
      () => _service.recusarContratacao(contratacao.id),
    );
    if (ok) await _avisar(contratacao, TipoNotificacao.contratacaoRecusada);
    return ok;
  }

  Future<bool> cancelar(
    Contratacao contratacao, {
    String? motivo,
    TipoNotificacao tipo = TipoNotificacao.contratacaoCancelada,
  }) async {
    final uid = _uid;
    if (uid == null) return false;
    final ok = await _executar(
      () => _service.cancelarContratacao(
        contratacao,
        canceladoPor: uid,
        motivo: motivo,
      ),
    );
    if (ok) {
      final texto = motivo?.trim() ?? '';
      await _avisar(
        contratacao.copyWith(
          motivoCancelamento: texto.isEmpty ? null : texto,
        ),
        tipo,
      );
    }
    return ok;
  }

  /// Avisa a outra parte (não falha: a ação já foi gravada).
  Future<void> _avisar(Contratacao contratacao, TipoNotificacao tipo) async {
    final uid = _uid;
    if (uid == null) return;
    await _service.tentarNotificar([
      Notificacao.contratacao(contratacao, tipo: tipo, autorId: uid),
    ]);
  }

  /// Grava no Firestore; o stream traz o resultado de volta.
  Future<bool> _executar(
    Future<void> Function() acao, {
    bool confirmando = false,
  }) async {
    _errorMessage = null;
    try {
      await acao();
      return true;
    } on FirebaseException catch (error) {
      _errorMessage = _mensagemErro(error, confirmando: confirmando);
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _contratacoesSubscription?.cancel();
    super.dispose();
  }
}

String _mensagemErro(FirebaseException error, {required bool confirmando}) {
  return switch (error.code) {
    // Na confirmação, a causa comum é a trava do dia já existir.
    'permission-denied' when confirmando =>
      'Você já tem um show confirmado nesse dia.',
    'permission-denied' => 'Sem permissão para essa ação.',
    'not-found' => 'Essa contratação não existe mais.',
    'unavailable' || 'deadline-exceeded' =>
      'O Firebase está indisponível. Tente novamente.',
    _ => 'Não foi possível concluir a ação.',
  };
}
