import 'package:flutter/material.dart';

import '../data/models/meter_point.dart';
import '../data/models/monthly_summary.dart';
import '../theme/colors.dart';
import '../utils/formatters.dart';
import 'status_badge.dart';

class MeterPointCard extends StatelessWidget {
  const MeterPointCard({
    super.key,
    required this.meterPoint,
    required this.summary,
    required this.onTap,
  });

  final MeterPoint meterPoint;
  final MonthlySummary? summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final exceedances = summary?.exceedanceCount ?? 0;
    final status = summary?.status ?? 'ok';

    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F101A33),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: nazwa + status
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.statusColor(status)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.bolt_rounded,
                      color: AppColors.statusColor(status),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Hero(
                          tag: 'mp-title-${meterPoint.id}',
                          child: Material(
                            color: Colors.transparent,
                            child: Text(
                              meterPoint.label,
                              style: const TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.foreground,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'PPE ${meterPoint.ppeNumber}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.mutedFg,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(status: status),
                ],
              ),
              const SizedBox(height: 14),
              // Chipy: taryfa + moc
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _Chip(
                    icon: Icons.label_outline,
                    text: 'Taryfa ${meterPoint.tariff ?? '—'}',
                  ),
                  _Chip(
                    icon: Icons.power_outlined,
                    text: 'Moc ${Fmt.kw(meterPoint.mocUmownaKw)}',
                  ),
                  if (exceedances > 0)
                    _Chip(
                      icon: Icons.warning_amber_rounded,
                      text: '$exceedances przekroczeń',
                      color: AppColors.danger,
                    ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 12),
              // 3 KPI w jednym rzędzie
              Row(
                children: [
                  Expanded(
                    child: _MiniKpi(
                      label: 'Zużycie',
                      value: Fmt.kwh(summary?.consumedKwhMtd),
                      hint: 'MTD',
                    ),
                  ),
                  Container(
                      width: 1, height: 32, color: AppColors.border),
                  Expanded(
                    child: _MiniKpi(
                      label: 'tg φ',
                      value: Fmt.tgPhi(summary?.currentTgPhi),
                      hint: 'aktualny',
                      valueColor: _tgColor(
                          summary?.currentTgPhi, meterPoint.tgPhiLimit),
                    ),
                  ),
                  Container(
                      width: 1, height: 32, color: AppColors.border),
                  Expanded(
                    child: _MiniKpi(
                      label: 'Bierna ind.',
                      value: Fmt.kvarh(summary?.reactiveInductiveKvarhMtd),
                      hint: 'MTD',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color? _tgColor(double? value, double? limit) {
    if (value == null || limit == null) return null;
    if (value > limit) return AppColors.danger;
    if (value > limit * 0.9) return AppColors.warning;
    return null;
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.text, this.color});
  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.foreground;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color != null
            ? c.withValues(alpha: 0.1)
            : AppColors.muted,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: c.withValues(alpha: 0.8)),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              fontSize: 11.5,
              color: c,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniKpi extends StatelessWidget {
  const _MiniKpi({
    required this.label,
    required this.value,
    required this.hint,
    this.valueColor,
  });
  final String label;
  final String value;
  final String hint;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.mutedFg,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: valueColor ?? AppColors.foreground,
              letterSpacing: -0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            hint,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.mutedFg,
            ),
          ),
        ],
      ),
    );
  }
}
