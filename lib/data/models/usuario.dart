import 'models.dart';

/// E5 (backoffice) — consulta de usuários pela equipe (somente leitura).

enum SituacaoUsuario {
  ativo('ATIVO', 'Ativo'),
  suspenso('SUSPENSO', 'Suspenso'),
  banido('BANIDO', 'Banido');

  const SituacaoUsuario(this.api, this.rotulo);

  final String api;
  final String rotulo;

  static SituacaoUsuario deApi(String? valor) =>
      values.where((s) => s.api == valor).firstOrNull ?? SituacaoUsuario.ativo;
}

List<PerfilSugestao> _perfis(Object? json) => (json as List<dynamic>? ?? [])
    .map((e) => PerfilSugestao.deApi(e as String?))
    .whereType<PerfilSugestao>()
    .toList();

DateTime? _data(Object? v) => v == null ? null : DateTime.parse(v as String);

class FiltroUsuarios {
  const FiltroUsuarios({this.busca = '', this.perfil});

  final String busca;
  final PerfilSugestao? perfil;

  FiltroUsuarios copyWith({String? busca, PerfilSugestao? perfil, bool limparPerfil = false}) => FiltroUsuarios(
        busca: busca ?? this.busca,
        perfil: limparPerfil ? null : (perfil ?? this.perfil),
      );
}

class UsuarioResumo {
  const UsuarioResumo({
    required this.id,
    required this.nome,
    required this.login,
    required this.perfis,
    required this.situacao,
    required this.criadoEm,
    this.cidade,
    this.estado,
    this.ultimoAcesso,
  });

  final String id;
  final String nome;
  final String login;
  final String? cidade;
  final String? estado;
  final List<PerfilSugestao> perfis;
  final SituacaoUsuario situacao;
  final DateTime criadoEm;
  final DateTime? ultimoAcesso;

  String get local => [cidade, estado].where((e) => e != null && e.isNotEmpty).join(' - ');

  factory UsuarioResumo.fromJson(Map<String, dynamic> json) => UsuarioResumo(
        id: json['uuid'] as String,
        nome: json['nome'] as String? ?? '',
        login: json['login'] as String? ?? '',
        cidade: json['cidade'] as String?,
        estado: json['estado'] as String?,
        perfis: _perfis(json['perfis']),
        situacao: SituacaoUsuario.deApi(json['situacao'] as String?),
        criadoEm: DateTime.parse(json['criadoEm'] as String),
        ultimoAcesso: _data(json['ultimoAcesso']),
      );
}

class UsuarioDetalhe {
  const UsuarioDetalhe({
    required this.id,
    required this.nome,
    required this.login,
    required this.perfis,
    required this.situacao,
    required this.criadoEm,
    this.cidade,
    this.estado,
    this.sobre,
    this.suspensoAte,
    this.banidoEm,
    this.fotoOculta = false,
    this.temFoto = false,
    this.ultimoAcesso,
  });

  final String id;
  final String nome;
  final String login;
  final String? cidade;
  final String? estado;
  final String? sobre;
  final List<PerfilSugestao> perfis;
  final SituacaoUsuario situacao;
  final DateTime? suspensoAte;
  final DateTime? banidoEm;
  final bool fotoOculta;
  final bool temFoto;
  final DateTime criadoEm;
  final DateTime? ultimoAcesso;

  String get local => [cidade, estado].where((e) => e != null && e.isNotEmpty).join(' - ');

  factory UsuarioDetalhe.fromJson(Map<String, dynamic> json) => UsuarioDetalhe(
        id: json['uuid'] as String,
        nome: json['nome'] as String? ?? '',
        login: json['login'] as String? ?? '',
        cidade: json['cidade'] as String?,
        estado: json['estado'] as String?,
        sobre: json['sobre'] as String?,
        perfis: _perfis(json['perfis']),
        situacao: SituacaoUsuario.deApi(json['situacao'] as String?),
        suspensoAte: _data(json['suspensoAte']),
        banidoEm: _data(json['banidoEm']),
        fotoOculta: json['fotoOculta'] as bool? ?? false,
        temFoto: json['temFoto'] as bool? ?? false,
        criadoEm: DateTime.parse(json['criadoEm'] as String),
        ultimoAcesso: _data(json['ultimoAcesso']),
      );
}

class PaginaUsuarios {
  const PaginaUsuarios({required this.itens, required this.pagina, required this.total, required this.totalPaginas});

  final List<UsuarioResumo> itens;
  final int pagina;
  final int total;
  final int totalPaginas;

  static const vazia = PaginaUsuarios(itens: [], pagina: 0, total: 0, totalPaginas: 0);

  factory PaginaUsuarios.fromJson(Map<String, dynamic> json) => PaginaUsuarios(
        itens: (json['itens'] as List<dynamic>? ?? [])
            .map((e) => UsuarioResumo.fromJson(e as Map<String, dynamic>))
            .toList(),
        pagina: (json['pagina'] as num?)?.toInt() ?? 0,
        total: (json['total'] as num?)?.toInt() ?? 0,
        totalPaginas: (json['totalPaginas'] as num?)?.toInt() ?? 0,
      );
}
