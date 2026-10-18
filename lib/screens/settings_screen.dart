import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _bacThreshold = 0.050;
  double _impactThreshold = 4.0;
  bool _isOverrideActive = false;

  void _triggerMaintenanceOverride() async {
    await ApiService.triggerMaintenanceOverride('MECHANIC-OVERRIDE-TOKEN');
    if (mounted) {
      setState(() => _isOverrideActive = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'MAINTENANCE OVERRIDE: Temporary 300s unlock granted for mechanic bench testing.',
            style: TextStyle(fontFamily: 'JetBrains Mono', color: AppColors.onPrimary),
          ),
          backgroundColor: AppColors.primaryContainer,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Rider Profile Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceLow,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: const Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.surfaceContainer,
                    child: Icon(Icons.person, color: AppColors.primary),
                  ),
                  SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tunde Adebayo',
                        style: TextStyle(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'COURIER DISPATCH #04 • HELM-001',
                        style: TextStyle(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 11,
                          fontFamily: 'JetBrains Mono',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'SAFETY INTERLOCK THRESHOLDS',
              style: TextStyle(
                color: AppColors.outline,
                fontSize: 11,
                fontFamily: 'JetBrains Mono',
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // BAC Limit Slider
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceLow,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Alcohol Threshold (BAC)',
                        style: TextStyle(color: AppColors.onSurface, fontSize: 13),
                      ),
                      Text(
                        '${_bacThreshold.toStringAsFixed(3)}%',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'JetBrains Mono',
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _bacThreshold,
                    min: 0.02,
                    max: 0.08,
                    divisions: 6,
                    activeColor: AppColors.primary,
                    inactiveColor: AppColors.surfaceContainer,
                    onChanged: (v) => setState(() => _bacThreshold = v),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Impact G Slider
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceLow,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Accident Peak Impact (G)',
                        style: TextStyle(color: AppColors.onSurface, fontSize: 13),
                      ),
                      Text(
                        '${_impactThreshold.toStringAsFixed(1)} G',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'JetBrains Mono',
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _impactThreshold,
                    min: 3.0,
                    max: 6.0,
                    divisions: 6,
                    activeColor: AppColors.primary,
                    inactiveColor: AppColors.surfaceContainer,
                    onChanged: (v) => setState(() => _impactThreshold = v),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'MAINTENANCE & OVERRIDES',
              style: TextStyle(
                color: AppColors.outline,
                fontSize: 11,
                fontFamily: 'JetBrains Mono',
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceLow,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Roadside Mechanic Override',
                    style: TextStyle(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Temporarily bypasses interlock for 300 seconds for bench diagnostics. All overrides are logged to security audit trail.',
                    style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 11),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.surfaceContainer,
                        foregroundColor: AppColors.error,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                      onPressed: _triggerMaintenanceOverride,
                      child: Text(
                        _isOverrideActive ? 'OVERRIDE CURRENTLY ACTIVE' : 'REQUEST TEMPORARY OVERRIDE',
                        style: const TextStyle(fontFamily: 'JetBrains Mono', fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
