import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../app/di.dart';
import '../../app/rotas.dart';
import '../../core/formatar.dart';
import '../../core/theme/theme.dart';
import '../../data/models/usuario.dart';
import '../../data/repositories/repositories.dart';
import 'usuarios_page.dart';

/// E5 (backoffice) — detalhe de uma conta (somente leitura). Nunca mostra senha nem o endereço das fotos.
class UsuarioDetalhePage extends StatefulWidget {
  const UsuarioDetalhePage({super.key, required this.id});

  final String id;

  @override
  State<UsuarioDetalhePage> createState() => _UsuarioDetalhePageState();
}

class _UsuarioDetalhePageState extends State<UsuarioDetalhePage> {
  final _repo = getIt<UsuarioRepository>();
  UsuarioDetalhe? _u;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void didUpdateWidget(covariant UsuarioDetalhePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) {
      _u = null;
      _carregar();
    }
  }

  Future<void> _carregar() async {
    setState(() => _erro = null);
    try {
      final u = await _repo.detalhe(widget.id);
      if (mounted) setState(() => _u = u);
    } on SessaoExpiradaException {
      // o app já volta para o login
    } on Exception catch (e) {
      if (mounted) setState(() => _erro = '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final voltar = Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        key: const Key('usuario-voltar'),
        onPressed: () => context.go(Rotas.usuarios),
        icon: const Icon(LucideIcons.arrowLeft, size: 16),
        label: const Text('Usuários'),
      ),
    );
    final u = _u;
    Widget corpo;
    if (_erro != null) {
      corpo = Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_erro!, style: GigTypography.body),
          TextButton(onPressed: _carregar, child: const Text('Tentar de novo')),
        ]),
      );
    } else if (u == null) {
      corpo = const Center(child: CircularProgressIndicator());
    } else {
      corpo = SingleChildScrollView(child: _conteudo(u));
    }
    return Padding(
      padding: const EdgeInsets.all(GigSpacing.xxxl),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        voltar,
        const SizedBox(height: GigSpacing.md),
        Expanded(child: corpo),
      ]),
    );
  }

  Widget _conteudo(UsuarioDetalhe u) {
    Widget campo(String rotulo, String valor, {Key? key}) => Padding(
          padding: const EdgeInsets.only(bottom: GigSpacing.lg),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(rotulo.toUpperCase(), style: GigTypography.fieldLabel),
            const SizedBox(height: GigSpacing.xxs),
            Text(valor, key: key, style: GigTypography.body),
          ]),
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(spacing: GigSpacing.md, runSpacing: GigSpacing.sm, crossAxisAlignment: WrapCrossAlignment.center, children: [
        Text(u.nome, key: const Key('usuario-nome'), style: GigTypography.h1),
        EtiquetaUsuario(situacao: u.situacao),
      ]),
      const SizedBox(height: GigSpacing.xl),
      campo('E-mail', u.login),
      campo('Perfis', u.perfis.isEmpty ? 'Nenhum perfil criado' : u.perfis.map((p) => p.rotulo).join(', ')),
      campo('Cidade', u.local.isEmpty ? '—' : u.local),
      if (u.sobre != null && u.sobre!.trim().isNotEmpty) campo('Sobre', u.sobre!),
      campo('Cadastro', Formatar.dataHora(u.criadoEm)),
      campo('Último acesso', u.ultimoAcesso == null ? '—' : Formatar.dataHora(u.ultimoAcesso!)),
      if (u.suspensoAte != null) campo('Suspenso até', Formatar.dataHora(u.suspensoAte!)),
      if (u.banidoEm != null) campo('Banido em', Formatar.dataHora(u.banidoEm!)),
      if (u.fotoOculta) campo('Foto', 'Escondida pela proteção automática, aguardando a análise da equipe.'),
      const SizedBox(height: GigSpacing.sm),
      Text('Para advertir, suspender ou banir, use Denúncias.', style: GigTypography.small),
    ]);
  }
}
