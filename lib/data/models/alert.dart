class AppAlert {
  final String id;
  final String type;
  final String severity; // info | warning | critical
  final String title;
  final String message;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final DateTime? acknowledgedAt;
  final DateTime? notifiedAt;
  final String? meterPointId;

  const AppAlert({
    required this.id,
    required this.type,
    required this.severity,
    required this.title,
    required this.message,
    required this.createdAt,
    this.payload = const {},
    this.acknowledgedAt,
    this.notifiedAt,
    this.meterPointId,
  });

  bool get isRead => acknowledgedAt != null;

  factory AppAlert.fromJson(Map<String, dynamic> json) => AppAlert(
        id: json['id'] as String,
        type: json['type'] as String? ?? 'info',
        severity: json['severity'] as String? ?? 'info',
        title: json['title'] as String? ?? '',
        message: json['message'] as String? ?? '',
        payload:
            (json['payload'] as Map?)?.cast<String, dynamic>() ?? const {},
        createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
        acknowledgedAt: json['acknowledged_at'] != null
            ? DateTime.parse(json['acknowledged_at'] as String).toLocal()
            : null,
        notifiedAt: json['notified_at'] != null
            ? DateTime.parse(json['notified_at'] as String).toLocal()
            : null,
        meterPointId: json['meter_point_id'] as String?,
      );
}
