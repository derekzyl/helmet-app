import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/telemetry_model.dart';

class ApiService {
  static String baseUrl = 'http://10.0.2.2:8000/api/v1'; // Default emulator host
  static String localIgnitionUrl = 'http://192.168.4.1:8080';

  static Future<TelemetryModel?> getLatestTelemetry({String deviceId = 'HLM-ESP32-001'}) async {
    try {
      final uri = Uri.parse('$baseUrl/telemetry/latest?device_id=$deviceId');
      final res = await http.get(uri).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        return TelemetryModel.fromJson(jsonDecode(res.body));
      }
    } catch (_) {
      // Local fallback: try querying local ignition controller directly
      try {
        final localUri = Uri.parse('$localIgnitionUrl/status');
        final res = await http.get(localUri).timeout(const Duration(seconds: 2));
        if (res.statusCode == 200) {
          return TelemetryModel.fromJson(jsonDecode(res.body));
        }
      } catch (_) {}
    }
    return null;
  }

  static Future<List<SafetyEventModel>> getEvents({int limit = 20}) async {
    try {
      final uri = Uri.parse('$baseUrl/events?limit=$limit');
      final res = await http.get(uri).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = data is List ? data : (data['items'] as List? ?? []);
        return list.map((e) => SafetyEventModel.fromJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<List<EmergencyContactModel>> getContacts() async {
    try {
      final uri = Uri.parse('$baseUrl/contacts');
      final res = await http.get(uri).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = data is List ? data : (data['items'] as List? ?? []);
        return list.map((e) => EmergencyContactModel.fromJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<bool> addEmergencyContact(String name, String phone, String rel) async {
    try {
      final uri = Uri.parse('$baseUrl/contacts');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'phone_number': phone,
          'relationship': rel,
          'priority': 1,
        }),
      ).timeout(const Duration(seconds: 4));
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

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
