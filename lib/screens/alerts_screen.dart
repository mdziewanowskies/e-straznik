import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/models/alert.dart';
import '../providers/alerts_providers.dart';
import '../providers/supabase_provider.dart';
import '../theme/colors.dart';
import '../utils/formatters.dart';
import '../widgets/mascot_refresh_indicator.dart';
import '../widgets/offline_banner.dart';
import '../widgets/status_badge.dart';

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(alertsProvider);
    final filter = ref.watch(alertsFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Alerty')),
      body: Column(
        children: [
          const OfflineBanner(),
          // Filtry — segment chipów
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _FilterChip(
                  label: 'Wszystkie',
                  selected: filter.severity == null,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref.read(alertsFilterProvider.notifier).setSeverity(null);
                  },
                ),
                _FilterChip(
                  label: 'Krytyczne',
                  selected: filter.severity == 'critical',
                  color: AppColors.danger,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref
                        .read(alertsFilterProvider.notifier)
                        .setSeverity('critical');
                  },
                ),
                _FilterChip(
                  label: 'Ostrzeżenia',
                  selected: filter.severity == 'warning',
                  color: AppColors.warning,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref
                        .read(alertsFilterProvider.notifier)
                        .setSeverity('warning');
                  },
                ),
                _FilterChip(
                  label: 'Info',
                  selected: filter.severity == 'info',
                  color: AppColors.primary,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref
                        .read(alertsFilterProvider.notifier)
                        .setSeverity('info');
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: MascotRefreshIndicator(
              onRefresh: () async {
                HapticFeedback.selectionClick();
                await ref.refresh(alertsProvider.future);
              },
              child: alertsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) =>
                    Center(child: Text('Nie udało się załadować: $e')),
                data: (alerts) {
                  if (alerts.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        _EmptyAlerts(hasFilter: filter.severity != null),
                      ],
                    );
                  }
                  return ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    itemCount: alerts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => _AlertTile(
                      alert: alerts[i],
                      onTap: () {
                        HapticFeedback.lightImpact();
                        context.push('/alerts/${alerts[i].id}');
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final base = color ?? AppColors.primary;
    return Padding(
      padding: const EdgeInsets.only(right: 8, top: 6, bottom: 6),
      child: Material(
        color: selected ? base : AppColors.card,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected ? base : AppColors.border,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.foreground,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyAlerts extends StatelessWidget {
  const _EmptyAlerts({required this.hasFilter});
  final bool hasFilter;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 60),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_outline_rounded,
            size: 48,
            color: AppColors.success,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          hasFilter ? 'Brak alertów w tej kategorii' : 'Wszystko gra!',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.foreground,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Nie ma żadnych alertów do wyświetlenia. Damy Ci znać, gdy coś się wydarzy.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.mutedFg,
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({required this.alert, required this.onTap});
  final AppAlert alert;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unread = !alert.isRead;
    final color = AppColors.severityColor(alert.severity);
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Severity icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(_iconFor(alert), color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            alert.title,
                            style: TextStyle(
                              fontWeight: unread
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              fontSize: 14,
                              color: AppColors.foreground,
                              letterSpacing: -0.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (unread) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      alert.message,
                      style: const TextStyle(
                        color: AppColors.mutedFg,
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        SeverityBadge(severity: alert.severity),
                        const Spacer(),
                        Text(
                          Fmt.dateTime(alert.createdAt),
                          style: const TextStyle(
                            color: AppColors.mutedFg,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(AppAlert a) {
    switch (a.type) {
      case 'power_exceedance':
        return Icons.bolt_rounded;
      case 'tg_phi_high':
        return Icons.show_chart_rounded;
      case 'reactive_capacitive':
        return Icons.electrical_services_rounded;
      case 'sync_error':
        return Icons.cloud_off_rounded;
      default:
        return Icons.notifications_active_outlined;
    }
  }
}

class AlertDetailScreen extends ConsumerStatefulWidget {
  const AlertDetailScreen({super.key, required this.alertId});
  final String alertId;

  @override
  ConsumerState<AlertDetailScreen> createState() => _AlertDetailScreenState();
}

class _AlertDetailScreenState extends ConsumerState<AlertDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await ref
            .read(alertsRepositoryProvider)
            .markAcknowledged(widget.alertId);
        ref.invalidate(alertsProvider);
        ref.invalidate(alertDetailProvider(widget.alertId));
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    final alertAsync = ref.watch(alertDetailProvider(widget.alertId));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Alert')),
      body: alertAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Błąd: $e')),
        data: (alert) {
          if (alert == null) {
            return const Center(child: Text('Nie znaleziono alertu.'));
          }
          final color = AppColors.severityColor(alert.severity);
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    _iconForType(alert.type),
                    color: color,
                    size: 34,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Center(child: SeverityBadge(severity: alert.severity)),
              const SizedBox(height: 14),
              Text(
                alert.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.foreground,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  Fmt.dateTime(alert.createdAt),
                  style: const TextStyle(
                    color: AppColors.mutedFg,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  alert.message,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.foreground,
                    height: 1.5,
                  ),
                ),
              ),
              if (alert.payload.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    'SZCZEGÓŁY',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.mutedFg,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final e in alert.payload.entries)
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 130,
                                child: Text(
                                  e.key,
                                  style: const TextStyle(
                                    color: AppColors.mutedFg,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  '${e.value}',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.foreground,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              if (alert.meterPointId != null) ...[
                const SizedBox(height: 20),
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      context.push('/ppe/${alert.meterPointId}');
                    },
                    icon: const Icon(Icons.bolt_rounded, size: 18),
                    label: const Text('Otwórz punkt PPE'),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'power_exceedance':
        return Icons.bolt_rounded;
      case 'tg_phi_high':
        return Icons.show_chart_rounded;
      case 'reactive_capacitive':
        return Icons.electrical_services_rounded;
      case 'sync_error':
        return Icons.cloud_off_rounded;
      default:
        return Icons.notifications_active_outlined;
    }
  }
}
