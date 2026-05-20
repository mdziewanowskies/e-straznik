import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/models/alert.dart';
import '../providers/alerts_providers.dart';
import '../providers/supabase_provider.dart';
import '../theme/colors.dart';
import '../utils/formatters.dart';
import '../widgets/offline_banner.dart';
import '../widgets/status_badge.dart';

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(alertsProvider);
    final filter = ref.watch(alertsFilterProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Powiadomienia')),
      body: Column(
        children: [
          const OfflineBanner(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: _FilterDropdown<String>(
                    label: 'Ważność',
                    value: filter.severity,
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Wszystkie')),
                      DropdownMenuItem(value: 'critical', child: Text('Krytyczne')),
                      DropdownMenuItem(value: 'warning', child: Text('Ostrzeżenia')),
                      DropdownMenuItem(value: 'info', child: Text('Info')),
                    ],
                    onChanged: (v) =>
                        ref.read(alertsFilterProvider.notifier).setSeverity(v),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _FilterDropdown<String>(
                    label: 'Typ',
                    value: filter.type,
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Wszystkie')),
                      DropdownMenuItem(
                          value: 'power_exceedance',
                          child: Text('Przekroczenie mocy')),
                      DropdownMenuItem(
                          value: 'tg_phi_high', child: Text('Wysoki tg φ')),
                      DropdownMenuItem(
                          value: 'reactive_capacitive',
                          child: Text('Energia pojem.')),
                      DropdownMenuItem(
                          value: 'sync_error', child: Text('Błąd synchr.')),
                    ],
                    onChanged: (v) =>
                        ref.read(alertsFilterProvider.notifier).setType(v),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.refresh(alertsProvider.future),
              child: alertsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) =>
                    Center(child: Text('Nie udało się załadować: $e')),
                data: (alerts) {
                  if (alerts.isEmpty) {
                    return ListView(
                      children: const [
                        SizedBox(height: 120),
                        Center(child: Text('Brak alertów.')),
                      ],
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: alerts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => _AlertTile(
                      alert: alerts[i],
                      onTap: () => context.push('/alerts/${alerts[i].id}'),
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

class _FilterDropdown<T> extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T? value;
  final List<DropdownMenuItem<T?>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T?>(
          isExpanded: true,
          value: value,
          items: items,
          onChanged: onChanged,
        ),
      ),
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
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: unread
                  ? AppColors.severityColor(alert.severity)
                      .withValues(alpha: 0.35)
                  : AppColors.border,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 8,
                margin: const EdgeInsets.only(top: 4, right: 10),
                child: unread
                    ? Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.severityColor(alert.severity),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SeverityBadge(severity: alert.severity),
                        const Spacer(),
                        Text(
                          Fmt.dateTime(alert.createdAt),
                          style: const TextStyle(
                              color: AppColors.mutedFg, fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      alert.title,
                      style: TextStyle(
                        fontWeight:
                            unread ? FontWeight.w700 : FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      alert.message,
                      style: const TextStyle(
                          color: AppColors.mutedFg, fontSize: 12.5),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
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
    // Mark as read on open.
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
      appBar: AppBar(title: const Text('Alert')),
      body: alertAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Błąd: $e')),
        data: (alert) {
          if (alert == null) {
            return const Center(child: Text('Nie znaleziono alertu.'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  SeverityBadge(severity: alert.severity),
                  const Spacer(),
                  Text(
                    Fmt.dateTime(alert.createdAt),
                    style:
                        const TextStyle(color: AppColors.mutedFg, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(alert.title,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(alert.message,
                  style:
                      const TextStyle(fontSize: 14, color: AppColors.foreground)),
              if (alert.payload.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text('Szczegóły',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.muted,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    alert.payload.entries
                        .map((e) => '${e.key}: ${e.value}')
                        .join('\n'),
                    style: const TextStyle(fontSize: 12.5),
                  ),
                ),
              ],
              if (alert.meterPointId != null) ...[
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () => context.push('/ppe/${alert.meterPointId}'),
                  icon: const Icon(Icons.bolt),
                  label: const Text('Otwórz PPE'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
