import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// GATT UUIDs from PROTOCOL.md §5 — both helmet (SH-HLM-PROV) and ignition (SH-IGN-PROV).
class BleProvisionUuids {
  static final Guid service = Guid('0000FE20-0000-1000-8000-00805F9B34FB');
  static final Guid ssid = Guid('0000FE21-0000-1000-8000-00805F9B34FB');
  static final Guid pass = Guid('0000FE22-0000-1000-8000-00805F9B34FB');
  static final Guid psk = Guid('0000FE23-0000-1000-8000-00805F9B34FB');
  static final Guid pairId = Guid('0000FE24-0000-1000-8000-00805F9B34FB');
  static final Guid status = Guid('0000FE25-0000-1000-8000-00805F9B34FB');
}

enum ProvDeviceKind { helmet, ignition, unknown }

class ProvScanHit {
  ProvScanHit({
    required this.device,
    required this.name,
    required this.rssi,
    required this.kind,
  });

  final BluetoothDevice device;
  final String name;
  final int rssi;
  final ProvDeviceKind kind;

  String get id => device.remoteId.str;
}

class BleProvisionService {
  static const String helmetAdv = 'SH-HLM-PROV';
  static const String ignitionAdv = 'SH-IGN-PROV';
  static const String defaultWifiSsid = 'SmartHelmet_AP';
  static const String defaultWifiPass = 'helmet1234';
  static const String defaultHelmetId = 'HLM-2026-0001';
  static const String defaultIgnitionId = 'IGN-2026-0001';

  static String wifiSsid = defaultWifiSsid;
  static String wifiPass = defaultWifiPass;
  static String pairingPsk = '';
  static String helmetDeviceId = defaultHelmetId;
  static String ignitionDeviceId = defaultIgnitionId;
  static bool autoConnect = true;

  static StreamSubscription<List<ScanResult>>? _scanSub;
  static final Map<String, ProvScanHit> _hits = {};

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    wifiSsid = prefs.getString('prov_wifi_ssid') ?? defaultWifiSsid;
    wifiPass = prefs.getString('prov_wifi_pass') ?? defaultWifiPass;
    pairingPsk = prefs.getString('prov_psk') ?? '';
    helmetDeviceId = prefs.getString('prov_helmet_id') ?? defaultHelmetId;
    ignitionDeviceId = prefs.getString('prov_ignition_id') ?? defaultIgnitionId;
    autoConnect = prefs.getBool('prov_auto_connect') ?? true;
    if (pairingPsk.isEmpty) {
      pairingPsk = generatePsk();
    }
  }

  static Future<void> persistCredentials({
    String? ssid,
    String? pass,
    String? psk,
    String? helmetId,
    String? ignitionId,
    bool? auto,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (ssid != null) {
      wifiSsid = ssid;
      await prefs.setString('prov_wifi_ssid', ssid);
    }
    if (pass != null) {
      wifiPass = pass;
      await prefs.setString('prov_wifi_pass', pass);
    }
    if (psk != null) {
      pairingPsk = psk;
      await prefs.setString('prov_psk', psk);
    }
    if (helmetId != null) {
      helmetDeviceId = helmetId;
      await prefs.setString('prov_helmet_id', helmetId);
    }
    if (ignitionId != null) {
      ignitionDeviceId = ignitionId;
      await prefs.setString('prov_ignition_id', ignitionId);
    }
    if (auto != null) {
      autoConnect = auto;
      await prefs.setBool('prov_auto_connect', auto);
    }
  }

  /// 64 hex chars = 256-bit PSK matching firmware DEFAULT_PAIRING_PSK format.
  static String generatePsk() {
    final rng = Random.secure();
    final bytes = List<int>.generate(32, (_) => rng.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  static ProvDeviceKind _kindFromName(String name) {
    final n = name.toUpperCase();
    if (n.contains('HLM') || n.contains('HELMET')) return ProvDeviceKind.helmet;
    if (n.contains('IGN') || n.contains('IGNITION')) return ProvDeviceKind.ignition;
    return ProvDeviceKind.unknown;
  }

  static Future<bool> ensurePermissions() async {
    if (await FlutterBluePlus.isSupported == false) return false;

    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    final bleOk = (statuses[Permission.bluetoothScan]?.isGranted ?? false) ||
        (statuses[Permission.bluetoothConnect]?.isGranted ?? false);
    final locOk = statuses[Permission.locationWhenInUse]?.isGranted ?? false;
    // Older Android needs location for BLE scan; newer often only BLE perms.
    return bleOk || locOk;
  }

  static Future<void> startScan({
    required void Function(List<ProvScanHit> hits) onUpdate,
    Duration timeout = const Duration(seconds: 12),
  }) async {
    await stopScan();
    _hits.clear();
    onUpdate([]);

    final ok = await ensurePermissions();
    if (!ok) {
      throw Exception('Bluetooth / location permission denied');
    }

    if (FlutterBluePlus.adapterStateNow != BluetoothAdapterState.on) {
      await FlutterBluePlus.turnOn();
    }

    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      for (final r in results) {
        final name = r.advertisementData.advName.isNotEmpty
            ? r.advertisementData.advName
            : (r.device.platformName.isNotEmpty ? r.device.platformName : '');
        if (name.isEmpty) continue;
        final upper = name.toUpperCase();
        if (!upper.contains('SH-HLM-PROV') &&
            !upper.contains('SH-IGN-PROV') &&
            !upper.contains('HLM-PROV') &&
            !upper.contains('IGN-PROV')) {
          continue;
        }
        final hit = ProvScanHit(
          device: r.device,
          name: name,
          rssi: r.rssi,
          kind: _kindFromName(name),
        );
        _hits[hit.id] = hit;
      }
      onUpdate(_hits.values.toList()
        ..sort((a, b) => b.rssi.compareTo(a.rssi)));
    });

    await FlutterBluePlus.startScan(
      timeout: timeout,
      androidUsesFineLocation: true,
    );
  }

  static Future<void> stopScan() async {
    await _scanSub?.cancel();
    _scanSub = null;
    try {
      await FlutterBluePlus.stopScan();
    } catch (_) {}
  }

  static Future<void> _writeUtf8(BluetoothCharacteristic c, String value) async {
    final bytes = utf8.encode(value);
    await c.write(bytes, withoutResponse: false);
    await Future<void>.delayed(const Duration(milliseconds: 80));
  }

  /// Provision one ESP32: Wi-Fi + PSK + paired peer ID, then commit (status=1).
  static Future<void> provisionDevice({
    required BluetoothDevice device,
    required ProvDeviceKind kind,
    required String ssid,
    required String pass,
    required String psk,
    required String pairedPeerId,
    void Function(String step)? onStep,
  }) async {
    onStep?.call('Connecting to ${device.platformName.isNotEmpty ? device.platformName : device.remoteId.str}…');
    await device.connect(timeout: const Duration(seconds: 15), autoConnect: false);
    try {
      onStep?.call('Discovering GATT…');
      final services = await device.discoverServices();
      final svc = services.firstWhere(
        (s) => s.uuid == BleProvisionUuids.service,
        orElse: () => throw Exception('Provisioning service FE20 not found'),
      );

      BluetoothCharacteristic charOf(Guid g) {
        return svc.characteristics.firstWhere(
          (c) => c.uuid == g,
          orElse: () => throw Exception('Missing characteristic $g'),
        );
      }

      onStep?.call('Writing Wi-Fi SSID…');
      await _writeUtf8(charOf(BleProvisionUuids.ssid), ssid);
      onStep?.call('Writing Wi-Fi password…');
      await _writeUtf8(charOf(BleProvisionUuids.pass), pass);
      onStep?.call('Writing pairing PSK…');
      await _writeUtf8(charOf(BleProvisionUuids.psk), psk);
      onStep?.call('Writing paired device ID ($pairedPeerId)…');
      await _writeUtf8(charOf(BleProvisionUuids.pairId), pairedPeerId);

      onStep?.call('Committing (device will reboot)…');
      final statusChar = charOf(BleProvisionUuids.status);
      await statusChar.write(Uint8List.fromList([1]), withoutResponse: false);
      await Future<void>.delayed(const Duration(milliseconds: 600));
      onStep?.call(kind == ProvDeviceKind.helmet ? 'Helmet provisioned' : 'Ignition provisioned');
    } finally {
      try {
        await device.disconnect();
      } catch (_) {}
    }
  }

  /// Pair both boards with the same Wi-Fi + PSK; cross-write peer IDs.
  static Future<void> pairBoth({
    required ProvScanHit helmet,
    required ProvScanHit ignition,
    required String ssid,
    required String pass,
    String? psk,
    String helmetId = defaultHelmetId,
    String ignitionId = defaultIgnitionId,
    void Function(String step)? onStep,
    void Function(int progress)? onProgress,
  }) async {
    final secret = (psk == null || psk.isEmpty) ? generatePsk() : psk;
    await stopScan();

    onProgress?.call(10);
    await provisionDevice(
      device: helmet.device,
      kind: ProvDeviceKind.helmet,
      ssid: ssid,
      pass: pass,
      psk: secret,
      pairedPeerId: ignitionId,
      onStep: onStep,
    );
    onProgress?.call(55);

    await Future<void>.delayed(const Duration(milliseconds: 400));

    await provisionDevice(
      device: ignition.device,
      kind: ProvDeviceKind.ignition,
      ssid: ssid,
      pass: pass,
      psk: secret,
      pairedPeerId: helmetId,
      onStep: onStep,
    );
    onProgress?.call(90);

    await persistCredentials(
      ssid: ssid,
      pass: pass,
      psk: secret,
      helmetId: helmetId,
      ignitionId: ignitionId,
      auto: true,
    );
    onProgress?.call(100);
    onStep?.call('Both devices paired. They will auto-connect on reboot.');
  }
}
