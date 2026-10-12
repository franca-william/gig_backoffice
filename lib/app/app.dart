import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/theme.dart';
import '../core/widgets/gig_toast.dart';

class BackofficeApp extends StatelessWidget {
  const BackofficeApp({super.key, required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'GiG Backoffice',
      debugShowCheckedModeBanner: false,
      theme: GigTheme.dark,
      routerConfig: router,
      scaffoldMessengerKey: GigToast.messengerKey,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
