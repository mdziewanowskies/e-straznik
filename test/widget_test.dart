import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:e_straznik/screens/login_screen.dart';
import 'package:e_straznik/theme/app_theme.dart';

/// Smoke test ekranu logowania.
///
/// Sprawdza, że ekran renderuje pola email/hasło, oba CTA i komunikat
/// informujący, że konto tworzy się w panelu webowym.
void main() {
  testWidgets('Login screen renders email, password and CTAs',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('pl', 'PL'),
          supportedLocales: const [Locale('pl', 'PL')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const LoginScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('e-Strażnik'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Hasło'), findsOneWidget);
    expect(find.text('Zaloguj się'), findsWidgets);
    expect(find.text('Zaloguj się przez Google'), findsOneWidget);
    expect(
      find.text('Konto tworzysz w panelu webowym e-strażnika'),
      findsOneWidget,
    );
  });

  testWidgets('Login form validates empty fields',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('pl', 'PL'),
          supportedLocales: const [Locale('pl', 'PL')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const LoginScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Zaloguj się'));
    await tester.pump();

    expect(find.text('Podaj email'), findsOneWidget);
    expect(find.text('Podaj hasło'), findsOneWidget);
  });
}
