import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/telemetry_model.dart';

class ApiService {
  static const String defaultBaseUrl = 'https://big-mariejeanne-cybergenii-b60e7032.koyeb.app/api/v1';
  static const String defaultWsUrl = 'wss://big-mariejeanne-cybergenii-b60e7032.koyeb.app/api/v1/telemetry/ws';
  /// Must match a registered cloud serial (see /devices/). Firmware may use HLM-2026-0001.
  static const String defaultDeviceId = 'HLM-2026';
  static const String defaultRiderName = 'Cybergenii Operator';
  static const String localIgnitionUrl = 'http://192.168.4.1:8080';

  static String baseUrl = defaultBaseUrl;
  static String wsUrl = defaultWsUrl;
  static String activeDeviceId = defaultDeviceId;
  static String riderName = defaultRiderName;

  static WebSocketChannel? _wsChannel;
  static final StreamController<TelemetryModel> _telemetryStreamController =
      StreamController<TelemetryModel>.broadcast();
  static bool _isWsConnected = false;
  static Timer? _wsReconnectTimer;
  static Timer? _pingTimer;

  static Stream<TelemetryModel> get telemetryStream => _telemetryStreamController.stream;
  static bool get isWsConnected => _isWsConnected;

  /// Initialize and load saved user preferences
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      baseUrl = prefs.getString('api_base_url') ?? defaultBaseUrl;
      activeDeviceId = prefs.getString('active_device_id') ?? defaultDeviceId;
      // Migrate legacy firmware serial that is not registered in cloud
      if (activeDeviceId == 'HLM-2026-0001' || activeDeviceId == 'HLM-DEFAULT') {
        activeDeviceId = defaultDeviceId;
        await prefs.setString('active_device_id', activeDeviceId);
      }
      riderName = prefs.getString('rider_name') ?? defaultRiderName;

      // Derive WS URL from HTTP Base URL if needed
      _deriveWsUrl();
    } catch (_) {}
  }

  static void _deriveWsUrl() {
    if (baseUrl.startsWith('https://')) {
      wsUrl = '${baseUrl.replaceFirst('https://', 'wss://')}/telemetry/ws';
    } else if (baseUrl.startsWith('http://')) {
      wsUrl = '${baseUrl.replaceFirst('http://', 'ws://')}/telemetry/ws';
    } else {
      wsUrl = defaultWsUrl;
    }
  }

  static Future<void> saveSettings({
    String? newBaseUrl,
    String? newDeviceId,
    String? newRiderName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (newBaseUrl != null && newBaseUrl.trim().isNotEmpty) {
      baseUrl = newBaseUrl.trim();
      await prefs.setString('api_base_url', baseUrl);
      _deriveWsUrl();
    }
    if (newDeviceId != null && newDeviceId.trim().isNotEmpty) {
      activeDeviceId = newDeviceId.trim();
      await prefs.setString('active_device_id', activeDeviceId);
    }
    if (newRiderName != null && newRiderName.trim().isNotEmpty) {
      riderName = newRiderName.trim();
      await prefs.setString('rider_name', riderName);
    }
    // Reconnect WS with new parameters
    reconnectWebSocket();
  }

  /// Start WebSocket real-time feed with subscription to active device
  static void connectWebSocket() {
    if (_isWsConnected) return;

    try {
      final uri = Uri.parse(wsUrl);
      _wsChannel = WebSocketChannel.connect(uri);
      _isWsConnected = true;

      // Send subscription handshake
      final subMsg = jsonEncode({
        'action': 'SUBSCRIBE',
        'device_ids': [activeDeviceId],
      });
      _wsChannel?.sink.add(subMsg);

      // Periodic ping
      _pingTimer?.cancel();
      _pingTimer = Timer.periodic(const Duration(seconds: 25), (_) {
        if (_isWsConnected) {
          _wsChannel?.sink.add(jsonEncode({'action': 'PING'}));
        }
      });

      _wsChannel?.stream.listen(
        (data) {
          try {
            final json = jsonDecode(data.toString());
            if (json is Map<String, dynamic>) {
              if (json['type'] == 'PONG') return;
              // Hub wraps frames as { type, device_id, data: {...sensors} }
              final Map<String, dynamic> frame;
              if (json['data'] is Map) {
                frame = Map<String, dynamic>.from(json['data'] as Map);
                frame['device_id'] ??= json['device_id'] ?? activeDeviceId;
              } else {
                frame = json;
              }
              final point = TelemetryModel.fromJson(frame, defaultDeviceId: activeDeviceId);
              _telemetryStreamController.add(point);
            }
          } catch (_) {}
        },
        onError: (err) {
          _handleWsDisconnect();
        },
        onDone: () {
          _handleWsDisconnect();
        },
      );
    } catch (_) {
      _handleWsDisconnect();
    }
  }

  static void _handleWsDisconnect() {
    _isWsConnected = false;
    _pingTimer?.cancel();
    _wsChannel?.sink.close();
    _wsChannel = null;

    // Retry connection after 5 seconds
    _wsReconnectTimer?.cancel();
    _wsReconnectTimer = Timer(const Duration(seconds: 5), () {
      connectWebSocket();
    });
  }

  static void reconnectWebSocket() {
    _wsReconnectTimer?.cancel();
    _pingTimer?.cancel();
    _wsChannel?.sink.close();
    _wsChannel = null;
    _isWsConnected = false;
    connectWebSocket();
  }

  static void disconnectWebSocket() {
    _wsReconnectTimer?.cancel();
    _pingTimer?.cancel();
    _wsChannel?.sink.close();
    _wsChannel = null;
    _isWsConnected = false;
  }

  /// Candidate serials when cloud ID and firmware ID differ (HLM-2026 vs HLM-2026-0001).
  static List<String> _deviceAliases(String primary) {
    final ids = <String>{primary, activeDeviceId, defaultDeviceId, 'HLM-2026', 'HLM-2026-0001', 'HLM-0001'};
    return ids.where((e) => e.trim().isNotEmpty).toList();
  }

  /// REST: Fetch latest telemetry
  static Future<TelemetryModel?> getLatestTelemetry({String? deviceId}) async {
    final primary = deviceId ?? activeDeviceId;
    for (final devId in _deviceAliases(primary)) {
      try {
        final uri = Uri.parse('$baseUrl/telemetry/latest/$devId');
        final res = await http.get(uri).timeout(const Duration(seconds: 4));
        if (res.statusCode == 200 && res.body.isNotEmpty && res.body != 'null') {
          final decoded = jsonDecode(res.body);
          if (decoded is Map<String, dynamic>) {
            return TelemetryModel.fromJson(decoded, defaultDeviceId: primary);
          }
        }
      } catch (_) {}
    }
    // Direct local ignition SoftAP fallback (phone must be on SH-IGN-*)
    try {
      final localUri = Uri.parse('$localIgnitionUrl/status');
      final res = await http.get(localUri).timeout(const Duration(seconds: 2));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is Map<String, dynamic>) {
          return TelemetryModel.fromJson(decoded, defaultDeviceId: primary);
        }
      }
    } catch (_) {}
    return null;
  }

  /// REST: Fetch telemetry history points
  static Future<List<TelemetryModel>> getTelemetryHistory({String? deviceId, int limit = 100}) async {
    final devId = deviceId ?? activeDeviceId;
    try {
      final uri = Uri.parse('$baseUrl/telemetry/history/$devId?limit=$limit');
      final res = await http.get(uri).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = data is List ? data : (data['items'] as List? ?? []);
        return list
            .map((e) => TelemetryModel.fromJson(e as Map<String, dynamic>, defaultDeviceId: devId))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  /// Convert telemetry history into calculated ride trips
  static Future<List<RideTripModel>> getRideTrips({String? deviceId}) async {
    final history = await getTelemetryHistory(deviceId: deviceId, limit: 150);
    if (history.isEmpty) return [];

    // Group points by date or contiguous running segments
    final List<RideTripModel> trips = [];
    List<TelemetryModel> currentSegment = [];

    for (final point in history) {
      if (currentSegment.isEmpty) {
        currentSegment.add(point);
      } else {
        final diff = point.timestamp.difference(currentSegment.last.timestamp).inMinutes.abs();
        if (diff > 45) {
          // New trip boundary
          final trip = _computeTripFromSegment(currentSegment);
          if (trip != null) trips.add(trip);
          currentSegment = [point];
        } else {
          currentSegment.add(point);
        }
      }
    }
    if (currentSegment.isNotEmpty) {
      final trip = _computeTripFromSegment(currentSegment);
      if (trip != null) trips.add(trip);
    }

    return trips;
  }

  static RideTripModel? _computeTripFromSegment(List<TelemetryModel> pts) {
    if (pts.isEmpty) return null;
    double maxSpeed = 0.0;
    double totalSpeed = 0.0;
    double maxBac = 0.0;

    for (final p in pts) {
      if (p.speedKmh > maxSpeed) maxSpeed = p.speedKmh;
      totalSpeed += p.speedKmh;
      if (p.bacLevel > maxBac) maxBac = p.bacLevel;
    }

    final avgSpeed = pts.isNotEmpty ? totalSpeed / pts.length : 0.0;
    final durationMins = pts.length > 1
        ? pts.last.timestamp.difference(pts.first.timestamp).inMinutes.abs() + 5
        : 12;
    final distanceKm = (avgSpeed * (durationMins / 60.0)).clamp(0.5, 99.0);
    final score = (100 - (maxBac * 500) - (maxSpeed > 80 ? 10 : 0)).round().clamp(60, 100);

    return RideTripModel(
      id: 'trip-${pts.first.timestamp.millisecondsSinceEpoch}',
      title: 'HelmGuard Session (${pts.first.deviceId})',
      startTime: pts.first.timestamp,
      distanceKm: double.parse(distanceKm.toStringAsFixed(1)),
      durationMinutes: durationMins,
      avgSpeedKmh: double.parse(avgSpeed.toStringAsFixed(1)),
      maxSpeedKmh: double.parse(maxSpeed.toStringAsFixed(1)),
      safetyScore: score,
      maxBac: double.parse(maxBac.toStringAsFixed(3)),
    );
  }

  /// REST: Fetch safety events
  static Future<List<SafetyEventModel>> getEvents({int limit = 50}) async {
    try {
      final uri = Uri.parse('$baseUrl/events/?limit=$limit');
      final res = await http.get(uri).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = data is List ? data : (data['items'] as List? ?? []);
        return list.map((e) => SafetyEventModel.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }

  /// REST: Acknowledge safety alarm
  static Future<bool> acknowledgeEvent(String eventId, {String acknowledgedBy = 'Fleet Operator'}) async {
    try {
      final uri = Uri.parse('$baseUrl/events/acknowledge/$eventId?acknowledged_by=${Uri.encodeComponent(acknowledgedBy)}');
      final res = await http.post(uri).timeout(const Duration(seconds: 4));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// REST & Local: Fetch emergency contacts
  static Future<List<EmergencyContactModel>> getContacts() async {
    try {
      final uri = Uri.parse('$baseUrl/contacts/');
      final res = await http.get(uri).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = data is List ? data : (data['items'] as List? ?? []);
        final contacts = list.map((e) => EmergencyContactModel.fromJson(e as Map<String, dynamic>)).toList();
        // Cache to local SharedPreferences
        _saveContactsCache(contacts);
        return contacts;
      }
    } catch (_) {}

    // Fallback to local storage (no dummy fake data)
    return await _loadContactsCache();
  }

  static Future<void> _saveContactsCache(List<EmergencyContactModel> contacts) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = jsonEncode(contacts.map((c) => c.toJson()).toList());
      await prefs.setString('cached_contacts', str);
    } catch (_) {}
  }

  static Future<List<EmergencyContactModel>> _loadContactsCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString('cached_contacts');
      if (str != null && str.isNotEmpty) {
        final list = jsonDecode(str) as List;
        return list.map((e) => EmergencyContactModel.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }

  /// REST & Local: Add emergency contact
  static Future<bool> addEmergencyContact(String name, String phone, String rel) async {
    try {
      final uri = Uri.parse('$baseUrl/contacts/');
      await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'phone_number': phone,
          'relationship': rel,
          'priority': 1,
        }),
      ).timeout(const Duration(seconds: 4));
    } catch (_) {}

    // Always keep local list in sync
    final local = await _loadContactsCache();
    local.add(EmergencyContactModel(
      id: 'c-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      phoneNumber: phone,
      relationship: rel,
      priority: local.length + 1,
    ));
    await _saveContactsCache(local);
    return true;
  }

  /// REST & Local: Delete emergency contact
  static Future<bool> deleteEmergencyContact(String id) async {
    try {
      final uri = Uri.parse('$baseUrl/contacts/$id');
      await http.delete(uri).timeout(const Duration(seconds: 3));
    } catch (_) {}

    final local = await _loadContactsCache();
    local.removeWhere((c) => c.id == id);
    await _saveContactsCache(local);
    return true;
  }

  /// REST: Discover nearby unprovisioned kits
  static Future<List<DeviceKitModel>> discoverDevices() async {
    try {
      final uri = Uri.parse('$baseUrl/devices/discover');
      final res = await http.get(uri).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List) {
          return data.map((e) => DeviceKitModel.fromJson(e as Map<String, dynamic>)).toList();
        }
      }
    } catch (_) {}
    return [];
  }

  /// REST: Easy 1-tap installation / pairing
  static Future<bool> easyInstallDevice({
    required String shortCode,
    String? label,
    String? vehicleType,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/devices/easy-install');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'short_code': shortCode,
          'label': label ?? 'HelmGuard Kit ($shortCode)',
          'vehicle_type': vehicleType ?? 'Motorcycle',
          'safety_preset': 'COMMERCIAL_STRICT',
        }),
      ).timeout(const Duration(seconds: 5));
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  /// REST: Update threshold configs on device
  static Future<bool> updateDeviceConfig({
    required String deviceId,
    double? bacLimit,
    double? impactG,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/devices/$deviceId/config');
      final body = <String, dynamic>{};
      if (bacLimit != null) body['bac_threshold'] = bacLimit;
      if (impactG != null) body['impact_g_threshold'] = impactG;

      final res = await http.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 4));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// REST: Mechanic maintenance override
  static Future<bool> triggerMaintenanceOverride(String token) async {
    try {
      final uri = Uri.parse('$baseUrl/devices/override');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': 'TEMPORARY_UNLOCK',
          'duration_sec': 300,
          'auth_token': token,
        }),
      ).timeout(const Duration(seconds: 4));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
