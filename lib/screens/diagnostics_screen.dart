import 'dart:async';
import 'package:flutter/material.dart';
import '../models/telemetry_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/connectivity_status_card.dart';

class DiagnosticsScreen extends StatefulWidget {
  const DiagnosticsScreen({super.key});

  @override
  State<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends State<DiagnosticsScreen> {
  TelemetryModel? _t;
  StreamSubscription? _sub;
  Timer? _poll;
  bool _running = false;
  bool _softApReachable = false;
  final List<String> _log = [];

  @override
  void initState() {
    super.initState();
    _refresh();
    _sub = ApiService.telemetryStream.listen((d) {
      if (mounted) setState(() => _t = d);
    });
    _poll = Timer.periodic(const Duration(seconds: 1), (_) => _refresh());
  }

  @override
  void dispose() {
    _sub?.cancel();
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    final t = await ApiService.getLatestTelemetry(deviceId: ApiService.activeDeviceId);
    if (!mounted) return;
    setState(() {
      _t = t ?? TelemetryModel.standby(deviceId: ApiService.activeDeviceId);
      _softApReachable = t?.isLive == true && (t?.wifiMode == 'SOFTAP' || t?.localLinkConnected == true);
    });
  }

  Future<void> _runFullDiagnosis() async {
    setState(() {
      _running = true;
      _log.clear();
    });
    void step(String s) {
      if (!mounted) return;
      setState(() => _log.add(s));
    }

    step('Pulling live telemetry…');
    await _refresh();
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final t = _t ?? TelemetryModel.standby();

    step(t.localLinkConnected ? 'PASS Local SoftAP / WS link' : 'FAIL No local helmet↔ignition link');
    step(t.mq3WarmedUp || (t.alcoholWarmupPct ?? 0) >= 100
        ? 'PASS MQ-3 warmed / ready'
        : 'WAIT MQ-3 warming ${(t.alcoholWarmupPct ?? 0).toStringAsFixed(0)}%');
    step(t.alcoholCalibrated ? 'PASS Alcohol baseline calibrated' : 'WARN Alcohol baseline not calibrated');
    step(t.alcoholDetected || t.bacLevel >= 0.05
        ? 'FAIL Alcohol over threshold (${t.bacLevel.toStringAsFixed(3)})'
        : 'PASS BAC ${t.bacLevel.toStringAsFixed(3)}');
    step(t.alcoholRisingAnomaly ? 'WARN BAC rising anomaly' : 'PASS BAC rise stable');
    step(t.helmetWorn ? 'PASS IR wear sensor (worn)' : 'FAIL Helmet not worn');
    step((t.tiltDegrees ?? 0) < 35
        ? 'PASS Tilt upright (${(t.tiltDegrees ?? 0).toStringAsFixed(1)}°)'
        : (t.tiltWarning ? 'WARN Excess lean' : 'FAIL Critical tilt'));
    step(t.imuAnomaly ? 'WARN IMU motion anomaly' : 'PASS IMU nominal (${t.imuState})');
    step((t.impactG ?? 1) < 3.5 ? 'PASS Impact peak ${(t.impactG ?? 1).toStringAsFixed(2)}G' : 'FAIL High impact');
    step(t.gpsFixed || (t.latitude.abs() + t.longitude.abs()) > 0.01
        ? 'PASS GPS / last fix'
        : 'WARN No GPS fix');
    step('INFO Battery ${t.batteryPercentage}% (not gated)');
    step(t.internetOk || ApiService.isWsConnected
        ? 'INFO Internet / cloud online'
        : 'INFO Offline — local interlock still active');
    step('Diagnosis complete.');

    if (mounted) setState(() => _running = false);
  }

  @override
  Widget build(BuildContext context) {
    final t = _t ?? TelemetryModel.standby(deviceId: ApiService.activeDeviceId);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sensor Diagnosis'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: t.isLive
                  ? AppColors.primaryContainer.withValues(alpha: 0.15)
                  : AppColors.error.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: t.isLive ? AppColors.primary.withValues(alpha: 0.4) : AppColors.error.withValues(alpha: 0.4),
              ),
            ),
            child: Text(
              t.isLive
                  ? 'LIVE sensors (${_softApReachable ? "SoftAP" : "fresh cloud"}). Wave IR 1s / shake MPU / MQ-3 — values below should move.'
                  : 'NOT LIVE — cloud cache or no SoftAP. Join Wi‑Fi SH-IGN-* (pass helmet1234), flash latest firmware, then reopen Diag. GPS needs sky or helmet serial: SIM',
              style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11, height: 1.35),
            ),
          ),
          const SizedBox(height: 12),
          ConnectivityStatusCard(telemetry: t, cloudWsLive: ApiService.isWsConnected),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _running ? null : _runFullDiagnosis,
            icon: _running
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.health_and_safety),
            label: Text(_running ? 'RUNNING…' : 'RUN FULL DIAGNOSIS'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryContainer,
              foregroundColor: AppColors.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 16),
          _section('MPU-6050', [
            _kv('State', t.imuState),
            _kv('Tilt', '${(t.tiltDegrees ?? 0).toStringAsFixed(1)}°'),
            _kv('Roll / Pitch', '${(t.rollDegrees ?? 0).toStringAsFixed(1)}° / ${(t.pitchDegrees ?? 0).toStringAsFixed(1)}°'),
            _kv('Accel (g)', '${(t.ax ?? 0).toStringAsFixed(2)}, ${(t.ay ?? 0).toStringAsFixed(2)}, ${(t.az ?? 1).toStringAsFixed(2)}'),
            _kv('Gyro (°/s)', '${(t.gx ?? 0).toStringAsFixed(0)}, ${(t.gy ?? 0).toStringAsFixed(0)}, ${(t.gz ?? 0).toStringAsFixed(0)}'),
            _kv('Peak impact', '${(t.impactG ?? 1).toStringAsFixed(2)} G'),
            _kv('Anomaly', t.imuAnomaly ? 'YES' : 'no'),
            _kv('Rider upright', t.riderUpright ? 'yes' : 'NO'),
          ]),
          _section('MQ-3 Alcohol', [
            _kv('BAC', t.bacLevel.toStringAsFixed(3)),
            _kv('Warmup', '${(t.alcoholWarmupPct ?? 0).toStringAsFixed(0)}%'),
            _kv('Calibrated', t.alcoholCalibrated ? 'yes' : 'no'),
            _kv('MQ3 raw', '${t.mq3Raw ?? '-'}'),
            _kv('Rise rate', (t.bacRiseRate ?? 0).toStringAsFixed(3)),
            _kv('Rising anomaly', t.alcoholRisingAnomaly ? 'YES' : 'no'),
            _kv('Over limit', t.alcoholDetected ? 'YES' : 'no'),
          ]),
          _section('Wear / Power / GPS', [
            _kv('Helmet worn', t.helmetWorn ? 'yes' : 'no'),
            _kv('Battery', '${t.batteryPercentage}%'),
            _kv('Ignition', t.ignitionStatus),
            _kv('Lock reason', t.lockReason ?? '-'),
            _kv('GPS', '${t.latitude.toStringAsFixed(5)}, ${t.longitude.toStringAsFixed(5)}'),
            _kv('Speed', '${t.speedKmh.toStringAsFixed(1)} km/h'),
          ]),
          if (_log.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text('AUDIT LOG', style: TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11, color: AppColors.outline)),
            const SizedBox(height: 8),
            ..._log.map((l) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(l, style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11)),
                )),
          ],
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> kids) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          ...kids,
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k, style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
          Text(v, style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 12)),
        ],
      ),
    );
  }
}
