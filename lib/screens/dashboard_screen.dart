import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_providers.dart';
import '../providers/dashboard_providers.dart';
import '../theme/colors.dart';
import '../widgets/mascot.dart';
import '../widgets/meter_point_card.dart';
import '../widgets/offline_banner.dart';
import '../widgets/sync_status_banner.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(dashboardProvider);
    final org = ref.watch(organizationProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dashboard'),
            if (org != null)
              Text(
                org.name,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.mutedFg),
              ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Alerty',
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push('/alerts'),
          ),
          IconButton(
            tooltip: 'Ustawienia',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.refresh(dashboardProvider.future),
              child: dashboard.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => _ErrorView(
                  message: e.toString(),
                  onRetry: () => ref.invalidate(dashboardProvider),
                ),
                data: (data) {
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      SyncStatusBanner(account: data.tauronAccount),
                      const SizedBox(height: 16),
                      if (data.meterPoints.isEmpty)
                        const _EmptyState()
                      else
                        ...data.meterPoints.map((mp) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: MeterPointCard(
                                meterPoint: mp,
                                summary: data.summariesByMpId[mp.id],
                                onTap: () => context.push('/ppe/${mp.id}'),
                              ),
                            )),
                      const SizedBox(height: 24),
                    ],
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Mascot(size: 96),
          const SizedBox(height: 16),
          const Text(
            'Nie masz jeszcze żadnego PPE',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Skonfiguruj konto Tauron i wybierz punkty poboru w panelu webowym e-strażnika.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.mutedFg, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                color: AppColors.danger, size: 48),
            const SizedBox(height: 12),
            const Text(
              'Nie udało się załadować danych',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.mutedFg, fontSize: 12),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Spróbuj ponownie'),
            ),
          ],
        ),
      ),
    );
  }
}
