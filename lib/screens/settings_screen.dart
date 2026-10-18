import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../main.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Rider Profile Header (Cleaned of dummy names)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(40),
                    child: Icon(Icons.shield, color: Theme.of(context).colorScheme.primary),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fleet Operator',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'OPERATOR: hello@cybergenii.com',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
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

            // Theme & Appearance Switcher
            Text(
              'APPEARANCE & THEME',
              style: TextStyle(
                color: Theme.of(context).colorScheme.outline,
                fontSize: 11,
                fontFamily: 'JetBrains Mono',
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isDark ? Icons.dark_mode : Icons.light_mode,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isDark ? 'Dark Theme' : 'Light Theme',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            isDark ? 'High-contrast nocturnal cockpit' : 'Daylight high-legibility theme',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Switch(
                    value: isDark,
                    activeThumbColor: Theme.of(context).colorScheme.primary,
                    onChanged: (val) {
                      themeModeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Text(
              'SAFETY INTERLOCK THRESHOLDS',
              style: TextStyle(
                color: Theme.of(context).colorScheme.outline,
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
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Alcohol Threshold (BAC)',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 13),
                      ),
                      Text(
                        '${_bacThreshold.toStringAsFixed(3)}%',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
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
                    activeColor: Theme.of(context).colorScheme.primary,
                    inactiveColor: Theme.of(context).colorScheme.surfaceContainerHighest,
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
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Accident Peak Impact (G)',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 13),
                      ),
                      Text(
                        '${_impactThreshold.toStringAsFixed(1)} G',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
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
                    activeColor: Theme.of(context).colorScheme.primary,
                    inactiveColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    onChanged: (v) => setState(() => _impactThreshold = v),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Text(
              'MAINTENANCE & OVERRIDES',
              style: TextStyle(
                color: Theme.of(context).colorScheme.outline,
                fontSize: 11,
                fontFamily: 'JetBrains Mono',
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Roadside Mechanic Override',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Temporarily bypasses interlock for 300 seconds for bench diagnostics. All overrides are logged to security audit trail.',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 11),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                        foregroundColor: Theme.of(context).colorScheme.error,
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
