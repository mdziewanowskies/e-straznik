import 'package:flutter/material.dart';

import '../data/models/meter_point.dart';
import '../theme/colors.dart';
import '../utils/formatters.dart';

class SyncStatusBanner extends StatelessWidget {
  const SyncStatusBanner({super.key, required this.account});
  final TauronAccount? account;

  @override
  Widget build(BuildContext context) {
    if (account == null) {
      return _buildBox(
        context,
        color: AppColors.mutedFg,
        icon: Icons.info_outline,
        title: 'Brak danych o synchronizacji',
        subtitle: 'Dane aktualizują się raz dziennie rano.',
      );
    }
    final ok = account!.isHealthy;
    return _buildBox(
      context,
      color: ok ? AppColors.success : AppColors.danger,
      icon: ok ? Icons.cloud_done_outlined : Icons.error_outline,
      title: ok
          ? 'Ostatnia synchronizacja: ${Fmt.dateTime(account!.lastSyncAt)}'
          : 'Problem z ostatnią synchronizacją',
      subtitle: ok
          ? 'Dane aktualizują się raz dziennie rano.'
          : account!.lastSyncError ?? 'Nie udało się pobrać danych z Tauronu.',
    );
  }

  Widget _buildBox(
    BuildContext context, {
    required Color color,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                      color: AppColors.mutedFg, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
