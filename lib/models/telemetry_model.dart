class TelemetryModel {
  final String deviceId;
  final bool helmetWorn;
  final bool alcoholDetected;
  final double bacLevel;
  final double latitude;
  final double longitude;
  final double speedKmh;
  final int batteryPercentage;
  final double? batteryVoltage;
  final double? impactG;
  final double? tiltDegrees;
  final String ignitionStatus;
  final String? lockReason;
  final DateTime timestamp;

  TelemetryModel({
    required this.deviceId,
    required this.helmetWorn,
    required this.alcoholDetected,
    required this.bacLevel,
    required this.latitude,
    required this.longitude,
    required this.speedKmh,
    required this.batteryPercentage,
    this.batteryVoltage,
    this.impactG,
    this.tiltDegrees,
    required this.ignitionStatus,
    this.lockReason,
    required this.timestamp,
  });

  factory TelemetryModel.fromJson(Map<String, dynamic> json) {
    return TelemetryModel(
      deviceId: json['device_id'] ?? 'HLM-ESP32-001',
      helmetWorn: json['helmet_worn'] ?? false,
      alcoholDetected: json['alcohol_detected'] ?? false,
      bacLevel: (json['bac_level'] as num?)?.toDouble() ?? 0.0,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 6.5244,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 3.3792,
      speedKmh: (json['speed_kmh'] as num?)?.toDouble() ?? 0.0,
      batteryPercentage: json['battery_percentage'] ?? 100,
      batteryVoltage: (json['battery_voltage'] as num?)?.toDouble() ?? 4.05,
      impactG: (json['impact_g'] as num?)?.toDouble() ?? 1.0,
      tiltDegrees: (json['tilt_degrees'] as num?)?.toDouble() ?? 0.0,
      ignitionStatus: json['ignition_status'] ?? 'LOCKED',
      lockReason: json['lock_reason'] ?? 'NONE',
      timestamp: json['timestamp'] != null 
          ? DateTime.tryParse(json['timestamp']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  bool get isUnlocked => ignitionStatus == 'UNLOCKED' || ignitionStatus == 'RUNNING_LATCHED';
  bool get isRunningLatched => ignitionStatus == 'RUNNING_LATCHED';
}

class SafetyEventModel {
  final String id;
  final String deviceId;
  final String eventType;
  final String severity;
  final String description;
  final double? latitude;
  final double? longitude;
  final bool isResolved;
  final DateTime createdAt;

  SafetyEventModel({
    required this.id,
    required this.deviceId,
    required this.eventType,
    required this.severity,
    required this.description,
    this.latitude,
    this.longitude,
    required this.isResolved,
    required this.createdAt,
  });

  factory SafetyEventModel.fromJson(Map<String, dynamic> json) {
    return SafetyEventModel(
      id: json['id'] ?? '',
      deviceId: json['device_id'] ?? '',
      eventType: json['event_type'] ?? 'ALERT',
      severity: json['severity'] ?? 'MEDIUM',
      description: json['description'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      isResolved: json['is_resolved'] ?? false,
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class EmergencyContactModel {
  final String id;
  final String name;
  final String phoneNumber;
  final String relationship;
  final int priority;

  EmergencyContactModel({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.relationship,
    required this.priority,
  });

  factory EmergencyContactModel.fromJson(Map<String, dynamic> json) {
    return EmergencyContactModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      relationship: json['relationship'] ?? '',
      priority: json['priority'] ?? 1,
    );
  }
}
