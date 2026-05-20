import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:e_straznik/screens/login_screen.dart';
import 'package:e_straznik/theme/app_theme.dart';

Widget _wrap(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      theme: AppTheme.light(),
      locale: const Locale('pl', 'PL'),
      supportedLocales: const [Locale('pl', 'PL')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: child,
    ),
  );
}

void main() {
  testWidgets('Login screen renders email, password and CTA',
      (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(const LoginScreen()));
    await tester.pumpAndSettle();

    expect(find.text('e-Strażnik'), findsOneWidget);
    expect(find.text('Zaloguj się'), findsWidgets);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(
      find.textContaining('Konto firmowe tworzysz w panelu webowym'),
      findsOneWidget,
    );
  });

  testWidgets('Login form validates empty fields',
      (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(const LoginScreen()));
    await tester.pumpAndSettle();

    // ElevatedButton submit
    await tester.tap(find.widgetWithText(ElevatedButton, 'Zaloguj się'));
    await tester.pump();

    expect(find.text('Podaj email'), findsOneWidget);
    expect(find.text('Podaj hasło'), findsOneWidget);
  });
}
