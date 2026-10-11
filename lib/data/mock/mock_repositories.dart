import '../models/models.dart';
import '../repositories/repositories.dart';

/// Relógio injetável (os testes controlam "agora" para as etiquetas Atrasada / Vence hoje).
typedef Relogio = DateTime Function();

/// Sessão falsa: `equipe@gig.app` / `123456`. [cookieValido] simula o cookie HttpOnly (recarregar a página).
class MockSessaoRepository implements SessaoRepository {
  MockSessaoRepository({this.cookieValido = false});

  static const loginEquipe = 'equipe@gig.app';
  static const senhaEquipe = '123456';
  static const membro = Membro(nome: 'Ana Equipe', login: loginEquipe);

  bool cookieValido;

  @override
  Future<Membro> entrar(String login, String senha) async {
    await Future<void>.delayed(Duration.zero);
    if (login.trim().toLowerCase() != loginEquipe || senha != senhaEquipe) {
      throw const CredenciaisInvalidasException();
    }
    cookieValido = true;
    return membro;
  }

  @override
  Future<Membro?> restaurar() async => cookieValido ? membro : null;

  @override
  Future<void> sair() async => cookieValido = false;
}

/// 8 sugestões de exemplo, em todas as situações, 2 atrasadas e 1 vencendo hoje.
class MockSugestaoRepository implements SugestaoRepository {
  MockSugestaoRepository({Relogio? relogio}) : _agora = relogio ?? DateTime.now {
    _semear();
  }

  final Relogio _agora;
  final Map<String, SugestaoDetalhe> _dados = {};

  /// Simula outra pessoa da equipe respondendo antes (409).
  final Set<String> respondidasPorOutraPessoa = {};

  static const tamanhoDaPagina = 20;

  void _semear() {
    final agora = _agora();
    SugestaoDetalhe s(String id, Duration atras, String? nome, PerfilSugestao perfil, TipoSugestao? tipo, String texto,
            SituacaoSugestao situacao, {String? resposta}) {
      final enviada = agora.subtract(atras);
      return SugestaoDetalhe(
        id: id,
        enviadaEm: enviada,
        prazoResposta: enviada.add(const Duration(days: 2)),
        nome: nome,
        perfil: perfil,
        tipo: tipo,
        texto: texto,
        situacao: situacao,
        aparelho: const Aparelho(
            versaoApp: '0.2.0', build: '7', sistema: 'Android', versaoSistema: '14 (SDK 34)', modelo: 'SM-A546E',
            idioma: 'pt_BR'),
        emAnaliseDesde: situacao == SituacaoSugestao.recebida ? null : enviada.add(const Duration(hours: 3)),
        emAnalisePor: situacao == SituacaoSugestao.recebida ? null : 'Ana Equipe',
        resposta: resposta,
        respondidaEm: resposta == null ? null : enviada.add(const Duration(hours: 20)),
        respondidaPor: resposta == null ? null : 'Ana Equipe',
      );
    }

    for (final item in [
      s('s1', const Duration(days: 3), 'Carlos Lima', PerfilSugestao.musico, TipoSugestao.ideia,
          'Queria poder filtrar as festas por estilo musical direto na Home.', SituacaoSugestao.recebida),
      s('s2', const Duration(days: 2, hours: 5), 'Bar do Zé', PerfilSugestao.estabelecimento, TipoSugestao.problema,
          'O banner do evento fica cortado quando a foto é vertical.', SituacaoSugestao.emAnalise),
      s('s3', const Duration(days: 1, hours: 12), 'Júlia Rocha', PerfilSugestao.curtidor, TipoSugestao.melhoria,
          'Seria ótimo ver quantas pessoas confirmaram presença antes de ir.', SituacaoSugestao.recebida),
      s('s4', const Duration(hours: 6), null, PerfilSugestao.curtidor, null,
          'Adoraria um modo claro no app.', SituacaoSugestao.recebida),
      s('s5', const Duration(hours: 2), 'Marcos Dias', PerfilSugestao.musico, TipoSugestao.outro,
          'Vocês pensam em ter pagamento pelo app?', SituacaoSugestao.emAnalise),
      s('s6', const Duration(days: 5), 'Pedro Alves', PerfilSugestao.musico, TipoSugestao.problema,
          'A notificação de convite não abria a tela certa.', SituacaoSugestao.respondida,
          resposta: 'Oi, Pedro! Obrigado pela sugestão. Já corrigimos na versão 0.2.0.'),
      s('s7', const Duration(days: 4), 'Casa Azul', PerfilSugestao.estabelecimento, TipoSugestao.ideia,
          'Poder duplicar um evento da semana passada.', SituacaoSugestao.respondida,
          resposta: 'Oi! Obrigado pela sugestão. Está na nossa lista.'),
      s('s8', const Duration(minutes: 30), 'Lia Souza', PerfilSugestao.curtidor, TipoSugestao.ideia,
          'Salvar festas favoritas para ver depois.', SituacaoSugestao.recebida),
    ]) {
      _dados[item.id] = item;
    }
  }

  SugestaoResumo _resumo(SugestaoDetalhe d) => SugestaoResumo(
        id: d.id,
        enviadaEm: d.enviadaEm,
        prazoResposta: d.prazoResposta,
        nome: d.nome,
        perfil: d.perfil,
        tipo: d.tipo,
        inicioDoTexto: d.texto.length <= 120 ? d.texto : '${d.texto.substring(0, 120)}…',
        situacao: d.situacao,
      );

  @override
  Future<PaginaSugestoes> listar(FiltroSugestoes filtro, {int pagina = 0}) async {
    final busca = filtro.busca.trim().toLowerCase();
    final filtradas = _dados.values
        .where((d) => filtro.situacao.aceita(d.situacao))
        .where((d) => filtro.perfil == null || d.perfil == filtro.perfil)
        .where((d) => filtro.tipo == null || d.tipo == filtro.tipo)
        .where((d) => busca.isEmpty || d.texto.toLowerCase().contains(busca))
        .toList()
      // Mesma ordem do backend: sem resposta primeiro (prazo mais próximo no topo), depois respondidas recentes.
      ..sort((a, b) {
        if (a.respondida != b.respondida) return a.respondida ? 1 : -1;
        if (!a.respondida) return a.prazoResposta.compareTo(b.prazoResposta);
        return b.respondidaEm!.compareTo(a.respondidaEm!);
      });
    final inicio = pagina * tamanhoDaPagina;
    final itens = filtradas.skip(inicio).take(tamanhoDaPagina).map(_resumo).toList();
    return PaginaSugestoes(
      itens: itens,
      pagina: pagina,
      total: filtradas.length,
      totalPaginas: (filtradas.length / tamanhoDaPagina).ceil(),
    );
  }

  @override
  Future<ContagemSugestoes> contagem() async {
    final agora = _agora();
    final abertas = _dados.values.where((d) => !d.respondida);
    return ContagemSugestoes(
      semResposta: abertas.length,
      atrasadas: abertas.where((d) => agora.isAfter(d.prazoResposta)).length,
    );
  }

  @override
  Future<SugestaoDetalhe> detalhe(String id) async {
    final d = _dados[id];
    if (d == null) throw const BackofficeException('Sugestão não encontrada.');
    return d;
  }

  @override
  Future<void> marcarEmAnalise(String id) async {
    final d = await detalhe(id);
    if (d.respondida) throw const SugestaoJaRespondidaException();
    if (d.situacao == SituacaoSugestao.emAnalise) return;
    _dados[id] = _copiar(d, situacao: SituacaoSugestao.emAnalise, emAnaliseDesde: _agora(), emAnalisePor: 'Ana Equipe');
  }

  @override
  Future<SugestaoDetalhe> responder(String id, String texto) async {
    final d = await detalhe(id);
    if (respondidasPorOutraPessoa.remove(id)) {
      _dados[id] = _copiar(d,
          situacao: SituacaoSugestao.respondida,
          resposta: 'Resposta enviada por outra pessoa da equipe.',
          respondidaEm: _agora(),
          respondidaPor: 'Bruno Equipe');
      throw const SugestaoJaRespondidaException();
    }
    if (d.respondida) throw const SugestaoJaRespondidaException();
    final limpo = texto.trim();
    if (limpo.length < 2 || limpo.length > 2000) {
      throw const BackofficeException('A resposta deve ter de 2 a 2000 caracteres.');
    }
    final respondida = _copiar(d,
        situacao: SituacaoSugestao.respondida, resposta: limpo, respondidaEm: _agora(), respondidaPor: 'Ana Equipe');
    _dados[id] = respondida;
    return respondida;
  }

  SugestaoDetalhe _copiar(SugestaoDetalhe d,
          {SituacaoSugestao? situacao,
          DateTime? emAnaliseDesde,
          String? emAnalisePor,
          String? resposta,
          DateTime? respondidaEm,
          String? respondidaPor}) =>
      SugestaoDetalhe(
        id: d.id,
        enviadaEm: d.enviadaEm,
        prazoResposta: d.prazoResposta,
        nome: d.nome,
        perfil: d.perfil,
        tipo: d.tipo,
        texto: d.texto,
        situacao: situacao ?? d.situacao,
        aparelho: d.aparelho,
        emAnaliseDesde: emAnaliseDesde ?? d.emAnaliseDesde,
        emAnalisePor: emAnalisePor ?? d.emAnalisePor,
        resposta: resposta ?? d.resposta,
        respondidaEm: respondidaEm ?? d.respondidaEm,
        respondidaPor: respondidaPor ?? d.respondidaPor,
      );
}
