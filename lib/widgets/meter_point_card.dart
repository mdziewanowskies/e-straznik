import 'package:flutter/material.dart';

import '../data/models/meter_point.dart';
import '../data/models/monthly_summary.dart';
import '../theme/colors.dart';
import '../utils/formatters.dart';
import 'kpi_tile.dart';
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
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F101A33),
                blurRadius: 18,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Hero(
                          tag: 'mp-title-${meterPoint.id}',
                          child: Material(
                            color: Colors.transparent,
                            child: Text(
                              meterPoint.label,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: AppColors.foreground,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'PPE ${meterPoint.ppeNumber}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.mutedFg,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(status: summary?.status ?? 'ok'),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _chip('Taryfa ${meterPoint.tariff ?? '—'}'),
                  const SizedBox(width: 8),
                  _chip('Moc ${Fmt.kw(meterPoint.mocUmownaKw)}'),
                ],
              ),
              const SizedBox(height: 14),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 2.3,
                children: [
                  KpiTile(
                    label: 'Zużycie MTD',
                    value: Fmt.kwh(summary?.consumedKwhMtd),
                    icon: Icons.bolt,
                  ),
                  KpiTile(
                    label: 'Bierna indukc. MTD',
                    value: Fmt.kvarh(summary?.reactiveInductiveKvarhMtd),
                    icon: Icons.flash_on,
                  ),
                  KpiTile(
                    label: 'tg φ aktualny',
                    value: Fmt.tgPhi(summary?.currentTgPhi),
                    icon: Icons.show_chart,
                  ),
                  KpiTile(
                    label: 'Przekroczenia',
                    value: '${summary?.exceedanceCount ?? 0}',
                    icon: Icons.warning_amber_rounded,
                    color: (summary?.exceedanceCount ?? 0) > 0
                        ? AppColors.danger
                        : AppColors.foreground,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.muted,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.foreground,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
