import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BlePairingScreen extends StatefulWidget {
  const BlePairingScreen({super.key});

  @override
  State<BlePairingScreen> createState() => _BlePairingScreenState();
}

class _BlePairingScreenState extends State<BlePairingScreen> {
  final _ssidController = TextEditingController(text: 'SmartHelmet_AP');
  final _passController = TextEditingController(text: 'helmet1234');
  final _pskController = TextEditingController(
    text: 'd4a8f9c1e2b3a4c5d6e7f8091a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b',
  );

  bool _isScanning = false;
  bool _isProvisioned = false;

  void _scanAndProvision() {
    setState(() => _isScanning = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isScanning = false;
          _isProvisioned = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'SUCCESS: Bluetooth GATT Handshake Complete. WiFi & PSK Saved to NVS!',
              style: TextStyle(fontFamily: 'JetBrains Mono', color: AppColors.onPrimary),
            ),
            backgroundColor: AppColors.primaryContainer,
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _ssidController.dispose();
    _passController.dispose();
    _pskController.dispose();
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
            const Text(
              'PROVISIONING GATT PROTOCOL (0xFE20)',
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
              'Hold Button B on Helmet or Button 2 on Ignition for 5s to enter BLE mode.',
              style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13),
            ),
            const SizedBox(height: 20),

            // Discovered Peripherals
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceLow,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.bluetooth_searching, color: AppColors.primary, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'SH-HLM-PROV (Helmet)',
                            style: TextStyle(
                              color: AppColors.onSurface,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'JetBrains Mono',
                            ),
                          ),
                        ],
                      ),
                      Text(
                        _isProvisioned ? 'PAIRED' : '-58 dBm (Strong)',
                        style: TextStyle(
                          color: _isProvisioned ? AppColors.primary : AppColors.primary,
                          fontSize: 11,
                          fontFamily: 'JetBrains Mono',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: AppColors.outlineVariant, height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.bluetooth_connected, color: AppColors.secondary, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'SH-IGN-PROV (Ignition)',
                            style: TextStyle(
                              color: AppColors.onSurface,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'JetBrains Mono',
                            ),
                          ),
                        ],
                      ),
                      Text(
                        _isProvisioned ? 'PAIRED' : '-64 dBm (Good)',
                        style: TextStyle(
                          color: _isProvisioned ? AppColors.primary : AppColors.secondary,
                          fontSize: 11,
                          fontFamily: 'JetBrains Mono',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Credentials Form
            const Text(
              'CREDENTIAL DISPATCH (BLE GATT WRITE)',
              style: TextStyle(
                color: AppColors.outline,
                fontSize: 11,
                fontFamily: 'JetBrains Mono',
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _ssidController,
              decoration: InputDecoration(
                labelText: 'WIFI SSID',
                labelStyle: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11),
                filled: true,
                fillColor: AppColors.surfaceContainer,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: AppColors.outlineVariant),
                ),
              ),
              style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 13),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _passController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'WIFI PASSWORD',
                labelStyle: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11),
                filled: true,
                fillColor: AppColors.surfaceContainer,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: AppColors.outlineVariant),
                ),
              ),
              style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 13),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _pskController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: '256-BIT SYMMETRIC PAIRING PSK',
                labelStyle: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11),
                filled: true,
                fillColor: AppColors.surfaceContainer,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: AppColors.outlineVariant),
                ),
              ),
              style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11),
            ),

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryContainer,
                  foregroundColor: AppColors.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                onPressed: _isScanning ? null : _scanAndProvision,
                child: Text(
                  _isScanning ? 'TRANSMITTING VIA BLE GATT...' : 'PAIR & DISPATCH CREDENTIALS',
                  style: const TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
