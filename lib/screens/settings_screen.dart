import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/theme_controller.dart';
import '../services/api_service.dart';
import 'contacts_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _bacThreshold = 0.050;
  double _impactThreshold = 4.0;
  bool _isOverrideActive = false;
  bool _isTestingConnection = false;
  String? _connectionStatus;

  void _triggerMaintenanceOverride() async {
    final success = await ApiService.triggerMaintenanceOverride('MECHANIC-OVERRIDE-TOKEN');
    if (mounted) {
      setState(() => _isOverrideActive = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'MAINTENANCE OVERRIDE: Temporary 300s unlock granted for mechanic bench testing.'
                : 'OVERRIDE DISPATCHED: Benchmark mode active locally for 300 seconds.',
            style: const TextStyle(fontFamily: 'JetBrains Mono', color: AppColors.onPrimary),
          ),
          backgroundColor: AppColors.primaryContainer,
        ),
      );
    }
  }

  void _testConnection() async {
    setState(() {
      _isTestingConnection = true;
      _connectionStatus = null;
    });

    final telemetry = await ApiService.getLatestTelemetry();
    if (mounted) {
      setState(() {
        _isTestingConnection = false;
        if (telemetry != null) {
          _connectionStatus = 'SUCCESS: Online & Receiving frames from ${telemetry.deviceId}';
        } else {
          _connectionStatus = 'CONNECTED: Server reachable, device in standby.';
        }
      });
    }
  }

  void _editProfile() {
    final nameCtrl = TextEditingController(text: ApiService.riderName);
    final devCtrl = TextEditingController(text: ApiService.activeDeviceId);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('Edit Rider & Device ID'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Rider / Operator Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: devCtrl,
              decoration: const InputDecoration(labelText: 'Active Helmet Device ID (e.g. HLM-2026-0001)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryContainer),
            onPressed: () async {
              await ApiService.saveSettings(
                newRiderName: nameCtrl.text.trim(),
                newDeviceId: devCtrl.text.trim(),
              );
              if (ctx.mounted) Navigator.pop(ctx);
              setState(() {});
            },
            child: const Text('Save', style: TextStyle(color: AppColors.onPrimary)),
          ),
        ],
      ),
    );
  }

  void _editServerUrl() {
    final urlCtrl = TextEditingController(text: ApiService.baseUrl);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('Server Connection URL'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Specify cloud backend or local development endpoint:',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlCtrl,
              decoration: const InputDecoration(
                labelText: 'API Base URL',
                hintText: 'https://.../api/v1',
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  label: const Text('Cloud (Koyeb)', style: TextStyle(fontSize: 10)),
                  onPressed: () => urlCtrl.text = ApiService.defaultBaseUrl,
                ),
                ActionChip(
                  label: const Text('Local (Emulator)', style: TextStyle(fontSize: 10)),
                  onPressed: () => urlCtrl.text = 'http://10.0.2.2:8000/api/v1',
                ),
                ActionChip(
                  label: const Text('Local (Host)', style: TextStyle(fontSize: 10)),
                  onPressed: () => urlCtrl.text = 'http://localhost:8000/api/v1',
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryContainer),
            onPressed: () async {
              await ApiService.saveSettings(newBaseUrl: urlCtrl.text.trim());
              if (ctx.mounted) Navigator.pop(ctx);
              setState(() {});
              _testConnection();
            },
            child: const Text('Update & Reconnect', style: TextStyle(color: AppColors.onPrimary)),
          ),
        ],
      ),
    );
  }

  void _syncThresholds() async {
    final success = await ApiService.updateDeviceConfig(
      deviceId: ApiService.activeDeviceId,
      bacLimit: _bacThreshold,
      impactG: _impactThreshold,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Thresholds synchronized with ${ApiService.activeDeviceId} firmware.'
                : 'Thresholds saved to local profile.',
            style: const TextStyle(fontFamily: 'JetBrains Mono', color: AppColors.onPrimary),
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
            // Rider Profile Header
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ApiService.riderName,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'DEVICE ID: ${ApiService.activeDeviceId}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 11,
                            fontFamily: 'JetBrains Mono',
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    color: AppColors.primary,
                    tooltip: 'Edit Profile & Device',
                    onPressed: _editProfile,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Server Connection Card
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
                      const Text(
                        'BACKEND CONNECTION',
                        style: TextStyle(
                          color: AppColors.outline,
                          fontSize: 10,
                          fontFamily: 'JetBrains Mono',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                        onPressed: _editServerUrl,
                        icon: const Icon(Icons.tune, size: 14, color: AppColors.primary),
                        label: const Text(
                          'Configure',
                          style: TextStyle(fontSize: 11, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    ApiService.baseUrl,
                    style: const TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 11,
                      color: AppColors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'WebSocket: ${ApiService.wsUrl}',
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_connectionStatus != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _connectionStatus!,
                      style: const TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 10,
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                      ),
                      onPressed: _isTestingConnection ? null : _testConnection,
                      icon: _isTestingConnection
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.wifi_tethering, size: 16),
                      label: const Text(
                        'TEST BACKEND & WEBSOCKET LINK',
                        style: TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Emergency Contacts Quick Link
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
              ),
              child: Material(
                color: Colors.transparent,
                child: ListTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ContactsScreen()),
                    );
                  },
                  leading: const Icon(Icons.contact_phone, color: AppColors.primary),
                  title: const Text('Emergency SOS Contacts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: const Text('Manage numbers notified on collision impact', style: TextStyle(fontSize: 11)),
                  trailing: const Icon(Icons.chevron_right),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Theme & Appearance Switcher
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
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: _syncThresholds,
                      icon: const Icon(Icons.sync, size: 16, color: AppColors.primary),
                      label: const Text(
                        'SYNC THRESHOLDS TO HELMET',
                        style: TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ),
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

            const SizedBox(height: 24),

            // About HelmGuard Card with Logo & App ID
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/images/app_icon.png',
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.shield,
                        color: AppColors.primary,
                        size: 40,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'HelmGuard',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'App ID: com.cybergenii.helmet',
                          style: TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontSize: 10,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          'Version 1.0.0+1 • © 2026 Cybergenii',
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
