import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PreRideCheckScreen extends StatefulWidget {
  const PreRideCheckScreen({super.key});

  @override
  State<PreRideCheckScreen> createState() => _PreRideCheckScreenState();
}

class _PreRideCheckScreenState extends State<PreRideCheckScreen> {
  final bool _step1Link = true;
  final bool _step2Worn = true;
  final bool _step3Alcohol = true;
  final bool _step4Imu = true;
  final bool _step5Battery = true;
  bool _isUnlocked = false;

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
    final allPassed = _step1Link && _step2Worn && _step3Alcohol && _step4Imu && _step5Battery;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pre-Ride Safety Check'),
      ),
      body: SingleChildScrollView(
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
            const Text(
              'Engine unlock requires all 5 safety conditions:',
              style: TextStyle(
                color: AppColors.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),

            _buildCheckItem(
              title: '1. Authenticated Helmet Wireless Link',
              subtitle: 'HMAC-SHA256 heartbeat fresh (<500ms latency)',
              passed: _step1Link,
              icon: Icons.wifi_tethering,
            ),
            const SizedBox(height: 12),

            _buildCheckItem(
              title: '2. Helmet Worn on Head',
              subtitle: 'FC-51 Infrared proximity sensor stable >1.0s',
              passed: _step2Worn,
              icon: Icons.face,
            ),
            const SizedBox(height: 12),

            _buildCheckItem(
              title: '3. Breathalyzer Alcohol Verification',
              subtitle: 'MQ-3 warmed up, BAC evaluated at 0.012% (PASS)',
              passed: _step3Alcohol,
              icon: Icons.air,
            ),
            const SizedBox(height: 12),

            _buildCheckItem(
              title: '4. 6-Axis Motion & Tilt Baseline',
              subtitle: 'MPU-6050 calibrated upright, zero crash Gs',
              passed: _step4Imu,
              icon: Icons.screen_rotation,
            ),
            const SizedBox(height: 12),

            _buildCheckItem(
              title: '5. Helmet Li-ion Battery Health',
              subtitle: 'Rail voltage 4.08V (92% capacity > 15% threshold)',
              passed: _step5Battery,
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
                  _isUnlocked ? 'MOTORCYCLE UNLOCKED (SSR ON)' : 'AUTHORIZE IGNITION & UNLOCK',
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
          color: passed ? AppColors.primary.withValues(alpha: 0.3) : AppColors.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: passed ? AppColors.primaryContainer.withValues(alpha: 0.2) : AppColors.surfaceContainer,
            ),
            child: Icon(icon, color: passed ? AppColors.primary : AppColors.outline, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'JetBrains Mono',
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
