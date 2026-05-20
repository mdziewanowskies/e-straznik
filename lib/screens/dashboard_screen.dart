import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/models/meter_point.dart';
import '../providers/auth_providers.dart';
import '../providers/dashboard_providers.dart';
import '../theme/colors.dart';
import '../utils/formatters.dart';
import '../widgets/mascot.dart';
import '../widgets/mascot_refresh_indicator.dart';
import '../widgets/meter_point_card.dart';
import '../widgets/offline_banner.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(dashboardProvider);
    final org = ref.watch(organizationProvider).valueOrNull;
    final profile = ref.watch(profileProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _GradientHeader(
            orgName: org?.name,
            userName: profile?.fullName ?? profile?.email,
            onAlerts: () => context.push('/alerts'),
            onSettings: () => context.push('/settings'),
          ),
          const OfflineBanner(),
          Expanded(
            child: MascotRefreshIndicator(
              onRefresh: () async {
                HapticFeedback.selectionClick();
                await ref.refresh(dashboardProvider.future);
              },
              child: dashboard.when(
                loading: () => const _LoadingState(),
                error: (e, _) => _ErrorView(
                  message: e.toString(),
                  onRetry: () => ref.invalidate(dashboardProvider),
                ),
                data: (data) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    children: [
                      _SyncStatusCard(account: data.tauronAccount),
                      const SizedBox(height: 20),
                      _SectionHeader(
                        title: 'Twoje punkty PPE',
                        count: data.meterPoints.length,
                      ),
                      const SizedBox(height: 12),
                      if (data.meterPoints.isEmpty)
                        const _EmptyState()
                      else
                        ...data.meterPoints.map((mp) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: MeterPointCard(
                                meterPoint: mp,
                                summary: data.summariesByMpId[mp.id],
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  context.push('/ppe/${mp.id}');
                                },
                              ),
                            )),
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

class _GradientHeader extends StatelessWidget {
  const _GradientHeader({
    required this.orgName,
    required this.userName,
    required this.onAlerts,
    required this.onSettings,
  });
  final String? orgName;
  final String? userName;
  final VoidCallback onAlerts;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.gradientHero,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 12, 20),
          child: Row(
            children: [
              const Mascot(size: 44, glow: false),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      orgName ?? 'e-Strażnik',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (userName != null)
                      Text(
                        userName!,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              _IconBtn(
                icon: Icons.notifications_outlined,
                onTap: () {
                  HapticFeedback.lightImpact();
                  onAlerts();
                },
                tooltip: 'Alerty',
              ),
              const SizedBox(width: 6),
              _IconBtn(
                icon: Icons.person_outline,
                onTap: () {
                  HapticFeedback.lightImpact();
                  onSettings();
                },
                tooltip: 'Ustawienia',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.12),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}

class _SyncStatusCard extends StatelessWidget {
  const _SyncStatusCard({required this.account});
  final TauronAccount? account;

  @override
  Widget build(BuildContext context) {
    final ok = account?.isHealthy ?? account == null;
    final Color color = ok ? AppColors.success : AppColors.danger;
    final IconData icon =
        ok ? Icons.cloud_done_outlined : Icons.cloud_off_outlined;
    final String title = account == null
        ? 'Brak danych o synchronizacji'
        : ok
            ? 'Dane są aktualne'
            : 'Problem z synchronizacją';
    final String? subtitle = account == null
        ? 'Dane aktualizują się raz dziennie rano.'
        : ok
            ? 'Ostatnia synchronizacja: ${Fmt.dateTime(account!.lastSyncAt)}'
            : (account!.lastSyncError ??
                'Nie udało się pobrać danych z Tauronu.');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A101A33),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.foreground,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.mutedFg,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.count});
  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.foreground,
            letterSpacing: -0.1,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.muted,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.mutedFg,
            ),
          ),
        ),
      ],
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        for (int i = 0; i < 3; i++) ...[
          _ShimmerCard(height: i == 0 ? 70 : 160),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard({required this.height});
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.muted,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Mascot(size: 110),
          const SizedBox(height: 12),
          const Text(
            'Brak punktów PPE',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.foreground,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Skonfiguruj konto Tauron i wybierz punkty poboru w panelu webowym e-strażnika. Tutaj zobaczysz status liczników.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.mutedFg,
              fontSize: 13,
              height: 1.5,
            ),
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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline,
                  color: AppColors.danger, size: 36),
            ),
            const SizedBox(height: 16),
            const Text(
              'Nie udało się załadować danych',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: AppColors.foreground,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.mutedFg, fontSize: 12.5),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Spróbuj ponownie'),
            ),
          ],
        ),
      ),
    );
  }
}
