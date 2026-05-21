import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/supabase_provider.dart';
import '../services/push_diagnostics.dart';
import '../theme/colors.dart';

class PushDiagnosticsScreen extends ConsumerWidget {
  const PushDiagnosticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(pushDiagnosticsProvider);
    final service = ref.watch(pushNotificationServiceProvider);
    final isBusy = status.stage == PushStage.requestingPermission ||
        status.stage == PushStage.waitingApns ||
        status.stage == PushStage.fetchingFcm ||
        status.stage == PushStage.registering;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Diagnostyka push'),
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _StatusCard(status: status),
          const SizedBox(height: 16),
          _InfoRow(label: 'Etap', value: status.humanStage),
          if (status.message != null)
            _InfoRow(label: 'Szczegóły', value: status.message!, multiline: true),
          if (status.apnsTokenPrefix != null)
            _InfoRow(
                label: 'APNS token', value: '${status.apnsTokenPrefix}…'),
          if (status.fcmTokenPrefix != null)
            _InfoRow(
                label: 'FCM token', value: '${status.fcmTokenPrefix}…'),
          if (status.lastResponseCode != null)
            _InfoRow(
                label: 'HTTP status',
                value: '${status.lastResponseCode}',
                color: status.lastResponseCode == 200
                    ? AppColors.success
                    : AppColors.danger),
          if (status.lastResponseBody != null &&
              status.lastResponseBody!.isNotEmpty)
            _InfoRow(
                label: 'Response body',
                value: status.lastResponseBody!,
                multiline: true),
          _InfoRow(
              label: 'Endpoint',
              value: 'POST https://e-straznik.com/api/public/devices/register',
              multiline: true),
          _InfoRow(
              label: 'Zaktualizowano',
              value: DateFormat('HH:mm:ss').format(status.updatedAt)),
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: (isBusy || service == null)
                  ? null
                  : () {
                      HapticFeedback.mediumImpact();
                      service.runDiagnostics();
                    },
              icon: isBusy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white),
                    )
                  : const Icon(Icons.refresh_rounded),
              label: Text(isBusy
                  ? 'Trwa…'
                  : 'Spróbuj rejestracji ponownie'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const _Hints(),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.status});
  final PushStatus status;

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    switch (status.stage) {
      case PushStage.registered:
        color = AppColors.success;
        icon = Icons.check_circle_rounded;
        break;
      case PushStage.permissionDenied:
      case PushStage.apnsTimeout:
      case PushStage.fcmNull:
      case PushStage.registerFailed:
      case PushStage.error:
        color = AppColors.danger;
        icon = Icons.error_rounded;
        break;
      case PushStage.idle:
        color = AppColors.mutedFg;
        icon = Icons.help_outline_rounded;
        break;
      default:
        color = AppColors.warning;
        icon = Icons.hourglass_top_rounded;
    }
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  status.humanStage,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                if (status.message != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    status.message!,
                    style: const TextStyle(
                        fontSize: 12.5, color: AppColors.mutedFg),
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.color,
    this.multiline = false,
  });
  final String label;
  final String value;
  final Color? color;
  final bool multiline;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.mutedFg,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              maxLines: multiline ? null : 1,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: color ?? AppColors.foreground,
                fontFamily: multiline ? 'Menlo' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Hints extends StatelessWidget {
  const _Hints();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.muted,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Co sprawdzić jeśli APNS timeout',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.foreground),
          ),
          SizedBox(height: 8),
          Text(
            '• iOS Settings → e-Strażnik → Powiadomienia: musi być Zezwól.\n'
            '• Xcode → Runner target → Signing & Capabilities → Push Notifications musi być dodane.\n'
            '• Firebase Console → Project Settings → Cloud Messaging → APNs Authentication Key (.p8) musi być wgrany.\n'
            '• Bundle ID w Xcode musi zgadzać się z Bundle ID w Firebase.\n'
            '• Po zmianie Info.plist trzeba zrobić nowy Archive — hot reload nie wystarczy.',
            style: TextStyle(fontSize: 12, color: AppColors.mutedFg, height: 1.5),
          ),
        ],
      ),
    );
  }
}
