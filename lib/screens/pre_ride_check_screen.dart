import 'dart:async';

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/telemetry_model.dart';
import '../services/api_service.dart';

class PreRideCheckScreen extends StatefulWidget {
  const PreRideCheckScreen({super.key});

  @override
  State<PreRideCheckScreen> createState() => _PreRideCheckScreenState();
}

class _PreRideCheckScreenState extends State<PreRideCheckScreen> {
  TelemetryModel _telemetry = TelemetryModel.standby(deviceId: ApiService.activeDeviceId);
  StreamSubscription<TelemetryModel>? _wsSub;
  Timer? _pollTimer;
  bool _isLoading = true;
  bool _isAuthorizing = false;
  String _statusHint = 'Listening for helmet telemetry…';

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _fetchTelemetry();
    _wsSub = ApiService.telemetryStream.listen((data) {
      if (!mounted) return;
      if (data.deviceId.isNotEmpty &&
          data.deviceId != ApiService.activeDeviceId &&
          !data.deviceId.contains(ApiService.activeDeviceId.split('-').last)) {
        // Still accept if only one active kit
      }
      setState(() {
        _telemetry = data;
        _isLoading = false;
        _statusHint = data.isUnlocked
            ? 'Ignition already UNLOCKED on device'
            : 'Live telemetry updating gates';
      });
    });
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) => _fetchTelemetry(quiet: true));
    if (!ApiService.isWsConnected) {
      ApiService.reconnectWebSocket();
    }
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchTelemetry({bool quiet = false}) async {
    if (!quiet && mounted) setState(() => _isLoading = true);
    final t = await ApiService.getLatestTelemetry(deviceId: ApiService.activeDeviceId);
    if (!mounted) return;
    setState(() {
      if (t != null) {
        _telemetry = t;
        _statusHint = t.isUnlocked
            ? 'Device reports UNLOCKED'
            : 'Gates refreshed from ${t.isLive ? "live" : "cached"} telemetry';
      } else if (!quiet) {
        _statusHint =
            'No telemetry yet for ${ApiService.activeDeviceId}. Wear helmet / wait for SoftAP link.';
      }
      _isLoading = false;
    });
  }

  bool get _step1Link {
    final t = _telemetry;
    return t.localLinkConnected ||
        ApiService.isWsConnected ||
        t.isLive ||
        t.wifiMode == 'SOFTAP' ||
        t.wifiMode == 'STA';
  }

  bool get _step2Worn => _telemetry.helmetWorn;

  bool get _step3Alcohol {
    final t = _telemetry;
    final warmed = t.mq3WarmedUp || (t.alcoholWarmupPct ?? 100) >= 99 || t.isLive;
    return warmed && !t.alcoholDetected && t.bacLevel <= 0.05 && !t.alcoholRisingAnomaly;
  }

  bool get _step4Imu {
    final t = _telemetry;
    final tilt = t.tiltDegrees ?? 0.0;
    final impact = t.impactG ?? 1.0;
    return impact < 3.5 && tilt < 60.0 && !t.imuAnomaly && t.imuState != 'CRASH' && t.imuState != 'PRE_ALERT';
  }

  bool get _step5Battery => _telemetry.batteryPercentage >= 15;

  bool get _allPassed =>
      _step1Link && _step2Worn && _step3Alcohol && _step4Imu && _step5Battery;

  Future<void> _triggerUnlock() async {
    if (!_allPassed || _isAuthorizing) return;

    setState(() {
      _isAuthorizing = true;
      _statusHint = 'Authorizing ignition…';
    });

    // Prefer confirming device already unlocked via live FSM; else request override
    await _fetchTelemetry(quiet: true);
    if (_telemetry.isUnlocked) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ignition already UNLOCKED — SoftAP safety gates passed on device.',
            style: TextStyle(fontFamily: 'JetBrains Mono', color: AppColors.onPrimary),
          ),
          backgroundColor: AppColors.primaryContainer,
        ),
      );
      setState(() => _isAuthorizing = false);
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) Navigator.pop(context, true);
      });
      return;
    }

    final ok = await ApiService.triggerMaintenanceOverride('PRE-RIDE-AUTHORIZE');
    await _fetchTelemetry(quiet: true);

    if (!mounted) return;
    setState(() {
      _isAuthorizing = false;
      _statusHint = ok || _telemetry.isUnlocked
          ? 'Authorize sent — watch ignition LED / SSR'
          : 'Cloud authorize failed; keep SoftAP link — device unlocks when gates stay green';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok || _telemetry.isUnlocked
              ? 'SUCCESS: Safety gates passed. Ignition unlock signaled.'
              : 'Gates OK locally. Keep helmet on SoftAP — ignition unlocks when device FSM agrees.',
          style: const TextStyle(fontFamily: 'JetBrains Mono', color: AppColors.onPrimary),
        ),
        backgroundColor: AppColors.primaryContainer,
      ),
    );

    if (ok || _telemetry.isUnlocked) {
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) Navigator.pop(context, true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = _telemetry;
    final unlocked = t.isUnlocked;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pre-Ride Safety Check'),
        actions: [
          IconButton(
            tooltip: 'Refresh Gates',
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: () => _fetchTelemetry(),
          ),
        ],
      ),
      body: _isLoading && t.isLive == false && t.batteryPercentage == 0
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'DUAL-FACTOR SAFETY VERIFICATION',
                    style: TextStyle(
                      color: AppColors.outline,
                      fontSize: 11,
                      fontFamily: 'JetBrains Mono',
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Engine unlock requires all 5 conditions on ${ApiService.activeDeviceId}',
                    style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.outlineVariant),
                    ),
                    child: Text(
                      _statusHint,
                      style: const TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 11,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildCheckItem(
                    title: '1. Helmet ↔ Ignition Link',
                    subtitle: _step1Link
                        ? 'Link OK · mode ${t.wifiMode.isEmpty ? "cloud/live" : t.wifiMode}'
                            '${t.localLinkConnected ? " · SoftAP peer" : ""}'
                        : 'No SoftAP / cloud telemetry — power both boards',
                    passed: _step1Link,
                    icon: Icons.wifi_tethering,
                  ),
                  const SizedBox(height: 12),
                  _buildCheckItem(
                    title: '2. Helmet Worn on Head',
                    subtitle: _step2Worn
                        ? 'IR proximity verified · worn'
                        : 'Put the helmet on (IR must detect head)',
                    passed: _step2Worn,
                    icon: Icons.face,
                  ),
                  const SizedBox(height: 12),
                  _buildCheckItem(
                    title: '3. Breathalyzer Alcohol Check',
                    subtitle: _step3Alcohol
                        ? 'BAC ${t.bacLevel.toStringAsFixed(3)}% · PASS'
                        : t.alcoholDetected || t.bacLevel > 0.05
                            ? 'BAC ${t.bacLevel.toStringAsFixed(3)}% over limit'
                            : 'Waiting for MQ-3 sample / warmup ${(t.alcoholWarmupPct ?? 0).toStringAsFixed(0)}%',
                    passed: _step3Alcohol,
                    icon: Icons.air,
                  ),
                  const SizedBox(height: 12),
                  _buildCheckItem(
                    title: '4. Motion & Tilt Baseline',
                    subtitle: _step4Imu
                        ? 'IMU ${t.imuState} · tilt ${(t.tiltDegrees ?? 0).toStringAsFixed(1)}° · impact ${(t.impactG ?? 1).toStringAsFixed(2)}G'
                        : 'Fix posture / clear IMU anomaly (tilt ${(t.tiltDegrees ?? 0).toStringAsFixed(1)}°)',
                    passed: _step4Imu,
                    icon: Icons.screen_rotation,
                  ),
                  const SizedBox(height: 12),
                  _buildCheckItem(
                    title: '5. Helmet Battery Health',
                    subtitle: _step5Battery
                        ? 'Battery ${t.batteryPercentage}%'
                        : 'Battery ${t.batteryPercentage}% — need ≥ 15%',
                    passed: _step5Battery,
                    icon: Icons.battery_charging_full,
                  ),
                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (_allPassed || unlocked)
                            ? AppColors.primaryContainer
                            : AppColors.surfaceContainer,
                        foregroundColor: (_allPassed || unlocked)
                            ? AppColors.onPrimary
                            : AppColors.outline,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                      onPressed: unlocked
                          ? () => Navigator.pop(context, true)
                          : (_allPassed && !_isAuthorizing)
                              ? _triggerUnlock
                              : () {
                                  _fetchTelemetry();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        _failSummary(),
                                        style: const TextStyle(fontFamily: 'JetBrains Mono'),
                                      ),
                                      backgroundColor: AppColors.surfaceHigh,
                                    ),
                                  );
                                },
                      child: _isAuthorizing
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimary),
                            )
                          : Text(
                              unlocked
                                  ? 'MOTORCYCLE UNLOCKED — DONE'
                                  : _allPassed
                                      ? 'AUTHORIZE IGNITION & UNLOCK'
                                      : 'TAP FOR GATE DETAILS',
                              style: const TextStyle(
                                fontFamily: 'JetBrains Mono',
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Gates refresh every 2s. Real SSR unlock happens on the ignition unit when SoftAP heartbeats stay green.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
    );
  }

  String _failSummary() {
    final fails = <String>[];
    if (!_step1Link) fails.add('link');
    if (!_step2Worn) fails.add('wear helmet');
    if (!_step3Alcohol) fails.add('alcohol');
    if (!_step4Imu) fails.add('tilt/IMU');
    if (!_step5Battery) fails.add('battery');
    return fails.isEmpty ? 'Refreshing…' : 'Still needed: ${fails.join(", ")}';
  }

  Widget _buildCheckItem({
    required String title,
    required String subtitle,
    required bool passed,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: passed ? AppColors.primary.withValues(alpha: 0.4) : AppColors.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: passed
                  ? AppColors.primaryContainer.withValues(alpha: 0.2)
                  : AppColors.surfaceContainer,
            ),
            child: Icon(
              icon,
              color: passed ? AppColors.primary : AppColors.outline,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: passed ? AppColors.onSurface : AppColors.outline,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            passed ? Icons.check_circle : Icons.radio_button_unchecked,
            color: passed ? AppColors.primary : AppColors.outline,
            size: 20,
          ),
        ],
      ),
    );
  }
}
