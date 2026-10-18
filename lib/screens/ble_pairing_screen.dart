import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BlePairingScreen extends StatefulWidget {
  const BlePairingScreen({super.key});

  @override
  State<BlePairingScreen> createState() => _BlePairingScreenState();
}

class _BlePairingScreenState extends State<BlePairingScreen> {
  // Method selection: 'radar' (Fast Pair) | 'qr' | 'pin'
  String _activeMode = 'radar';

  // 4-Digit PIN
  final _pinController = TextEditingController(text: '8492');

  // Friendly vehicle name
  final _nameController = TextEditingController(text: 'Cruiser Alpha');

  bool _isPairing = false;
  bool _isProvisioned = false;
  int _auditProgress = 0;
  bool _showAdvanced = false;

  final _ssidController = TextEditingController(text: 'SmartHelmet_AP');
  final _passController = TextEditingController(text: 'helmet1234');

  void _executeFastPair() async {
    setState(() {
      _isPairing = true;
      _auditProgress = 20;
    });

    // Step 1: BLE Handshake
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _auditProgress = 50);

    // Step 2: Auto-negotiate 256-bit PSK in background
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _auditProgress = 80);

    // Step 3: Arm Solid-State Relay Interlock
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {
      _auditProgress = 100;
      _isPairing = false;
      _isProvisioned = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'SUCCESS: Helmet & Ignition Relay Paired! Interlock Armed.',
          style: TextStyle(fontFamily: 'JetBrains Mono', color: AppColors.onPrimary),
        ),
        backgroundColor: AppColors.primaryContainer,
      ),
    );
  }

  void _simulateQrScan() {
    setState(() {
      _activeMode = 'radar';
      _pinController.text = '8492';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'QR Sticker Verified: Vanguard Kit #8492',
          style: TextStyle(fontFamily: 'JetBrains Mono', color: AppColors.onPrimary),
        ),
        backgroundColor: AppColors.primaryContainer,
      ),
    );
  }

  @override
  void dispose() {
    _pinController.dispose();
    _nameController.dispose();
    _ssidController.dispose();
    _passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth LE Pairing'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Tag
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: const Text(
                    'ZERO-SERIAL INSTALLATION',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 10,
                      fontFamily: 'JetBrains Mono',
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Install Smart Helmet System',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Zero-friction Bluetooth LE pairing. The helmet and ignition relay are provisioned as 1 protected device.',
              style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13),
            ),
            const SizedBox(height: 20),

            // Mode Selector
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: _activeMode == 'radar' ? AppColors.surfaceContainer : null,
                      side: BorderSide(
                        color: _activeMode == 'radar' ? AppColors.primary : AppColors.outlineVariant,
                      ),
                    ),
                    onPressed: () => setState(() => _activeMode = 'radar'),
                    icon: const Icon(Icons.radar, size: 16),
                    label: const Text('Nearby Radar', style: TextStyle(fontSize: 11)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: _activeMode == 'qr' ? AppColors.surfaceContainer : null,
                      side: BorderSide(
                        color: _activeMode == 'qr' ? AppColors.primary : AppColors.outlineVariant,
                      ),
                    ),
                    onPressed: () => setState(() => _activeMode = 'qr'),
                    icon: const Icon(Icons.qr_code_scanner, size: 16),
                    label: const Text('Scan QR', style: TextStyle(fontSize: 11)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: _activeMode == 'pin' ? AppColors.surfaceContainer : null,
                      side: BorderSide(
                        color: _activeMode == 'pin' ? AppColors.primary : AppColors.outlineVariant,
                      ),
                    ),
                    onPressed: () => setState(() => _activeMode = 'pin'),
                    icon: const Icon(Icons.pin, size: 16),
                    label: const Text('4-Digit PIN', style: TextStyle(fontSize: 11)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Discovered Nearby System Card (Mode: Radar)
            if (_activeMode == 'radar') ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isProvisioned ? AppColors.primary : AppColors.outlineVariant,
                    width: _isProvisioned ? 2 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.two_wheeler, color: AppColors.primary, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Vanguard Pro Helmet Kit',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Kit Code: #${_pinController.text} • Signal: -42 dBm',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontFamily: 'JetBrains Mono',
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _isProvisioned
                                ? AppColors.primary.withValues(alpha: 0.2)
                                : AppColors.surfaceContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _isProvisioned ? 'ARMED' : 'READY',
                            style: TextStyle(
                              color: _isProvisioned ? AppColors.primary : AppColors.onSurfaceVariant,
                              fontSize: 11,
                              fontFamily: 'JetBrains Mono',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: AppColors.outlineVariant, height: 24),

                    // Component Pairing Status
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.shield_outlined, size: 16, color: AppColors.primary),
                            SizedBox(width: 6),
                            Text('Smart Helmet (ESP32)', style: TextStyle(fontSize: 12, fontFamily: 'JetBrains Mono')),
                          ],
                        ),
                        Text('100 Hz Sensors OK', style: TextStyle(fontSize: 11, color: AppColors.primary, fontFamily: 'JetBrains Mono')),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.power_settings_new, size: 16, color: AppColors.secondary),
                            SizedBox(width: 6),
                            Text('Ignition SSR Relay', style: TextStyle(fontSize: 12, fontFamily: 'JetBrains Mono')),
                          ],
                        ),
                        Text('Interlock Latched', style: TextStyle(fontSize: 11, color: AppColors.secondary, fontFamily: 'JetBrains Mono')),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            // QR Code Scanner Tab
            if (_activeMode == 'qr') ...[
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.outlineVariant),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.qr_code_scanner, size: 64, color: AppColors.primary),
                    const SizedBox(height: 12),
                    const Text(
                      'Scan Visor QR Sticker',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Point camera at the QR sticker inside helmet or on the manual',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.surfaceContainer,
                        foregroundColor: AppColors.primary,
                      ),
                      onPressed: _simulateQrScan,
                      icon: const Icon(Icons.camera_alt, size: 18),
                      label: const Text('Simulate Scan (Kit #8492)'),
                    ),
                  ],
                ),
              ),
            ],

            // 4-Digit PIN Tab
            if (_activeMode == 'pin') ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.outlineVariant),
                ),
                child: Column(
                  children: [
                    const Text(
                      'ENTER 4-DIGIT SETUP PIN',
                      style: TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 11,
                        color: AppColors.outline,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _pinController,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'JetBrains Mono',
                        letterSpacing: 8,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.surfaceContainer,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.outlineVariant),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Found on your warranty card or helmet box label',
                      style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Friendly Ride Name
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'BIKE / RIDE NICKNAME',
                labelStyle: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11),
                filled: true,
                fillColor: AppColors.surfaceContainer,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.outlineVariant),
                ),
              ),
              style: const TextStyle(fontSize: 14),
            ),

            const SizedBox(height: 24),

            // 1-Tap Installation Action
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryContainer,
                  foregroundColor: AppColors.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _isPairing ? null : _executeFastPair,
                icon: _isPairing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimary),
                      )
                    : const Icon(Icons.flash_on, size: 20),
                label: Text(
                  _isPairing
                      ? 'ARMING INTERLOCK ($_auditProgress%)...'
                      : _isProvisioned
                          ? 'RE-ARM SYSTEM'
                          : '1-TAP PAIR & ARM SYSTEM',
                  style: const TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),

            // Diagnostics Checklist (shown after/during pairing)
            if (_isPairing || _isProvisioned) ...[
              const SizedBox(height: 20),
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
                      'SYSTEM DIAGNOSTIC AUDIT',
                      style: TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 11,
                        color: AppColors.outline,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildAuditItem(
                      icon: Icons.face,
                      title: 'Optical Head Wear Sensor',
                      status: _auditProgress >= 30 ? 'CALIBRATED' : 'WAITING',
                      isComplete: _auditProgress >= 30,
                    ),
                    const SizedBox(height: 8),
                    _buildAuditItem(
                      icon: Icons.air,
                      title: 'MQ-3 Alcohol Breathalyzer',
                      status: _auditProgress >= 60 ? 'ZEROED (0.00 mg/L)' : 'WAITING',
                      isComplete: _auditProgress >= 60,
                    ),
                    const SizedBox(height: 8),
                    _buildAuditItem(
                      icon: Icons.explore,
                      title: 'MPU-6050 Motion / Gyro',
                      status: _auditProgress >= 80 ? 'BALANCED' : 'WAITING',
                      isComplete: _auditProgress >= 80,
                    ),
                    const SizedBox(height: 8),
                    _buildAuditItem(
                      icon: Icons.power,
                      title: 'Ignition SSR Relay Interlock',
                      status: _auditProgress >= 100 ? 'ARMED & LATCHED' : 'WAITING',
                      isComplete: _auditProgress >= 100,
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Collapsible Advanced Section
            InkWell(
              onTap: () => setState(() => _showAdvanced = !_showAdvanced),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _showAdvanced ? 'Hide Advanced Options' : 'Advanced: Custom Wi-Fi Credentials',
                    style: const TextStyle(fontSize: 11, color: AppColors.outline, fontFamily: 'JetBrains Mono'),
                  ),
                  Icon(
                    _showAdvanced ? Icons.expand_less : Icons.expand_more,
                    size: 16,
                    color: AppColors.outline,
                  ),
                ],
              ),
            ),

            if (_showAdvanced) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _ssidController,
                decoration: const InputDecoration(labelText: 'Custom Wi-Fi SSID', filled: true),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Custom Wi-Fi Password', filled: true),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAuditItem({
    required IconData icon,
    required String title,
    required String status,
    required bool isComplete,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: isComplete ? AppColors.primary : AppColors.outline),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 12, fontFamily: 'JetBrains Mono')),
          ],
        ),
        Text(
          status,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            fontFamily: 'JetBrains Mono',
            color: isComplete ? AppColors.primary : AppColors.outline,
          ),
        ),
      ],
    );
  }
}
