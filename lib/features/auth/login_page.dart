import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../app/di.dart';
import '../../app/sessao_store.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/gig_button.dart';
import '../../core/widgets/gig_logo.dart';
import '../../core/widgets/gig_text_field.dart';
import '../../data/repositories/repositories.dart';

/// Login do backoffice: mesmo e-mail e senha do app. Sem "criar conta".
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  final _sessao = getIt<SessaoStore>();
  bool _enviando = false;
  String? _erro;

  @override
  void dispose() {
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (_enviando || !(_form.currentState?.validate() ?? false)) return;
    setState(() {
      _enviando = true;
      _erro = null;
    });
    try {
      await _sessao.entrar(_email.text, _senha.text);
      // o router leva ao /dashboard quando a sessão muda
    } on CredenciaisInvalidasException {
      setState(() => _erro = 'E-mail ou senha inválidos.');
    } catch (_) {
      setState(() => _erro = 'Não foi possível entrar agora. Tente de novo em instantes.');
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/login_fundo.jpg'),
            fit: BoxFit.cover,
            // escurece a foto para o card e a logo continuarem legíveis
            colorFilter: ColorFilter.mode(Color(0x99000000), BlendMode.darken),
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(GigSpacing.xxl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: GigLogo(largura: 72)),
                  const SizedBox(height: GigSpacing.xxl),
                  Container(
                    padding: const EdgeInsets.all(GigSpacing.xxxl),
                    decoration: BoxDecoration(
                      color: GigColors.surface,
                      borderRadius: GigRadius.cardLarge,
                      border: Border.all(color: GigColors.border),
                    ),
                    child: Form(
                      key: _form,
                      child: AutofillGroup(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Backoffice',
                              style: GigTypography.h2.copyWith(color: GigColors.textSubtle),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: GigSpacing.xxl),
                            Observer(builder: (_) {
                              final aviso = _sessao.aviso.value;
                              if (aviso == null || _erro != null) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(bottom: GigSpacing.lg),
                                child: _Mensagem(texto: aviso, cor: GigColors.info),
                              );
                            }),
                            GigTextField(
                              key: const Key('login-email'),
                              label: 'E-mail',
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.username, AutofillHints.email],
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o e-mail.' : null,
                            ),
                            const SizedBox(height: GigSpacing.lg),
                            GigTextField(
                              key: const Key('login-senha'),
                              label: 'Senha',
                              controller: _senha,
                              isPassword: true,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.password],
                              onSubmitted: (_) => _entrar(),
                              validator: (v) => (v == null || v.isEmpty) ? 'Informe a senha.' : null,
                            ),
                            if (_erro != null) ...[
                              const SizedBox(height: GigSpacing.lg),
                              _Mensagem(texto: _erro!, cor: GigColors.danger),
                            ],
                            const SizedBox(height: GigSpacing.xxl),
                            GigButton(label: 'Entrar', onPressed: _entrar, loading: _enviando),
                            const SizedBox(height: GigSpacing.lg),
                            Text(
                              'Use o mesmo e-mail e senha do app GiG. O acesso é liberado só para a equipe.',
                              style: GigTypography.small,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: GigSpacing.sm),
                            Text(
                              'Esqueceu a senha? Redefina sua senha pelo app.',
                              style: GigTypography.small,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Mensagem extends StatelessWidget {
  const _Mensagem({required this.texto, required this.cor});

  final String texto;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: GigSpacing.md, vertical: GigSpacing.sm),
      decoration: BoxDecoration(
        color: cor.withAlpha(26),
        borderRadius: const BorderRadius.all(Radius.circular(GigRadius.sm)),
        border: Border.all(color: cor.withAlpha(115)),
      ),
      child: Text(texto, style: GigTypography.body),
    );
  }
}
