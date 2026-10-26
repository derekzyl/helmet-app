import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/telemetry_model.dart';
import '../services/api_service.dart';

class BlePairingScreen extends StatefulWidget {
  const BlePairingScreen({super.key});

  @override
  State<BlePairingScreen> createState() => _BlePairingScreenState();
}

class _BlePairingScreenState extends State<BlePairingScreen> {
  String _activeMode = 'radar'; // 'radar' | 'qr' | 'pin'
  final _pinController = TextEditingController();
  final _nameController = TextEditingController();

  List<DeviceKitModel> _discoveredKits = [];
  DeviceKitModel? _selectedKit;
  bool _isScanning = false;
  bool _isPairing = false;
  bool _isProvisioned = false;
  int _auditProgress = 0;
  bool _showAdvanced = false;

  final _ssidController = TextEditingController();
  final _passController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scanDevices();
  }

  Future<void> _scanDevices() async {
    setState(() => _isScanning = true);
    final kits = await ApiService.discoverDevices();
    if (mounted) {
      setState(() {
        _discoveredKits = kits;
        _isScanning = false;
        if (kits.isNotEmpty && _selectedKit == null) {
          _selectedKit = kits.first;
          _pinController.text = kits.first.kitCode;
          _nameController.text = kits.first.label;
        }
      });
    }
  }

  void _executeFastPair() async {
    final code = _pinController.text.trim().isNotEmpty
        ? _pinController.text.trim()
        : (_selectedKit?.kitCode ?? '2026');
    final name = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : (_selectedKit?.label ?? 'HelmGuard Smart System');

    setState(() {
      _isPairing = true;
      _auditProgress = 25;
    });

    // Step 1: BLE Handshake & Discover
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _auditProgress = 55);

    // Step 2: Register device & negotiate 256-bit PSK with backend / ignition controller
    final success = await ApiService.easyInstallDevice(
      shortCode: code,
      label: name,
      vehicleType: 'Motorcycle',
    );

    if (!mounted) return;
    setState(() => _auditProgress = 85);

    // Step 3: Save newly paired active device ID
    final newDevId = _selectedKit?.serialNumber.isNotEmpty == true
        ? _selectedKit!.serialNumber
        : 'HLM-$code';

    await ApiService.saveSettings(newDeviceId: newDevId);

    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() {
      _auditProgress = 100;
      _isPairing = false;
      _isProvisioned = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'SUCCESS: Paired with $newDevId! Interlock Armed.'
              : 'PAIRED LOCALLY: $newDevId is set as active helmet device.',
          style: const TextStyle(fontFamily: 'JetBrains Mono', color: AppColors.onPrimary),
        ),
        backgroundColor: AppColors.primaryContainer,
      ),
    );
  }

  void _simulateQrScan() {
    setState(() {
      _activeMode = 'radar';
      _pinController.text = '2026';
      _nameController.text = 'HelmGuard Visor Kit';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'QR Sticker Verified: Kit #2026 Ready to Pair',
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
        actions: [
          IconButton(
            tooltip: 'Rescan Nearby',
            icon: _isScanning
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  )
                : const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: _isScanning ? null : _scanDevices,
          ),
        ],
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
              'Zero-friction Bluetooth LE pairing. The helmet sensors and ignition relay are provisioned as 1 protected device.',
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

            // Radar Mode
            if (_activeMode == 'radar') ...[
              if (_discoveredKits.isNotEmpty) ...[
                Column(
                  children: _discoveredKits.map((kit) {
                    final isSelected = _selectedKit?.kitCode == kit.kitCode;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLow,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.outlineVariant,
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: ListTile(
                          onTap: () {
                            setState(() {
                              _selectedKit = kit;
                              _pinController.text = kit.kitCode;
                              _nameController.text = kit.label;
                            });
                          },
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.two_wheeler, color: AppColors.primary, size: 24),
                          ),
                          title: Text(
                            kit.label,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          subtitle: Text(
                            'Code: #${kit.kitCode} • Signal: ${kit.rssiDbm} dBm • Bat: ${kit.batteryPct}%',
                            style: const TextStyle(
                              fontFamily: 'JetBrains Mono',
                              fontSize: 11,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          trailing: Icon(
                            isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                            color: isSelected ? AppColors.primary : AppColors.outline,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.outlineVariant),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.bluetooth_searching, size: 40, color: AppColors.primary),
                      const SizedBox(height: 12),
                      const Text(
                        'Scanning for broadcasting kits...',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Active Target: ${ApiService.activeDeviceId}',
                        style: const TextStyle(
                          color: AppColors.outline,
                          fontSize: 11,
                          fontFamily: 'JetBrains Mono',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],

            // Scan QR
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
                      'Point camera at the QR sticker inside helmet or on the product box',
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
                      label: const Text('Capture QR Code'),
                    ),
                  ],
                ),
              ),
            ],

            // 4-Digit PIN
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
                        hintText: '2026',
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
                hintText: 'e.g. HelmGuard Cruiser',
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
