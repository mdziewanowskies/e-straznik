import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/meter_point.dart';
import '../data/models/monthly_summary.dart';
import '../data/models/power_reading.dart';
import '../providers/dashboard_providers.dart';
import '../providers/meter_point_detail_providers.dart';
import '../theme/colors.dart';
import '../utils/formatters.dart';
import '../widgets/kpi_tile.dart';
import '../widgets/status_badge.dart';

class PpeDetailsScreen extends ConsumerWidget {
  const PpeDetailsScreen({super.key, required this.meterPointId});
  final String meterPointId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mp = ref.watch(meterPointProvider(meterPointId));
    final summary = ref.watch(meterPointSummaryProvider(meterPointId));

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: mp.maybeWhen(
            data: (m) => Hero(
              tag: 'mp-title-${meterPointId}',
              child: Material(
                color: Colors.transparent,
                child: Text(m?.label ?? 'PPE'),
              ),
            ),
            orElse: () => const Text('PPE'),
          ),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Przegląd'),
              Tab(text: 'Moc 15-min'),
              Tab(text: 'Energia bierna'),
              Tab(text: 'Odczyty'),
            ],
          ),
        ),
        body: mp.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Błąd: $e')),
          data: (meterPoint) {
            if (meterPoint == null) {
              return const Center(child: Text('Nie znaleziono PPE'));
            }
            return TabBarView(
              children: [
                _OverviewTab(
                    meterPoint: meterPoint, summaryAsync: summary),
                _PowerTab(meterPoint: meterPoint),
                _ReactiveTab(meterPointId: meterPointId),
                _ReadingsTab(meterPointId: meterPointId),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _OverviewTab extends ConsumerWidget {
  const _OverviewTab({required this.meterPoint, required this.summaryAsync});
  final MeterPoint meterPoint;
  final AsyncValue<MonthlySummary?> summaryAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(meterPointSummaryProvider(meterPoint.id));
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PPE ${meterPoint.ppeNumber}',
                        style: const TextStyle(
                            color: AppColors.mutedFg, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      'Taryfa ${meterPoint.tariff ?? '—'}  •  Moc umowna ${Fmt.kw(meterPoint.mocUmownaKw)}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
              StatusBadge(status: summaryAsync.value?.status ?? 'ok'),
            ],
          ),
          const SizedBox(height: 16),
          summaryAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text('Błąd: $e'),
            data: (s) => GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.0,
              children: [
                KpiTile(
                    label: 'Zużycie MTD',
                    value: Fmt.kwh(s?.consumedKwhMtd),
                    icon: Icons.bolt),
                KpiTile(
                    label: 'Bierna indukc. MTD',
                    value: Fmt.kvarh(s?.reactiveInductiveKvarhMtd),
                    icon: Icons.flash_on),
                KpiTile(
                    label: 'Bierna pojem. MTD',
                    value: Fmt.kvarh(s?.reactiveCapacitiveKvarhMtd),
                    icon: Icons.electrical_services),
                KpiTile(
                    label: 'tg φ aktualny',
                    value: Fmt.tgPhi(s?.currentTgPhi),
                    icon: Icons.show_chart),
                KpiTile(
                    label: 'Projekcja tg φ',
                    value: Fmt.tgPhi(s?.projectedTgPhiEom),
                    icon: Icons.trending_up,
                    color: _tgColor(s?.projectedTgPhiEom,
                        meterPoint.tgPhiLimit)),
                KpiTile(
                    label: 'Przekroczenia',
                    value: '${s?.exceedanceCount ?? 0}',
                    icon: Icons.warning_amber_rounded,
                    color: (s?.exceedanceCount ?? 0) > 0
                        ? AppColors.danger
                        : AppColors.foreground),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color? _tgColor(double? value, double? limit) {
    if (value == null || limit == null) return null;
    if (value > limit) return AppColors.danger;
    if (value > limit * 0.9) return AppColors.warning;
    return AppColors.success;
  }
}

class _PowerTab extends ConsumerWidget {
  const _PowerTab({required this.meterPoint});
  final MeterPoint meterPoint;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final powerAsync = ref.watch(power15MinProvider(meterPoint.id));
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(power15MinProvider(meterPoint.id)),
      child: powerAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Błąd: $e')),
        data: (readings) {
          if (readings.isEmpty) {
            return ListView(
              children: const [
                SizedBox(height: 80),
                Center(child: Text('Brak odczytów 15-minutowych.')),
              ],
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SizedBox(
                height: 260,
                child: _PowerChart(
                  readings: readings,
                  mocUmowna: meterPoint.mocUmownaKw,
                ),
              ),
              const SizedBox(height: 12),
              Text('Linia: ${Fmt.kw(meterPoint.mocUmownaKw)} (moc umowna)',
                  style: const TextStyle(
                      color: AppColors.mutedFg, fontSize: 12)),
            ],
          );
        },
      ),
    );
  }
}

class _PowerChart extends StatelessWidget {
  const _PowerChart({required this.readings, required this.mocUmowna});
  final List<Power15MinReading> readings;
  final double? mocUmowna;

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[
      for (int i = 0; i < readings.length; i++)
        FlSpot(i.toDouble(), readings[i].powerKw),
    ];
    final exceedanceSpots = <FlSpot>[
      for (int i = 0; i < readings.length; i++)
        if ((readings[i].exceedanceKw ?? 0) > 0)
          FlSpot(i.toDouble(), readings[i].powerKw),
    ];
    final maxY = [
      ...readings.map((r) => r.powerKw),
      if (mocUmowna != null) mocUmowna! * 1.1,
    ].fold<double>(0, (m, v) => v > m ? v : m);

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY == 0 ? 1 : maxY,
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (v, _) => Text(
                v.toStringAsFixed(0),
                style:
                    const TextStyle(fontSize: 10, color: AppColors.mutedFg),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: (readings.length / 4).clamp(1, 1000).toDouble(),
              getTitlesWidget: (v, _) {
                final idx = v.toInt();
                if (idx < 0 || idx >= readings.length) {
                  return const SizedBox.shrink();
                }
                return Text(
                  Fmt.time(readings[idx].timestamp),
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.mutedFg),
                );
              },
            ),
          ),
        ),
        extraLinesData: mocUmowna != null
            ? ExtraLinesData(
                horizontalLines: [
                  HorizontalLine(
                    y: mocUmowna!,
                    color: AppColors.danger,
                    strokeWidth: 1.5,
                    dashArray: const [6, 4],
                  ),
                ],
              )
            : null,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false,
            color: AppColors.primary,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.teal.withValues(alpha: 0.08),
            ),
          ),
          if (exceedanceSpots.isNotEmpty)
            LineChartBarData(
              spots: exceedanceSpots,
              isCurved: false,
              color: AppColors.danger,
              barWidth: 0,
              dotData: FlDotData(
                show: true,
                getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                  radius: 3,
                  color: AppColors.danger,
                  strokeWidth: 0,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ReactiveTab extends ConsumerWidget {
  const _ReactiveTab({required this.meterPointId});
  final String meterPointId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readingsAsync = ref.watch(readingsProvider(meterPointId));
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(readingsProvider(meterPointId)),
      child: readingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Błąd: $e')),
        data: (readings) {
          if (readings.isEmpty) {
            return ListView(children: const [
              SizedBox(height: 80),
              Center(child: Text('Brak danych o energii biernej.')),
            ]);
          }
          final take = readings.take(30).toList().reversed.toList();
          final maxY = take.fold<double>(0, (m, r) {
            final v = (r.inductiveKvarh ?? 0) > (r.capacitiveKvarh ?? 0)
                ? (r.inductiveKvarh ?? 0)
                : (r.capacitiveKvarh ?? 0);
            return v > m ? v : m;
          });
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SizedBox(
                height: 280,
                child: BarChart(
                  BarChartData(
                    maxY: maxY == 0 ? 1 : maxY * 1.1,
                    gridData:
                        const FlGridData(show: true, drawVerticalLine: false),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 36,
                          getTitlesWidget: (v, _) => Text(
                            v.toStringAsFixed(0),
                            style: const TextStyle(
                                fontSize: 10, color: AppColors.mutedFg),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 22,
                          interval: (take.length / 5)
                              .clamp(1, 1000)
                              .toDouble(),
                          getTitlesWidget: (v, _) {
                            final idx = v.toInt();
                            if (idx < 0 || idx >= take.length) {
                              return const SizedBox.shrink();
                            }
                            return Text(
                              Fmt.date(take[idx].date)
                                  .substring(0, 5), // dd.MM
                              style: const TextStyle(
                                  fontSize: 9, color: AppColors.mutedFg),
                            );
                          },
                        ),
                      ),
                    ),
                    barGroups: [
                      for (int i = 0; i < take.length; i++)
                        BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: take[i].inductiveKvarh ?? 0,
                              color: AppColors.primary,
                              width: 5,
                            ),
                            BarChartRodData(
                              toY: take[i].capacitiveKvarh ?? 0,
                              color: AppColors.teal,
                              width: 5,
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  _Legend(color: AppColors.primary, label: 'Indukcyjna'),
                  SizedBox(width: 16),
                  _Legend(color: AppColors.teal, label: 'Pojemnościowa'),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(fontSize: 12, color: AppColors.mutedFg)),
      ],
    );
  }
}

class _ReadingsTab extends ConsumerWidget {
  const _ReadingsTab({required this.meterPointId});
  final String meterPointId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readingsAsync = ref.watch(readingsProvider(meterPointId));
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(readingsProvider(meterPointId)),
      child: readingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Błąd: $e')),
        data: (readings) {
          if (readings.isEmpty) {
            return ListView(children: const [
              SizedBox(height: 80),
              Center(child: Text('Brak odczytów.')),
            ]);
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: readings.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final r = readings[i];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(Fmt.date(r.date),
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  'T1: ${Fmt.kwh(r.activeT1Kwh)} • T2: ${Fmt.kwh(r.activeT2Kwh)}',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Q+: ${Fmt.kvarh(r.inductiveKvarh)}',
                        style: const TextStyle(fontSize: 12)),
                    Text('Q-: ${Fmt.kvarh(r.capacitiveKvarh)}',
                        style: const TextStyle(fontSize: 12)),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
