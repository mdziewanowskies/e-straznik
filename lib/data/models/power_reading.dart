class Power15MinReading {
  final DateTime timestamp;
  final double powerKw;
  final double? pumKw;
  final double? exceedanceKw;

  const Power15MinReading({
    required this.timestamp,
    required this.powerKw,
    this.pumKw,
    this.exceedanceKw,
  });

  factory Power15MinReading.fromJson(Map<String, dynamic> json) =>
      Power15MinReading(
        timestamp:
            DateTime.parse(json['timestamp_15min'] as String).toLocal(),
        powerKw: (json['power_kw'] as num?)?.toDouble() ?? 0,
        pumKw: (json['pum_kw'] as num?)?.toDouble(),
        exceedanceKw: (json['exceedance_kw'] as num?)?.toDouble(),
      );
}

class PowerExceedance {
  final String id;
  final String meterPointId;
  final DateTime occurredAt;
  final double exceedanceKw;
  final double? powerKw;
  final double? pumKw;

  const PowerExceedance({
    required this.id,
    required this.meterPointId,
    required this.occurredAt,
    required this.exceedanceKw,
    this.powerKw,
    this.pumKw,
  });

  factory PowerExceedance.fromJson(Map<String, dynamic> json) =>
      PowerExceedance(
        id: json['id'] as String,
        meterPointId: json['meter_point_id'] as String,
        occurredAt: DateTime.parse(
                (json['occurred_at'] ?? json['timestamp_15min']) as String)
            .toLocal(),
        exceedanceKw: (json['exceedance_kw'] as num?)?.toDouble() ?? 0,
        powerKw: (json['power_kw'] as num?)?.toDouble(),
        pumKw: (json['pum_kw'] as num?)?.toDouble(),
      );
}

class Reading {
  final String id;
  final DateTime date;
  final double? activeT1Kwh;
  final double? activeT2Kwh;
  final double? inductiveKvarh;
  final double? capacitiveKvarh;
  final double? exportKwh;

  const Reading({
    required this.id,
    required this.date,
    this.activeT1Kwh,
    this.activeT2Kwh,
    this.inductiveKvarh,
    this.capacitiveKvarh,
    this.exportKwh,
  });

  factory Reading.fromJson(Map<String, dynamic> json) => Reading(
        id: json['id'] as String,
        date: DateTime.parse(
                (json['reading_date'] ?? json['date'] ?? json['day']) as String)
            .toLocal(),
        activeT1Kwh: (json['active_t1_kwh'] as num?)?.toDouble(),
        activeT2Kwh: (json['active_t2_kwh'] as num?)?.toDouble(),
        inductiveKvarh: (json['reactive_inductive_kvarh'] as num?)?.toDouble(),
        capacitiveKvarh:
            (json['reactive_capacitive_kvarh'] as num?)?.toDouble(),
        exportKwh: (json['export_kwh'] as num?)?.toDouble(),
      );
}
