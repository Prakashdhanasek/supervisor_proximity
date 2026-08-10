class IncidentAlertSetting {
  final String id;
  final String incidentType;
  final int intervalSecs;
  final int? speedThresholdKmh;
  final DateTime? updatedAt;

  IncidentAlertSetting({
    required this.id,
    required this.incidentType,
    required this.intervalSecs,
    this.speedThresholdKmh,
    this.updatedAt,
  });

  factory IncidentAlertSetting.fromJson(Map<String, dynamic> json) {
    return IncidentAlertSetting(
      id: json['id'] as String,
      incidentType: json['incidentType'] as String,
      intervalSecs: json['intervalSecs'] as int,
      speedThresholdKmh: json['speedThresholdKmh'] as int?,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'incidentType': incidentType,
    'intervalSecs': intervalSecs,
    'speedThresholdKmh': speedThresholdKmh,
  };

  IncidentAlertSetting copyWith({int? intervalSecs, int? speedThresholdKmh}) {
    return IncidentAlertSetting(
      id: id,
      incidentType: incidentType,
      intervalSecs: intervalSecs ?? this.intervalSecs,
      speedThresholdKmh: speedThresholdKmh ?? this.speedThresholdKmh,
      updatedAt: updatedAt,
    );
  }
}
