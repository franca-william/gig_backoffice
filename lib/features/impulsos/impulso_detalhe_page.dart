import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../app/di.dart';
import '../../app/rotas.dart';
import '../../core/formatar.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/gig_toast.dart';
import '../../data/models/impulso.dart';
import '../sugestoes/widgets.dart';
import 'impulsos_store.dart';

/// E40 — detalhe de um impulso: compra na loja, texto da notificação, resultados e estorno (só Google Play).
class ImpulsoDetalhePage extends StatefulWidget {
  const ImpulsoDetalhePage({super.key, required this.id});

  final String id;

  @override
  State<ImpulsoDetalhePage> createState() => _ImpulsoDetalhePageState();
}

class _ImpulsoDetalhePageState extends State<ImpulsoDetalhePage> {
  final _store = getIt<ImpulsosStore>();
  ImpulsoDetalhe? _detalhe;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      final d = await _store.detalhe(widget.id);
      if (mounted) setState(() => _detalhe = d);
    } catch (e) {
      if (mounted) setState(() => _erro = '$e');
    }
  }

  Future<void> _estornar() async {
    final ok = await showGigConfirmDialog(
      context,
      title: 'Estornar impulso?',
      message: 'O Google Play devolve o valor à casa e o impulso para na hora. Não dá para desfazer.',
      confirmLabel: 'Estornar',
      destructive: true,
    );
    if (!ok) return;
    try {
      await _store.estornar(widget.id);
      GigToast.success('Estornado. A casa foi avisada.');
      await _carregar();
    } catch (e) {
      GigToast.error('$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _detalhe;
    return Padding(
      padding: const EdgeInsets.all(GigSpacing.xxxl),
      child: d == null
          ? Center(child: _erro == null ? const CircularProgressIndicator() : Text(_erro!, style: GigTypography.body))
          : ListView(children: [
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => context.go(Rotas.impulsos),
                  icon: const Icon(LucideIcons.arrowLeft, size: 16),
                  label: const Text('Impulsos'),
                ),
              ),
              Row(children: [
                Expanded(child: Text('${d.resumo.nomeProduto} · ${d.resumo.evento}', style: GigTypography.h1)),
                Etiqueta(texto: d.resumo.situacao.rotulo, cor: GigColors.primary),
              ]),
              const SizedBox(height: GigSpacing.xs),
              Text(
                '${d.resumo.casa}${d.resumo.dataEvento == null ? '' : ' · evento em ${Formatar.data(d.resumo.dataEvento!)}'}'
                '${d.resumo.pagoEm == null ? '' : ' · pago em ${Formatar.dataHora(d.resumo.pagoEm!)}'}',
                style: GigTypography.paragraph,
              ),
              const SizedBox(height: GigSpacing.xl),
              Text('Compra na loja', style: GigTypography.h3),
              const SizedBox(height: GigSpacing.sm),
              Text(
                d.resumo.loja == null
                    ? 'Sem compra confirmada.'
                    : '${d.resumo.loja == 'APP_STORE' ? 'App Store' : 'Google Play'} · ${d.idTransacao ?? ''}'
                        ' · ${d.resumo.ambiente ?? ''}${d.compraEstornada ? ' · ESTORNADA' : ''}',
                style: GigTypography.body,
              ),
              if (d.podeEstornar) ...[
                const SizedBox(height: GigSpacing.sm),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    key: const Key('impulso-estornar'),
                    onPressed: _estornar,
                    icon: const Icon(LucideIcons.rotateCw, size: 16),
                    label: const Text('Estornar pelo Google Play'),
                  ),
                ),
              ] else if (d.resumo.loja == 'APP_STORE')
                Text('Compras da App Store só são reembolsadas pela Apple, a pedido da casa.',
                    style: GigTypography.small),
              if (d.pushTitulo != null) ...[
                const SizedBox(height: GigSpacing.xl),
                Text('Notificação', style: GigTypography.h3),
                const SizedBox(height: GigSpacing.sm),
                Text(d.pushTitulo!, style: GigTypography.body.copyWith(fontWeight: FontWeight.w700)),
                Text(d.pushTexto ?? '', style: GigTypography.body),
                const SizedBox(height: GigSpacing.xs),
                Text(
                  [
                    if (d.resumo.push != null) d.resumo.push!.rotulo,
                    if (d.pushEditado) 'texto editado pela casa',
                    if (d.alcanceContratado != null) 'até ${d.alcanceContratado} curtidores',
                    if (d.motivoRecusa != null) 'recusado: ${d.motivoRecusa}',
                  ].join(' · '),
                  style: GigTypography.small,
                ),
              ],
              const SizedBox(height: GigSpacing.xl),
              Text('Resultados', style: GigTypography.h3),
              const SizedBox(height: GigSpacing.sm),
              Text(
                d.resumo.ehCard
                    ? '${d.impressoes} exibições · ${d.toques} toques · ${d.presencas} "Eu vou" em 24 h'
                    : '${d.enviados} enviadas · ${d.entregues} entregues · ${d.presencas} "Eu vou" em 24 h',
                style: GigTypography.body,
              ),
            ]),
    );
  }
}
