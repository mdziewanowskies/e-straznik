import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:e_straznik/data/models/meter_point.dart';
import 'package:e_straznik/data/models/monthly_summary.dart';
import 'package:e_straznik/theme/app_theme.dart';
import 'package:e_straznik/widgets/meter_point_card.dart';

/// Golden test pojedynczej karty PPE na dashboardzie.
///
/// Aby zapisać aktualny obraz referencyjny:
///   flutter test --update-goldens test/dashboard_golden_test.dart
void main() {
  setUpAll(() async {
    await initializeDateFormatting('pl_PL');
  });

  testWidgets('Meter point card golden', (tester) async {
    const mp = MeterPoint(
      id: 'mp1',
      label: 'Hotel — kuchnia główna',
      ppeNumber: 'PL_ZEYRD0000000000000000123456789',
      tariff: 'C22A',
      mocUmownaKw: 120,
      tgPhiLimit: 0.4,
    );
    const summary = MonthlySummary(
      meterPointId: 'mp1',
      consumedKwhMtd: 12345.67,
      reactiveInductiveKvarhMtd: 1234.5,
      reactiveCapacitiveKvarhMtd: 12.0,
      currentTgPhi: 0.35,
      projectedTgPhiEom: 0.38,
      exceedanceCount: 3,
      status: 'yellow',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('pl', 'PL'),
        supportedLocales: const [Locale('pl', 'PL')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: MeterPointCard(
              meterPoint: mp,
              summary: summary,
              onTap: () {},
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MeterPointCard),
      matchesGoldenFile('goldens/meter_point_card.png'),
    );
  });
}
