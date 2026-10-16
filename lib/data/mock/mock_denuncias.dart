import 'dart:typed_data';

import '../models/denuncia.dart';
import '../repositories/repositories.dart';
import 'mock_repositories.dart';
import 'mock_verificacoes.dart';

/// E31 — 5 denúncias de exemplo: 4 abertas (2 de gravidade alta, 1 atrasada; 1 média; 1 baixa) e 1 já decidida.
/// A foto do retrato é a imagem de 1 pixel das verificações.
class MockDenunciaRepository implements DenunciaRepository {
  MockDenunciaRepository({Relogio? relogio}) : _agora = relogio ?? DateTime.now {
    _semear();
  }

  final Relogio _agora;
  final Map<String, DenunciaDetalhe> _dados = {};

  /// Fotos abertas (como a auditoria do backend).
  final List<String> fotosAbertas = [];

  /// Decisões recebidas (para os testes conferirem o corpo enviado).
  final Map<String, DecisaoDenuncia> decisoes = {};

  /// Simula outra pessoa da equipe decidindo antes (409).
  final Set<String> decididasPorOutraPessoa = {};

  static const tamanhoDaPagina = 20;

  void _semear() {
    final agora = _agora();
    DenunciaDetalhe d(
      String id,
      String tipo,
      String descricao,
      GravidadeDenuncia gravidade,
      String perfil,
      String nome,
      Duration atras, {
      SituacaoDenuncia situacao = SituacaoDenuncia.aberta,
      String? comentario,
      bool temFoto = false,
      bool fotoOculta = false,
      int total = 1,
      int pessoas = 1,
      String? sobre,
    }) {
      final criada = agora.subtract(atras);
      final prazo = gravidade == GravidadeDenuncia.alta
          ? criada.add(const Duration(hours: 24))
          : criada.add(const Duration(days: 3));
      return DenunciaDetalhe(
        id: id,
        tipo: tipo,
        tipoDescricao: descricao,
        gravidade: gravidade,
        situacao: situacao,
        origem: 'PERFIL',
        comentario: comentario,
        criadaEm: criada,
        prazoAnalise: prazo,
        denunciante: 'Rafael Lima',
        perfilDenunciante: 'CURTIDOR',
        retrato: RetratoDenunciado(nome: nome, sobre: sobre, cidade: 'Fortaleza', estado: 'CE', temFoto: temFoto),
        atual: PerfilAtual(
          perfil: perfil,
          perfilId: 'perfil-$id',
          nome: nome,
          sobre: sobre,
          cidade: 'Fortaleza',
          estado: 'CE',
          fotoOculta: fotoOculta,
        ),
        totalDoPerfil: total,
        pessoasDistintas: pessoas,
        historico: [
          for (var i = 1; i < total; i++)
            HistoricoDenuncia(
              id: '$id-h$i',
              tipoDescricao: descricao,
              gravidade: gravidade,
              situacao: SituacaoDenuncia.aberta,
              criadaEm: criada.subtract(Duration(hours: i)),
            ),
        ],
        decisao: situacao.aberta
            ? null
            : DecisaoTomada(procedente: false, acao: AcaoDenuncia.nenhuma, analisadaEm: criada.add(const Duration(hours: 5))),
      );
    }

    for (final x in [
      d('d1', 'CONTEUDO_EXPLICITO', 'Conteúdo sexual ou explícito', GravidadeDenuncia.alta, 'CURTIDOR', 'Lara Mendes',
          const Duration(hours: 30),
          temFoto: true, fotoOculta: true, total: 3, pessoas: 3, sobre: 'Só alegria'),
      d('d2', 'ASSEDIO', 'Assédio, ameaça ou perfil que está me incomodando', GravidadeDenuncia.media, 'MUSICO',
          'DJ Kadu', const Duration(days: 1),
          comentario: 'Manda mensagem toda hora depois que recusei.'),
      d('d3', 'CONTEUDO_INADEQUADO', 'Conteúdo que não deveria estar aqui (spam, propaganda, foto que não é da pessoa)',
          GravidadeDenuncia.baixa, 'ESTABELECIMENTO', 'Bar Estrela', const Duration(hours: 2),
          sobre: 'Promoção! Chama no zap 85 9999-0000'),
      d('d4', 'DISCURSO_DE_ODIO', 'Racismo, homofobia, transfobia ou outro preconceito', GravidadeDenuncia.alta,
          'CURTIDOR', 'Beto Lima', const Duration(hours: 2),
          comentario: 'Bio com ofensa.', sobre: 'Texto ofensivo de exemplo'),
      d('d5', 'GOLPE', 'Golpe, cobrança indevida ou fraude', GravidadeDenuncia.media, 'MUSICO', 'Banda Fake',
          const Duration(days: 4),
          situacao: SituacaoDenuncia.improcedente),
    ]) {
      _dados[x.id] = x;
    }
  }

  static int _ordemGravidade(GravidadeDenuncia g) => switch (g) {
        GravidadeDenuncia.alta => 0,
        GravidadeDenuncia.media => 1,
        GravidadeDenuncia.baixa => 2,
      };

  @override
  Future<PaginaDenuncias> listar(FiltroDenuncias filtro, {int pagina = 0}) async {
    final busca = filtro.busca.trim().toLowerCase();
    final lista = _dados.values.where((d) {
      final situacaoOk = switch (filtro.situacao) {
        FiltroDenuncia.abertas => d.situacao.aberta,
        FiltroDenuncia.procedente => d.situacao == SituacaoDenuncia.procedente,
        FiltroDenuncia.improcedente => d.situacao == SituacaoDenuncia.improcedente,
        FiltroDenuncia.todas => true,
      };
      return situacaoOk &&
          (filtro.gravidade == null || d.gravidade == filtro.gravidade) &&
          (busca.isEmpty || d.atual.nome.toLowerCase().contains(busca));
    }).toList()
      ..sort((a, b) {
        if (a.aberta != b.aberta) return a.aberta ? -1 : 1;
        if (a.aberta) {
          final g = _ordemGravidade(a.gravidade).compareTo(_ordemGravidade(b.gravidade));
          return g != 0 ? g : a.prazoAnalise.compareTo(b.prazoAnalise);
        }
        return (b.decisao?.analisadaEm ?? b.criadaEm).compareTo(a.decisao?.analisadaEm ?? a.criadaEm);
      });
    final inicio = pagina * tamanhoDaPagina;
    return PaginaDenuncias(
      itens: [for (final d in lista.skip(inicio).take(tamanhoDaPagina)) _resumo(d)],
      pagina: pagina,
      total: lista.length,
      totalPaginas: (lista.length / tamanhoDaPagina).ceil(),
    );
  }

  @override
  Future<ContagemDenuncias> contagem() async {
    final agora = _agora();
    final abertas = _dados.values.where((d) => d.aberta).toList();
    return ContagemDenuncias(
      abertas: abertas.length,
      altas: abertas.where((d) => d.gravidade == GravidadeDenuncia.alta).length,
      atrasadas: abertas.where((d) => d.prazoAnalise.isBefore(agora)).length,
    );
  }

  @override
  Future<DenunciaDetalhe> detalhe(String id) async {
    final d = _dados[id];
    if (d == null) throw const BackofficeException('Denúncia não encontrada.');
    return d;
  }

  @override
  Future<({Uint8List bytes, String contentType})> foto(String id) async {
    final d = await detalhe(id);
    if (!d.retrato.temFoto) throw const BackofficeException('Denúncia sem foto.');
    fotosAbertas.add(id);
    return (bytes: MockVerificacaoRepository.imagem, contentType: 'image/png');
  }

  @override
  Future<DenunciaDetalhe> decidir(String id, DecisaoDenuncia decisao) async {
    final d = await detalhe(id);
    if (!d.aberta || decididasPorOutraPessoa.contains(id)) throw const DenunciaJaAnalisadaException();
    final acao = decisao.procedente ? decisao.acao : AcaoDenuncia.nenhuma;
    if (acao == null) throw const BackofficeException('Escolha a ação para a denúncia procedente.');
    if (acao == AcaoDenuncia.suspensao && decisao.diasSuspensao != 7 && decisao.diasSuspensao != 30) {
      throw const BackofficeException('A suspensão é de 7 ou 30 dias.');
    }
    if (acao == AcaoDenuncia.conteudoRemovido && !decisao.removerFoto && !decisao.removerSobre) {
      throw const BackofficeException('Escolha remover a foto, o sobre ou os dois.');
    }
    decisoes[id] = decisao;
    final agora = _agora();
    final a = d.atual;
    final removeuFoto = acao == AcaoDenuncia.conteudoRemovido && decisao.removerFoto;
    final removeuSobre = acao == AcaoDenuncia.conteudoRemovido && decisao.removerSobre;
    return _dados[id] = DenunciaDetalhe(
      id: d.id,
      tipo: d.tipo,
      tipoDescricao: d.tipoDescricao,
      gravidade: d.gravidade,
      situacao: decisao.procedente ? SituacaoDenuncia.procedente : SituacaoDenuncia.improcedente,
      origem: d.origem,
      comentario: d.comentario,
      criadaEm: d.criadaEm,
      prazoAnalise: d.prazoAnalise,
      denunciante: d.denunciante,
      perfilDenunciante: d.perfilDenunciante,
      retrato: d.retrato,
      atual: PerfilAtual(
        perfil: a.perfil,
        perfilId: a.perfilId,
        nome: a.nome,
        sobre: removeuSobre ? null : a.sobre,
        cidade: a.cidade,
        estado: a.estado,
        fotoUrl: removeuFoto ? null : a.fotoUrl,
        suspensoAte: acao == AcaoDenuncia.suspensao ? agora.add(Duration(days: decisao.diasSuspensao!)) : a.suspensoAte,
        banidoEm: acao == AcaoDenuncia.banimento ? agora : a.banidoEm,
      ),
      totalDoPerfil: d.totalDoPerfil,
      pessoasDistintas: d.pessoasDistintas,
      historico: d.historico,
      decisao: DecisaoTomada(
        procedente: decisao.procedente,
        acao: acao,
        diasSuspensao: acao == AcaoDenuncia.suspensao ? decisao.diasSuspensao : null,
        fotoRemovida: removeuFoto,
        sobreRemovido: removeuSobre,
        observacaoInterna: decisao.observacaoInterna,
        mensagemParaDenunciado: decisao.mensagemParaDenunciado,
        analisadaEm: agora,
        analisadaPor: MockSessaoRepository.membro.nome,
      ),
    );
  }

  static DenunciaResumo _resumo(DenunciaDetalhe d) => DenunciaResumo(
        id: d.id,
        tipo: d.tipo,
        tipoDescricao: d.tipoDescricao,
        gravidade: d.gravidade,
        situacao: d.situacao,
        acao: d.decisao?.acao,
        origem: d.origem,
        perfil: d.atual.perfil,
        denunciado: d.atual.nome,
        cidade: d.atual.cidade,
        estado: d.atual.estado,
        criadaEm: d.criadaEm,
        prazoAnalise: d.prazoAnalise,
        analisadaEm: d.decisao?.analisadaEm,
      );
}
