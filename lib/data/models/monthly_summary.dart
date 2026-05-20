class MonthlySummary {
  final String meterPointId;
  final double consumedKwhMtd;
  final double reactiveInductiveKvarhMtd;
  final double reactiveCapacitiveKvarhMtd;
  final double? currentTgPhi;
  final double? projectedTgPhiEom;
  final int exceedanceCount;
  final String status; // 'ok' | 'yellow' | 'red'

  const MonthlySummary({
    required this.meterPointId,
    required this.consumedKwhMtd,
    required this.reactiveInductiveKvarhMtd,
    required this.reactiveCapacitiveKvarhMtd,
    this.currentTgPhi,
    this.projectedTgPhiEom,
    this.exceedanceCount = 0,
    this.status = 'ok',
  });

  factory MonthlySummary.fromJson(Map<String, dynamic> json) => MonthlySummary(
        meterPointId: json['meter_point_id'] as String,
        consumedKwhMtd: (json['consumed_kwh_mtd'] as num?)?.toDouble() ?? 0,
        reactiveInductiveKvarhMtd:
            (json['reactive_inductive_kvarh_mtd'] as num?)?.toDouble() ?? 0,
        reactiveCapacitiveKvarhMtd:
            (json['reactive_capacitive_kvarh_mtd'] as num?)?.toDouble() ?? 0,
        currentTgPhi: (json['current_tg_phi'] as num?)?.toDouble(),
        projectedTgPhiEom:
            (json['projected_tg_phi_eom'] as num?)?.toDouble(),
        exceedanceCount: (json['exceedance_count'] as num?)?.toInt() ?? 0,
        status: json['status'] as String? ?? 'ok',
      );
}
