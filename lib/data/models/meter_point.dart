class MeterPoint {
  final String id;
  final String label;
  final String ppeNumber;
  final String? tariff;
  final double? mocUmownaKw;
  final double? tgPhiLimit;
  final bool monitoringEnabled;

  const MeterPoint({
    required this.id,
    required this.label,
    required this.ppeNumber,
    this.tariff,
    this.mocUmownaKw,
    this.tgPhiLimit,
    this.monitoringEnabled = true,
  });

  factory MeterPoint.fromJson(Map<String, dynamic> json) => MeterPoint(
        id: json['id'] as String,
        label: json['label'] as String? ?? '',
        ppeNumber: json['ppe_number'] as String? ?? '',
        tariff: json['tariff'] as String?,
        mocUmownaKw: (json['moc_umowna_kw'] as num?)?.toDouble(),
        tgPhiLimit: (json['tg_phi_limit'] as num?)?.toDouble(),
        monitoringEnabled: json['monitoring_enabled'] as bool? ?? true,
      );
}

class TauronAccount {
  final String id;
  final DateTime? lastSyncAt;
  final String? lastSyncStatus;
  final String? lastSyncError;

  const TauronAccount({
    required this.id,
    this.lastSyncAt,
    this.lastSyncStatus,
    this.lastSyncError,
  });

  bool get isHealthy => lastSyncStatus == 'ok';

  factory TauronAccount.fromJson(Map<String, dynamic> json) => TauronAccount(
        id: json['id'] as String,
        lastSyncAt: json['last_sync_at'] != null
            ? DateTime.parse(json['last_sync_at'] as String).toLocal()
            : null,
        lastSyncStatus: json['last_sync_status'] as String?,
        lastSyncError: json['last_sync_error'] as String?,
      );
}
