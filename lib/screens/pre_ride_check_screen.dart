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
  TelemetryModel? _telemetry;
  bool _isLoading = true;
  bool _isUnlocked = false;

  @override
  void initState() {
    super.initState();
    _fetchTelemetry();
  }

  Future<void> _fetchTelemetry() async {
    setState(() => _isLoading = true);
    final t = await ApiService.getLatestTelemetry();
    if (mounted) {
      setState(() {
        _telemetry = t;
        _isLoading = false;
        if (t?.isUnlocked == true) {
          _isUnlocked = true;
        }
      });
    }
  }

  void _triggerUnlock() {
    setState(() {
      _isUnlocked = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'SUCCESS: All 5 Safety Gates Passed. Motorcycle SSR Engaged (UNLOCKED)!',
          style: TextStyle(fontFamily: 'JetBrains Mono', color: AppColors.onPrimary),
        ),
        backgroundColor: AppColors.primaryContainer,
      ),
    );
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = _telemetry;
    final step1Link = t != null && t.isLive;
    final step2Worn = t != null && t.helmetWorn;
    final step3Alcohol = t != null && !t.alcoholDetected && t.bacLevel <= 0.05;
    final step4Imu = t != null && (t.impactG ?? 1.0) < 3.0;
    final step5Battery = t != null && t.batteryPercentage >= 15;

    final allPassed = step1Link && step2Worn && step3Alcohol && step4Imu && step5Battery;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pre-Ride Safety Check'),
        actions: [
          IconButton(
            tooltip: 'Refresh Gates',
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: _fetchTelemetry,
          ),
        ],
      ),
      body: _isLoading
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
                    'Engine unlock requires all 5 conditions on ${ApiService.activeDeviceId}:',
                    style: const TextStyle(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildCheckItem(
                    title: '1. Authenticated Helmet Wireless Link',
                    subtitle: step1Link
                        ? 'Connected to live fleet link • Active signal'
                        : 'Awaiting telemetry packet from helmet',
                    passed: step1Link,
                    icon: Icons.wifi_tethering,
                  ),
                  const SizedBox(height: 12),

                  _buildCheckItem(
                    title: '2. Helmet Worn on Head',
                    subtitle: step2Worn
                        ? 'IR proximity sensor verified • Helmet latched'
                        : 'Helmet sensor reports removed from rider',
                    passed: step2Worn,
                    icon: Icons.face,
                  ),
                  const SizedBox(height: 12),

                  _buildCheckItem(
                    title: '3. Breathalyzer Alcohol Verification',
                    subtitle: step3Alcohol
                        ? 'MQ-3 evaluated at ${t.bacLevel.toStringAsFixed(3)}% BAC (PASS)'
                        : 'BAC threshold exceeded or awaiting test',
                    passed: step3Alcohol,
                    icon: Icons.air,
                  ),
                  const SizedBox(height: 12),

                  _buildCheckItem(
                    title: '4. Motion & Tilt Baseline',
                    subtitle: step4Imu
                        ? 'MPU-6050 calibrated upright • ${(t.tiltDegrees ?? 0.0).toStringAsFixed(1)}° tilt'
                        : 'Excessive tilt or impact detected',
                    passed: step4Imu,
                    icon: Icons.screen_rotation,
                  ),
                  const SizedBox(height: 12),

                  _buildCheckItem(
                    title: '5. Helmet Li-ion Battery Health',
                    subtitle: step5Battery
                        ? 'Battery at ${t.batteryPercentage}% (Healthy)'
                        : 'Battery too low (< 15%) or disconnected',
                    passed: step5Battery,
                    icon: Icons.battery_charging_full,
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: allPassed ? AppColors.primaryContainer : AppColors.surfaceContainer,
                        foregroundColor: allPassed ? AppColors.onPrimary : AppColors.outline,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                      onPressed: (allPassed && !_isUnlocked) ? _triggerUnlock : null,
                      child: Text(
                        _isUnlocked
                            ? 'MOTORCYCLE UNLOCKED (SSR ON)'
                            : allPassed
                                ? 'AUTHORIZE IGNITION & UNLOCK'
                                : 'SAFETY GATES INCOMPLETE',
                        style: const TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
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
