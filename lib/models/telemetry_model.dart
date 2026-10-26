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
  final bool isLive;

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
    this.isLive = true,
  });

  /// Factory for a clean standby state when awaiting first telemetry packet
  factory TelemetryModel.standby({String deviceId = 'HLM-2026-0001'}) {
    return TelemetryModel(
      deviceId: deviceId,
      helmetWorn: false,
      alcoholDetected: false,
      bacLevel: 0.0,
      latitude: 0.0,
      longitude: 0.0,
      speedKmh: 0.0,
      batteryPercentage: 0,
      batteryVoltage: 0.0,
      impactG: 1.0,
      tiltDegrees: 0.0,
      ignitionStatus: 'LOCKED',
      lockReason: 'AWAITING_TELEMETRY',
      timestamp: DateTime.now(),
      isLive: false,
    );
  }

  factory TelemetryModel.fromJson(Map<String, dynamic> json, {String defaultDeviceId = ''}) {
    final devId = json['device_id']?.toString() ??
        json['serial_number']?.toString() ??
        defaultDeviceId;

    final bac = (json['bac_level'] as num?)?.toDouble() ??
        (json['alcohol_level_mg_l'] as num?)?.toDouble() ??
        0.0;

    final batPct = (json['battery_pct'] as num?)?.toInt() ??
        (json['battery_percentage'] as num?)?.toInt() ??
        100;

    final batVolt = (json['battery_voltage'] as num?)?.toDouble() ??
        ((json['battery_mv'] as num?) != null
            ? (json['battery_mv'] as num).toDouble() / 1000.0
            : null);

    final ignState = json['ignition_state']?.toString() ??
        json['ignition_status']?.toString() ??
        'LOCKED';

    DateTime parsedTime;
    if (json['recorded_at'] != null) {
      parsedTime = DateTime.tryParse(json['recorded_at'].toString()) ?? DateTime.now();
    } else if (json['timestamp'] != null) {
      if (json['timestamp'] is int) {
        final val = json['timestamp'] as int;
        parsedTime = DateTime.fromMillisecondsSinceEpoch(
          val > 10000000000 ? val : val * 1000,
        );
      } else {
        parsedTime = DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now();
      }
    } else {
      parsedTime = DateTime.now();
    }

    return TelemetryModel(
      deviceId: devId,
      helmetWorn: json['helmet_worn'] == true,
      alcoholDetected: json['alcohol_detected'] == true || bac > 0.05,
      bacLevel: bac,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      speedKmh: (json['speed_kmh'] as num?)?.toDouble() ?? 0.0,
      batteryPercentage: batPct,
      batteryVoltage: batVolt,
      impactG: (json['impact_g'] as num?)?.toDouble(),
      tiltDegrees: (json['tilt_degrees'] as num?)?.toDouble(),
      ignitionStatus: ignState,
      lockReason: json['lock_reason']?.toString() ?? (ignState == 'LOCKED' ? 'SAFETY_INTERLOCK' : 'NONE'),
      timestamp: parsedTime,
      isLive: true,
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
      id: json['id']?.toString() ?? '',
      deviceId: json['device_id']?.toString() ?? '',
      eventType: json['event_type']?.toString() ?? 'ALERT',
      severity: json['severity']?.toString() ?? 'MEDIUM',
      description: json['description']?.toString() ?? json['message']?.toString() ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      isResolved: json['is_resolved'] == true || json['acknowledged'] == true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
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
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phoneNumber: json['phone_number']?.toString() ?? '',
      relationship: json['relationship']?.toString() ?? '',
      priority: (json['priority'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone_number': phoneNumber,
    'relationship': relationship,
    'priority': priority,
  };
}

class DeviceKitModel {
  final String kitCode;
  final String serialNumber;
  final String ignitionSerial;
  final String label;
  final int rssiDbm;
  final int batteryPct;
  final bool readyToPair;

  DeviceKitModel({
    required this.kitCode,
    required this.serialNumber,
    required this.ignitionSerial,
    required this.label,
    required this.rssiDbm,
    required this.batteryPct,
    required this.readyToPair,
  });

  factory DeviceKitModel.fromJson(Map<String, dynamic> json) {
    return DeviceKitModel(
      kitCode: json['kit_code']?.toString() ?? '',
      serialNumber: json['serial_number']?.toString() ?? json['device_id']?.toString() ?? '',
      ignitionSerial: json['ignition_serial']?.toString() ?? '',
      label: json['label']?.toString() ?? json['name']?.toString() ?? 'HelmGuard Kit',
      rssiDbm: (json['rssi_dbm'] as num?)?.toInt() ?? -50,
      batteryPct: (json['battery_pct'] as num?)?.toInt() ?? 95,
      readyToPair: json['ready_to_pair'] != false,
    );
  }
}

class RideTripModel {
  final String id;
  final String title;
  final DateTime startTime;
  final double distanceKm;
  final int durationMinutes;
  final double avgSpeedKmh;
  final double maxSpeedKmh;
  final int safetyScore;
  final double maxBac;

  RideTripModel({
    required this.id,
    required this.title,
    required this.startTime,
    required this.distanceKm,
    required this.durationMinutes,
    required this.avgSpeedKmh,
    required this.maxSpeedKmh,
    required this.safetyScore,
    required this.maxBac,
  });
}
