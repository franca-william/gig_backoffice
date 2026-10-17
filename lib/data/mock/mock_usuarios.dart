import '../models/models.dart';
import '../models/usuario.dart';
import '../repositories/repositories.dart';
import 'mock_repositories.dart';

/// E5 (backoffice) — 6 usuários de exemplo (ativo, com mais de um perfil, suspenso e banido).
class MockUsuarioRepository implements UsuarioRepository {
  MockUsuarioRepository({Relogio? relogio}) : _agora = relogio ?? DateTime.now {
    final agora = _agora();
    UsuarioDetalhe u(String id, String nome, List<PerfilSugestao> perfis,
            {String? cidade = 'São Paulo',
            String? estado = 'SP',
            SituacaoUsuario situacao = SituacaoUsuario.ativo,
            String? sobre}) =>
        UsuarioDetalhe(
          id: id,
          nome: nome,
          login: '${nome.toLowerCase().replaceAll(' ', '.')}@exemplo.com',
          cidade: cidade,
          estado: estado,
          sobre: sobre,
          perfis: perfis,
          situacao: situacao,
          suspensoAte: situacao == SituacaoUsuario.suspenso ? agora.add(const Duration(days: 5)) : null,
          banidoEm: situacao == SituacaoUsuario.banido ? agora.subtract(const Duration(days: 9)) : null,
          criadoEm: agora.subtract(const Duration(days: 120)),
          ultimoAcesso: agora.subtract(const Duration(hours: 3)),
        );
    for (final d in [
      u('u1', 'Ana Souza', [PerfilSugestao.musico], sobre: 'Violonista e cantora de MPB.'),
      u('u2', 'Bar do Zé', [PerfilSugestao.estabelecimento], cidade: 'Campinas'),
      u('u3', 'Carlos Lima', [PerfilSugestao.musico, PerfilSugestao.curtidor]),
      u('u4', 'Júlia Rocha', [PerfilSugestao.curtidor], cidade: null, estado: null),
      u('u5', 'Pedro Alves', [PerfilSugestao.musico], situacao: SituacaoUsuario.suspenso),
      u('u6', 'Marcos Dias', [PerfilSugestao.curtidor], situacao: SituacaoUsuario.banido),
    ]) {
      _dados[d.id] = d;
    }
  }

  final Relogio _agora;
  final Map<String, UsuarioDetalhe> _dados = {};

  static const tamanhoDaPagina = 20;

  UsuarioResumo _resumo(UsuarioDetalhe d) => UsuarioResumo(
        id: d.id,
        nome: d.nome,
        login: d.login,
        cidade: d.cidade,
        estado: d.estado,
        perfis: d.perfis,
        situacao: d.situacao,
        criadoEm: d.criadoEm,
        ultimoAcesso: d.ultimoAcesso,
      );

  @override
  Future<PaginaUsuarios> listar(FiltroUsuarios filtro, {int pagina = 0}) async {
    final busca = filtro.busca.trim().toLowerCase();
    final filtrados = _dados.values
        .where((d) => busca.isEmpty || d.nome.toLowerCase().contains(busca) || d.login.toLowerCase().contains(busca))
        .where((d) => filtro.perfil == null || d.perfis.contains(filtro.perfil))
        .toList()
      ..sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
    final itens = filtrados.skip(pagina * tamanhoDaPagina).take(tamanhoDaPagina).map(_resumo).toList();
    return PaginaUsuarios(
      itens: itens,
      pagina: pagina,
      total: filtrados.length,
      totalPaginas: (filtrados.length / tamanhoDaPagina).ceil(),
    );
  }

  @override
  Future<UsuarioDetalhe> detalhe(String id) async {
    final d = _dados[id];
    if (d == null) throw const BackofficeException('Usuário não encontrado.');
    return d;
  }
}
