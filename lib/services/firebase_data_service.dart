import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/logging/app_logger.dart';
import '../models/agenda_publica.dart';
import '../models/avaliacao.dart';
import '../models/casa_show.dart';
import '../models/contratacao.dart';
import '../models/conversa.dart';
import '../models/denuncia.dart';
import '../models/interesse.dart';
import '../models/mensagem.dart';
import '../models/notificacao.dart';
import '../models/musico.dart';
import '../models/oportunidade.dart';
import '../models/usuario.dart';

class FirebaseDataService {
  /// [auth] e [firestore] são injetados nos testes (fakes); no app vêm das
  /// instâncias padrão, já inicializadas por `FirebaseBootstrap`.
  FirebaseDataService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth,
      _firestore = firestore;

  final FirebaseAuth? _auth;
  final FirebaseFirestore? _firestore;

  FirebaseAuth get auth => _auth ?? FirebaseAuth.instance;
  FirebaseFirestore get firestore => _firestore ?? FirebaseFirestore.instance;

  String? get currentUserId => auth.currentUser?.uid;
  String? get currentUserEmail => auth.currentUser?.email;

  /// Uid atual primeiro, depois cada troca, sem repetição: todo provider que
  /// assinar — cedo ou tarde — recebe o estado atual.
  Stream<String?> get authUserIds => _authUserIds().distinct();

  Stream<String?> _authUserIds() async* {
    yield auth.currentUser?.uid;
    yield* auth.authStateChanges().map((user) => user?.uid);
  }

  Future<UserCredential> login({required String email, required String senha}) {
    return auth.signInWithEmailAndPassword(email: email, password: senha);
  }

  Future<UserCredential> cadastrar({
    required String nome,
    required String email,
    required String telefone,
    required String senha,
  }) async {
    late final UserCredential credential;

    try {
      credential = await auth
          .createUserWithEmailAndPassword(email: email, password: senha)
          .timeout(const Duration(seconds: 15));
    } on FirebaseAuthException catch (error) {
      if (error.code != 'email-already-in-use') rethrow;

      // Retoma um cadastro interrompido somente após validar a senha.
      credential = await auth
          .signInWithEmailAndPassword(email: email, password: senha)
          .timeout(const Duration(seconds: 15));
    }

    await credential.user
        ?.updateDisplayName(nome)
        .timeout(const Duration(seconds: 15));
    await salvarUsuario(
      uid: credential.user!.uid,
      nome: nome,
      email: email,
      telefone: telefone,
    ).timeout(const Duration(seconds: 15));

    return credential;
  }

  Future<void> recuperarSenha(String email) {
    return auth.sendPasswordResetEmail(email: email);
  }

  Future<void> logout() {
    return auth.signOut();
  }

  Future<void> salvarUsuario({
    required String uid,
    required String nome,
    required String email,
    required String telefone,
    TipoUsuario? tipoUsuario,
  }) {
    return firestore.collection('usuarios').doc(uid).set({
      'nome': nome,
      'email': email,
      'telefone': telefone,
      if (tipoUsuario != null) 'tipoUsuario': tipoUsuario.name,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Uids com assinatura válida (Plano 7): documento em `assinantes/{uid}`
  /// sem `expiraEm` ou com `expiraEm` no futuro. A coleção é gravada só pelo
  /// Admin SDK (`definir-assinante.js`) e lida por qualquer autenticado —
  /// diferente de `usuarios`, que o próprio usuário escreve.
  Stream<Set<String>> streamAssinantes() {
    return firestore.collection('assinantes').snapshots().map((s) {
      final agora = DateTime.now();
      return {
        for (final d in s.docs)
          if (d.data()['expiraEm'] == null ||
              _dateTimeFromValue(d.data()['expiraEm']).isAfter(agora))
            d.id,
      };
    });
  }

  Future<void> definirTipoUsuario(String uid, TipoUsuario tipoUsuario) {
    return firestore.collection('usuarios').doc(uid).set({
      'tipoUsuario': tipoUsuario.name,
    }, SetOptions(merge: true));
  }

  Future<Usuario?> carregarUsuario(String uid) async {
    final doc = await firestore.collection('usuarios').doc(uid).get();
    final data = doc.data();
    if (data == null) return null;

    return Usuario.fromMap(doc.id, data);
  }

  /// Perfil do estabelecimento (Plano 16). Contato e CNPJ vêm do documento
  /// `privado/dados`, que as regras só deixam o dono e quem já conversa com
  /// ele ler; sem permissão eles voltam vazios (não é erro).
  Future<CasaShow?> carregarEstabelecimento(String usuarioId) async {
    final ref = firestore.collection('estabelecimentos').doc(usuarioId);
    final doc = await ref.get();
    final data = doc.data();
    if (data == null) return null;

    Map<String, dynamic>? privado;
    try {
      privado = (await ref.collection('privado').doc('dados').get()).data();
    } on FirebaseException catch (erro) {
      if (erro.code != 'permission-denied') rethrow;
    }
    return CasaShow.fromMap(doc.id, data, privado: privado);
  }

  /// Grava a parte pública e a privada no mesmo batch. Apaga do documento
  /// público o contato/CNPJ de antes do Plano 16 (as regras recusam o
  /// documento público com essas chaves).
  Future<void> salvarEstabelecimento(String usuarioId, CasaShow perfil) {
    final ref = firestore.collection('estabelecimentos').doc(usuarioId);
    return (firestore.batch()
          ..set(ref, {
            ...perfil.toMap(),
            'contato': FieldValue.delete(),
            'cnpj': FieldValue.delete(),
          }, SetOptions(merge: true))
          ..set(ref.collection('privado').doc('dados'), perfil.toMapPrivado()))
        .commit();
  }

  Stream<List<Musico>> streamMusicos() {
    return firestore
        .collection('perfis_musicos')
        .snapshots()
        .map((s) => s.docs.map((d) => Musico.fromMap(d.id, d.data())).toList());
  }

  Stream<List<Oportunidade>> streamOportunidades() {
    return firestore
        .collection('oportunidades')
        .snapshots()
        .map(
          (s) =>
              s.docs.map((d) => Oportunidade.fromMap(d.id, d.data())).toList(),
        );
  }

  /// Admin é uma *custom claim* do Firebase Auth, aplicada só pelo script
  /// `definir-admin.js` (Admin SDK) — nunca um campo que o usuário grave.
  /// `true` força renovar o token para enxergar uma claim recém-aplicada.
  Future<bool> ehAdmin() async {
    final user = auth.currentUser;
    if (user == null) return false;
    final token = await user.getIdTokenResult(true);
    return token.claims?['admin'] == true;
  }

  Future<void> atualizarOportunidade(Oportunidade oportunidade) {
    return firestore
        .collection('oportunidades')
        .doc(oportunidade.id)
        .set(oportunidade.toMap());
  }

  Future<void> removerOportunidade(String oportunidadeId) {
    return firestore.collection('oportunidades').doc(oportunidadeId).delete();
  }

  /// Grava com id automático e devolve o id criado.
  Future<String> criarOportunidade(Oportunidade oportunidade) async {
    final ref = await firestore
        .collection('oportunidades')
        .add(oportunidade.toMap());
    return ref.id;
  }

  Stream<List<Interesse>> streamInteressesEnviados(String uid) =>
      _streamInteresses('remetenteId', uid);

  Stream<List<Interesse>> streamInteressesRecebidos(String uid) =>
      _streamInteresses('destinatarioId', uid);

  Stream<List<Interesse>> _streamInteresses(String campo, String uid) {
    return firestore
        .collection('interesses')
        .where(campo, isEqualTo: uid)
        .snapshots()
        .map(
          (s) => s.docs.map((d) => Interesse.fromMap(d.id, d.data())).toList(),
        );
  }

  Future<void> enviarInteresse(Interesse interesse) {
    return firestore
        .collection('interesses')
        .doc(interesse.id)
        .set(interesse.toMap());
  }

  Future<void> cancelarInteresse(String interesseId) {
    return firestore.collection('interesses').doc(interesseId).delete();
  }

  Future<void> recusarInteresse(String interesseId) {
    return firestore.collection('interesses').doc(interesseId).update({
      'status': StatusInteresse.recusado.name,
      'respondidoEm': DateTime.now(),
    });
  }

  /// Aceita o interesse e, no mesmo batch, registra-o na conversa do par
  /// (`Conversa.idPar`): cria a conversa se for a primeira vez ou reaproveita
  /// a existente, com uma mensagem de sistema ("Convite para X aceito").
  /// Devolve o id da conversa.
  Future<String> aceitarInteresse(
    Interesse interesse, {
    required String nomeDestinatario,
  }) async {
    final agora = DateTime.now();
    final aviso = Mensagem(
      id: 'sistema_${interesse.id}_${agora.millisecondsSinceEpoch}',
      remetenteId: interesse.destinatarioId,
      texto: Conversa.textoAceite(interesse),
      dataHora: agora,
      sistema: true,
    );

    final batch = firestore.batch();
    final conversaId = _registrarNaConversa(
      batch,
      interesse,
      nomes: {
        interesse.remetenteId: interesse.remetenteNome,
        interesse.destinatarioId: nomeDestinatario,
      },
      aviso: aviso,
    );
    batch.update(firestore.collection('interesses').doc(interesse.id), {
      'status': StatusInteresse.aceito.name,
      'respondidoEm': agora,
      'conversaId': conversaId,
    });
    await batch.commit();
    return conversaId;
  }

  /// Garante a conversa do par de um interesse **já aceito** (ex.: conversa
  /// apagada) e devolve o id. Só grava o nome de quem chama ([meuUid]).
  Future<String> garantirConversa(
    Interesse interesse, {
    required String meuUid,
    required String meuNome,
  }) async {
    final batch = firestore.batch();
    final conversaId = _registrarNaConversa(
      batch,
      interesse,
      nomes: {meuUid: meuNome},
    );
    await batch.commit();
    return conversaId;
  }

  /// `set` com merge na conversa do par: cria ou atualiza sem perder as
  /// mensagens. `interesseId` (o último) é o que as regras conferem na criação.
  String _registrarNaConversa(
    WriteBatch batch,
    Interesse interesse, {
    required Map<String, String> nomes,
    Mensagem? aviso,
  }) {
    final conversaId = Conversa.idPar(
      interesse.remetenteId,
      interesse.destinatarioId,
    );
    batch.set(firestore.collection('conversas').doc(conversaId), {
      'participantes': Conversa.participantesDoPar(
        interesse.remetenteId,
        interesse.destinatarioId,
      ),
      'nomes': nomes,
      'interesseId': interesse.id,
      'interesseIds': FieldValue.arrayUnion([interesse.id]),
      if (aviso != null) 'mensagens': FieldValue.arrayUnion([aviso.toMap()]),
      if (aviso != null) 'atualizadoEm': aviso.dataHora,
    }, SetOptions(merge: true));
    return conversaId;
  }

  Future<Musico?> carregarPerfilMusico(String usuarioId) async {
    final doc = await firestore
        .collection('perfis_musicos')
        .doc(usuarioId)
        .get();
    final data = doc.data();
    if (data == null) return null;

    return Musico.fromMap(doc.id, data);
  }

  Future<void> salvarPerfilMusico(String usuarioId, Musico perfil) {
    return firestore
        .collection('perfis_musicos')
        .doc(usuarioId)
        .set(perfil.toMap(), SetOptions(merge: true));
  }

  /// Dias que o músico bloqueou na agenda (todo dia é livre por padrão).
  Future<List<DateTime>> listarDiasBloqueados(String usuarioId) async {
    final snapshot = await firestore
        .collection('bloqueios')
        .where('usuarioId', isEqualTo: usuarioId)
        .get();

    final datas =
        snapshot.docs
            .map((doc) => _dateTimeFromValue(doc.data()['data']))
            .toList()
          ..sort();

    return datas;
  }

  Future<void> bloquearDia(String usuarioId, DateTime data) {
    return firestore
        .collection('bloqueios')
        .doc(_bloqueioId(usuarioId, data))
        .set({
          'usuarioId': usuarioId,
          'data': DateTime(data.year, data.month, data.day),
          // Texto `yyyy-MM-dd`, igual em qualquer fuso: chave da busca de
          // músicos livres no dia (Plano 13).
          'dia': Contratacao.diaDe(data),
        });
  }

  Future<void> desbloquearDia(String usuarioId, DateTime data) {
    return firestore
        .collection('bloqueios')
        .doc(_bloqueioId(usuarioId, data))
        .delete();
  }

  // ---------------------------------------------------------------------------
  // Contratações (Plano 9B)
  // ---------------------------------------------------------------------------

  /// Contratações em que [uid] é o músico ou o dono, mais recentes primeiro.
  Stream<List<Contratacao>> streamContratacoes(String uid) {
    Stream<List<Contratacao>> por(String campo) => firestore
        .collection('contratacoes')
        .where(campo, isEqualTo: uid)
        .snapshots()
        .map(
          (s) =>
              s.docs.map((d) => Contratacao.fromMap(d.id, d.data())).toList(),
        );

    return _combinar(por('musicoId'), por('donoId'), (comoMusico, comoDono) {
      final porId = {
        for (final c in [...comoMusico, ...comoDono]) c.id: c,
      };
      return porId.values.toList()
        ..sort((a, b) => b.criadoEm.compareTo(a.criadoEm));
    });
  }

  /// Grava a proposta do dono (id automático). Devolve o id.
  Future<String> proporContratacao(Contratacao contratacao) async {
    final ref = await firestore
        .collection('contratacoes')
        .add(contratacao.copyWith(status: StatusContratacao.proposta).toMap());
    return ref.id;
  }

  /// Músico confirma: status + trava do dia no mesmo batch. Se o dia já tem
  /// outro show confirmado, a trava já existe e as regras recusam o batch.
  Future<void> confirmarContratacao(Contratacao contratacao) {
    final batch = firestore.batch();
    batch.update(firestore.collection('contratacoes').doc(contratacao.id), {
      'status': StatusContratacao.confirmada.name,
      'respondidoEm': DateTime.now(),
    });
    batch.set(
      firestore
          .collection('ocupacoes')
          .doc(Contratacao.idOcupacao(contratacao.musicoId, contratacao.dia)),
      {
        'musicoId': contratacao.musicoId,
        'dia': contratacao.dia,
        'contratacaoId': contratacao.id,
      },
    );
    return batch.commit();
  }

  /// Plano 21: o músico pede outro cachê (uma vez só; as regras conferem).
  Future<void> contraproporContratacao(String contratacaoId, double valor) {
    return firestore.collection('contratacoes').doc(contratacaoId).update({
      'status': StatusContratacao.contraproposta.name,
      'cacheContraproposto': valor,
      'houveContraproposta': true,
      'respondidoEm': DateTime.now(),
    });
  }

  /// Plano 21: o dono aceita o valor do músico; volta a ser proposta, agora
  /// com esse cachê, e o músico confirma normalmente.
  Future<void> aceitarContraproposta(Contratacao contratacao) {
    return firestore.collection('contratacoes').doc(contratacao.id).update({
      'status': StatusContratacao.proposta.name,
      'cacheAcordado': contratacao.cacheContraproposto,
      'respondidoEm': DateTime.now(),
    });
  }

  Future<void> recusarContratacao(String contratacaoId) {
    return firestore.collection('contratacoes').doc(contratacaoId).update({
      'status': StatusContratacao.recusada.name,
      'respondidoEm': DateTime.now(),
    });
  }

  /// Dono retira a proposta, ou qualquer parte desfaz a confirmada. Se estava
  /// confirmada, apaga a trava do dia no mesmo batch (libera a data).
  Future<void> cancelarContratacao(
    Contratacao contratacao, {
    required String canceladoPor,
    String? motivo,
  }) {
    final batch = firestore.batch();
    batch.update(firestore.collection('contratacoes').doc(contratacao.id), {
      'status': StatusContratacao.cancelada.name,
      'canceladoEm': DateTime.now(),
      'canceladoPor': canceladoPor,
      if (motivo != null && motivo.trim().isNotEmpty)
        'motivoCancelamento': motivo.trim(),
    });
    if (contratacao.status == StatusContratacao.confirmada) {
      batch.delete(
        firestore
            .collection('ocupacoes')
            .doc(Contratacao.idOcupacao(contratacao.musicoId, contratacao.dia)),
      );
    }
    return batch.commit();
  }

  /// Dias bloqueados e ocupados de [musicoId] (leitura pública); os demais
  /// são livres.
  Stream<AgendaPublica> streamAgendaPublica(String musicoId) {
    Stream<Set<String>> dias(
      String colecao,
      String campoUsuario,
      String Function(Map<String, dynamic>) dia,
    ) => firestore
        .collection(colecao)
        .where(campoUsuario, isEqualTo: musicoId)
        .snapshots()
        .map((s) => {for (final d in s.docs) dia(d.data())});

    return _combinar(
      dias(
        'bloqueios',
        'usuarioId',
        (d) => Contratacao.diaDe(_dateTimeFromValue(d['data'])),
      ),
      dias('ocupacoes', 'musicoId', (d) => d['dia'] as String? ?? ''),
      (bloqueados, ocupados) =>
          AgendaPublica(bloqueados: bloqueados, ocupados: ocupados),
    );
  }

  /// Uids dos músicos que **não** estão livres no [dia] (`yyyy-MM-dd`):
  /// bloquearam o dia ou já têm show confirmado nele (Plano 13). Duas
  /// consultas por igualdade (índice automático), leitura aberta a
  /// autenticados.
  Stream<Set<String>> streamIndisponiveisNoDia(String dia) {
    Stream<Set<String>> uids(String colecao, String campoUsuario) => firestore
        .collection(colecao)
        .where('dia', isEqualTo: dia)
        .snapshots()
        .map(
          (s) => {
            for (final d in s.docs)
              if (d.data()[campoUsuario] case final String uid) uid,
          },
        );

    return _combinar(
      uids('bloqueios', 'usuarioId'),
      uids('ocupacoes', 'musicoId'),
      (bloqueados, ocupados) => {...bloqueados, ...ocupados},
    );
  }

  // ---------------------------------------------------------------------------
  // Bloqueio e denúncia (Plano 22)
  // ---------------------------------------------------------------------------

  CollectionReference<Map<String, dynamic>> _bloqueados(String uid) =>
      firestore.collection('usuarios').doc(uid).collection('bloqueados');

  /// Quem [uid] bloqueou (lista privada do dono).
  Stream<List<UsuarioBloqueado>> streamBloqueados(String uid) {
    return _bloqueados(uid).snapshots().map(
      (s) => s.docs
          .map((d) => UsuarioBloqueado.fromMap(d.id, d.data()))
          .toList(),
    );
  }

  Future<void> bloquearUsuario(String uid, UsuarioBloqueado bloqueado) {
    return _bloqueados(uid).doc(bloqueado.uid).set(bloqueado.toMap());
  }

  Future<void> desbloquearUsuario(String uid, String outroUid) {
    return _bloqueados(uid).doc(outroUid).delete();
  }

  /// Encerra o que está pendente entre [uid] e [outroUid] (Plano 22):
  /// interesses pendentes (recebidos → recusados; enviados → cancelados) e
  /// contratações em negociação (o músico recusa a proposta ou retira a
  /// contraproposta; o dono retira). Shows confirmados ficam. Devolve
  /// quantos itens foram encerrados.
  Future<int> encerrarPendentesCom(String uid, String outroUid) async {
    var encerrados = 0;
    final agora = DateTime.now();

    final recebidos = await firestore
        .collection('interesses')
        .where('destinatarioId', isEqualTo: uid)
        .get();
    final enviados = await firestore
        .collection('interesses')
        .where('remetenteId', isEqualTo: uid)
        .get();
    for (final d in recebidos.docs) {
      final i = d.data();
      if (i['remetenteId'] != outroUid || i['status'] != 'pendente') continue;
      await d.reference.update({
        'status': StatusInteresse.recusado.name,
        'respondidoEm': agora,
      });
      encerrados++;
    }
    for (final d in enviados.docs) {
      final i = d.data();
      if (i['destinatarioId'] != outroUid || i['status'] != 'pendente') {
        continue;
      }
      await d.reference.update({
        'status': StatusInteresse.cancelado.name,
        'respondidoEm': agora,
      });
      encerrados++;
    }

    final contratacoes = await streamContratacoes(uid).first;
    for (final c in contratacoes) {
      final outro = c.musicoId == uid ? c.donoId : c.musicoId;
      if (outro != outroUid || !c.emNegociacao) continue;
      if (c.musicoId == uid && c.status == StatusContratacao.proposta) {
        await recusarContratacao(c.id);
      } else {
        await cancelarContratacao(c, canceladoPor: uid);
      }
      encerrados++;
    }
    return encerrados;
  }

  Future<void> denunciar(Denuncia denuncia) {
    return firestore.collection('denuncias').add(denuncia.toMap());
  }

  /// Todas as denúncias (só o admin consegue ler).
  Stream<List<Denuncia>> streamDenuncias() {
    return firestore
        .collection('denuncias')
        .snapshots()
        .map(
          (s) => s.docs.map((d) => Denuncia.fromMap(d.id, d.data())).toList(),
        );
  }

  Future<void> marcarDenunciaAnalisada(String denunciaId) {
    return firestore.collection('denuncias').doc(denunciaId).update({
      'status': 'analisada',
      'analisadaEm': DateTime.now(),
    });
  }

  // ---------------------------------------------------------------------------
  // Favoritos (Plano 18)
  // ---------------------------------------------------------------------------

  /// `usuarios/{uid}/favoritos/{tipo}_{alvoId}` — só o dono lê e escreve.
  /// [tipo] é `musico` ou `oportunidade` (o prefixo evita colisão de ids).
  DocumentReference<Map<String, dynamic>> _favorito(
    String uid,
    String tipo,
    String alvoId,
  ) => firestore
      .collection('usuarios')
      .doc(uid)
      .collection('favoritos')
      .doc('${tipo}_$alvoId');

  /// Favoritos de [uid], separados por tipo.
  Stream<({Set<String> musicos, Set<String> oportunidades})> streamFavoritos(
    String uid,
  ) {
    return firestore
        .collection('usuarios')
        .doc(uid)
        .collection('favoritos')
        .snapshots()
        .map((s) {
          final musicos = <String>{};
          final oportunidades = <String>{};
          for (final d in s.docs) {
            final alvoId = d.data()['alvoId'] as String? ?? '';
            switch (d.data()['tipo']) {
              case 'musico':
                musicos.add(alvoId);
              case 'oportunidade':
                oportunidades.add(alvoId);
            }
          }
          return (musicos: musicos, oportunidades: oportunidades);
        });
  }

  Future<void> favoritar(String uid, String tipo, String alvoId) {
    return _favorito(uid, tipo, alvoId).set({
      'tipo': tipo,
      'alvoId': alvoId,
      'criadoEm': DateTime.now(),
    });
  }

  Future<void> desfavoritar(String uid, String tipo, String alvoId) {
    return _favorito(uid, tipo, alvoId).delete();
  }

  // ---------------------------------------------------------------------------
  // Avaliações (Plano 17)
  // ---------------------------------------------------------------------------

  /// Grava a avaliação com id `{contratacaoId}_{autorId}`. As regras só
  /// aceitam uma vez, por quem participou, dentro do prazo.
  Future<void> avaliar(Avaliacao avaliacao) {
    return firestore
        .collection('avaliacoes')
        .doc(avaliacao.id)
        .set(avaliacao.toMap());
  }

  /// Todas as avaliações (leitura pública). A coleção é pequena num app de
  /// TCC; se crescer, trocar por consultas por `avaliadoId`.
  Stream<List<Avaliacao>> streamAvaliacoes() {
    return firestore
        .collection('avaliacoes')
        .snapshots()
        .map(
          (s) => s.docs.map((d) => Avaliacao.fromMap(d.id, d.data())).toList(),
        );
  }

  // ---------------------------------------------------------------------------
  // Notificações (Plano 11)
  // ---------------------------------------------------------------------------

  /// Grava as notificações em batches de até 10: a regra de cada uma lê o
  /// interesse vinculado, e as regras limitam as leituras por batch.
  Future<void> notificar(List<Notificacao> notificacoes) async {
    const porBatch = 10;
    for (var i = 0; i < notificacoes.length; i += porBatch) {
      final batch = firestore.batch();
      for (final n in notificacoes.skip(i).take(porBatch)) {
        batch.set(firestore.collection('notificacoes').doc(), n.toMap());
      }
      await batch.commit();
    }
  }

  /// Como [notificar], mas nunca falha: a notificação é secundária à ação
  /// que a gerou, que já foi gravada; a falha só fica no log.
  Future<void> tentarNotificar(List<Notificacao> notificacoes) async {
    if (notificacoes.isEmpty) return;
    try {
      await notificar(notificacoes);
    } catch (erro, stack) {
      AppLogger.falha(_origem, 'Falha ao notificar', erro, stack);
    }
  }

  /// Sem `orderBy` (evita índice composto): quem usa ordena.
  Stream<List<Notificacao>> streamNotificacoes(String uid) {
    return firestore
        .collection('notificacoes')
        .where('destinatarioId', isEqualTo: uid)
        .snapshots()
        .map(
          (s) =>
              s.docs.map((d) => Notificacao.fromMap(d.id, d.data())).toList(),
        );
  }

  Future<void> marcarNotificacoesLidas(List<String> ids) async {
    const porBatch = 400;
    for (var i = 0; i < ids.length; i += porBatch) {
      final batch = firestore.batch();
      for (final id in ids.skip(i).take(porBatch)) {
        batch.update(firestore.collection('notificacoes').doc(id), {
          'lida': true,
        });
      }
      await batch.commit();
    }
  }

  Future<void> removerNotificacao(String id) =>
      firestore.collection('notificacoes').doc(id).delete();

  /// Interesses da oportunidade dos quais [uid] é parte (as regras exigem a
  /// consulta restrita a remetente ou destinatário).
  Future<List<Interesse>> interessesDaOportunidade(
    String uid,
    String oportunidadeId,
  ) async {
    Future<List<Interesse>> por(String campo) async {
      final snapshot = await firestore
          .collection('interesses')
          .where(campo, isEqualTo: uid)
          .where('oportunidadeId', isEqualTo: oportunidadeId)
          .get();
      return snapshot.docs
          .map((d) => Interesse.fromMap(d.id, d.data()))
          .toList();
    }

    final listas = await Future.wait([
      por('remetenteId'),
      por('destinatarioId'),
    ]);
    return {
      for (final i in [...listas[0], ...listas[1]]) i.id: i,
    }.values.toList();
  }

  /// Contratações ainda ativas (proposta/confirmada) da oportunidade, do dono.
  Future<List<Contratacao>> contratacoesAtivasDaOportunidade(
    String donoId,
    String oportunidadeId,
  ) async {
    final snapshot = await firestore
        .collection('contratacoes')
        .where('donoId', isEqualTo: donoId)
        .where('oportunidadeId', isEqualTo: oportunidadeId)
        .get();
    return snapshot.docs
        .map((d) => Contratacao.fromMap(d.id, d.data()))
        .where((c) => c.ativa)
        .toList();
  }

  /// Remove a oportunidade encerrando, no mesmo batch, os interesses pendentes
  /// dela: candidaturas (o dono é o destinatário) viram `recusado`; convites
  /// (o dono é o remetente) viram `cancelado`.
  Future<void> encerrarOportunidade(
    String oportunidadeId,
    List<Interesse> interesses,
  ) {
    final batch = firestore.batch();
    final agora = DateTime.now();
    for (final interesse in interesses.where((i) => i.pendente)) {
      batch.update(firestore.collection('interesses').doc(interesse.id), {
        'status': interesse.tipo == TipoInteresse.candidatura
            ? StatusInteresse.recusado.name
            : StatusInteresse.cancelado.name,
        'respondidoEm': agora,
      });
    }
    batch.delete(firestore.collection('oportunidades').doc(oportunidadeId));
    return batch.commit();
  }

  /// Registra que [uid] leu a conversa agora (contador de não lidas).
  Future<void> marcarConversaLida(String conversaId, String uid) {
    return firestore.collection('conversas').doc(conversaId).update({
      'lidaEm.$uid': DateTime.now(),
    });
  }

  Stream<List<Conversa>> streamConversas(String uid) {
    return firestore
        .collection('conversas')
        .where('participantes', arrayContains: uid)
        .snapshots()
        .map(
          (s) => s.docs.map((d) => Conversa.fromMap(d.id, d.data())).toList(),
        );
  }

  /// `arrayUnion` em vez de regravar a lista: dois participantes escrevendo ao
  /// mesmo tempo não se sobrescrevem.
  Future<void> enviarMensagem(String conversaId, Mensagem mensagem) {
    return firestore.collection('conversas').doc(conversaId).update({
      'mensagens': FieldValue.arrayUnion([mensagem.toMap()]),
      'atualizadoEm': mensagem.dataHora,
    });
  }
}

/// Junta dois streams: emite [juntar] com o último valor de cada um, a
/// partir do momento em que os dois já emitiram.
Stream<R> _combinar<A, B, R>(
  Stream<A> a,
  Stream<B> b,
  R Function(A, B) juntar,
) {
  late StreamController<R> controller;
  StreamSubscription<A>? subA;
  StreamSubscription<B>? subB;
  A? ultimoA;
  B? ultimoB;
  var temA = false;
  var temB = false;

  void emitir() {
    if (temA && temB) controller.add(juntar(ultimoA as A, ultimoB as B));
  }

  controller = StreamController<R>(
    onListen: () {
      subA = a.listen((v) {
        ultimoA = v;
        temA = true;
        emitir();
      }, onError: controller.addError);
      subB = b.listen((v) {
        ultimoB = v;
        temB = true;
        emitir();
      }, onError: controller.addError);
    },
    // Sem await: quem cancela (ex.: `.first`) não precisa esperar o
    // encerramento das consultas internas.
    onCancel: () {
      subA?.cancel();
      subB?.cancel();
    },
  );
  return controller.stream;
}

String _bloqueioId(String usuarioId, DateTime data) {
  final dataNormalizada = DateTime(data.year, data.month, data.day);
  final dataIso = dataNormalizada.toIso8601String().substring(0, 10);
  return '${usuarioId}_$dataIso';
}

DateTime _dateTimeFromValue(dynamic value) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value) ?? DateTime.now();

  try {
    return value.toDate() as DateTime;
  } catch (_) {
    return DateTime.now();
  }
}

const _origem = 'FirebaseDataService';
