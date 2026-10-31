import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/ble_provision_service.dart';

class BlePairingScreen extends StatefulWidget {
  const BlePairingScreen({super.key});

  @override
  State<BlePairingScreen> createState() => _BlePairingScreenState();
}

class _BlePairingScreenState extends State<BlePairingScreen> {
  final _ssidController = TextEditingController(text: BleProvisionService.defaultWifiSsid);
  final _passController = TextEditingController(text: BleProvisionService.defaultWifiPass);
  final _helmetIdController = TextEditingController(text: BleProvisionService.defaultHelmetId);
  final _ignitionIdController = TextEditingController(text: BleProvisionService.defaultIgnitionId);

  List<ProvScanHit> _hits = [];
  ProvScanHit? _helmet;
  ProvScanHit? _ignition;
  bool _isScanning = false;
  bool _isPairing = false;
  bool _isProvisioned = false;
  bool _autoConnect = true;
  bool _softApOnly = true; // peer SoftAP after handshake — no phone Wi‑Fi required
  bool _showAdvanced = false;
  int _progress = 0;
  String _statusLine = 'Power both boards. LEDs blink while connecting / pairing.';
  String _auditStep = '';

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    await BleProvisionService.init();
    if (!mounted) return;
    setState(() {
      _ssidController.text = BleProvisionService.wifiSsid;
      _passController.text = BleProvisionService.wifiPass;
      _helmetIdController.text = BleProvisionService.helmetDeviceId;
      _ignitionIdController.text = BleProvisionService.ignitionDeviceId;
      _autoConnect = BleProvisionService.autoConnect;
      _isProvisioned = BleProvisionService.pairingPsk.isNotEmpty &&
          BleProvisionService.pairingPsk != '';
    });
  }

  Future<void> _scanBle() async {
    if (_isScanning) return;
    setState(() {
      _isScanning = true;
      _statusLine = 'Preparing Bluetooth scan…';
      _hits = [];
      _helmet = null;
      _ignition = null;
    });

    try {
      await BleProvisionService.startScan(
        onStatus: (s) {
          if (!mounted) return;
          setState(() => _statusLine = s);
        },
        onUpdate: (hits) {
          if (!mounted) return;
          ProvScanHit? h;
          ProvScanHit? i;
          for (final hit in hits) {
            if (hit.kind == ProvDeviceKind.helmet && h == null) h = hit;
            if (hit.kind == ProvDeviceKind.ignition && i == null) i = hit;
          }
          // Auto-pick first unknown slots so unnamed FE20 ads are usable
          for (final hit in hits) {
            if (hit.kind == ProvDeviceKind.unknown) {
              if (h == null) {
                h = hit;
              } else if (i == null && hit.id != h.id) {
                i = hit;
              }
            }
          }
          setState(() {
            _hits = hits;
            _helmet ??= h;
            _ignition ??= i;
            if (_helmet == null && h != null) _helmet = h;
            if (_ignition == null && i != null) _ignition = i;
            _statusLine = hits.isEmpty
                ? 'Scanning… Hold Button B on helmet 5s (LED yellow blink = BLE).'
                : 'Found ${hits.length} device(s). Select helmet + ignition, then Pair.';
          });
        },
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      setState(() => _statusLine = msg.contains('frequently')
          ? 'Android blocked rapid scans — wait ~10s and tap Scan again.'
          : 'Scan failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_statusLine, style: const TextStyle(fontFamily: 'JetBrains Mono')),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  Future<void> _pairBoth() async {
    if (_helmet == null || _ignition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Select both Helmet (SH-HLM-PROV) and Ignition (SH-IGN-PROV) first.',
            style: TextStyle(fontFamily: 'JetBrains Mono'),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final ssid = _softApOnly
        ? BleProvisionService.softApOnlySsid
        : (_ssidController.text.trim().isEmpty
            ? 'SmartHelmet_AP'
            : _ssidController.text.trim());
    final pass = _softApOnly
        ? BleProvisionService.defaultWifiPass
        : (_passController.text.trim().isEmpty
            ? BleProvisionService.defaultWifiPass
            : _passController.text.trim());
    final helmetId = _helmetIdController.text.trim().isEmpty
        ? BleProvisionService.defaultHelmetId
        : _helmetIdController.text.trim();
    final ignitionId = _ignitionIdController.text.trim().isEmpty
        ? BleProvisionService.defaultIgnitionId
        : _ignitionIdController.text.trim();

    setState(() {
      _isPairing = true;
      _progress = 5;
      _auditStep = 'Starting dual-device BLE provision…';
    });

    try {
      await BleProvisionService.pairBoth(
        helmet: _helmet!,
        ignition: _ignition!,
        ssid: ssid,
        pass: pass,
        helmetId: helmetId,
        ignitionId: ignitionId,
        onStep: (s) {
          if (!mounted) return;
          setState(() => _auditStep = s);
        },
        onProgress: (p) {
          if (!mounted) return;
          setState(() => _progress = p);
        },
      );

      await BleProvisionService.persistCredentials(auto: _autoConnect);
      await ApiService.saveSettings(newDeviceId: helmetId);

      // Best-effort cloud registry (non-blocking for local pair success)
      final digits = helmetId.replaceAll(RegExp(r'[^0-9]'), '');
      final padded = (digits.isEmpty ? '2026' : digits).padLeft(4, '0');
      final shortCode = padded.length <= 4 ? padded : padded.substring(padded.length - 4);
      await ApiService.easyInstallDevice(
        shortCode: shortCode,
        label: 'HelmGuard Kit',
        vehicleType: 'Motorcycle',
      );

      if (!mounted) return;
      setState(() {
        _isPairing = false;
        _isProvisioned = true;
        _progress = 100;
        _statusLine = 'Paired. Boards reboot and auto-connect (LEDs → green when link OK).';
        _auditStep = 'Done — default auto-connect enabled';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'SUCCESS: Helmet + Ignition paired over BLE. Auto-connect armed.',
            style: TextStyle(fontFamily: 'JetBrains Mono', color: AppColors.onPrimary),
          ),
          backgroundColor: AppColors.primaryContainer,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isPairing = false;
        _statusLine = 'Pairing failed: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pairing failed: $e', style: const TextStyle(fontFamily: 'JetBrains Mono')),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  void dispose() {
    BleProvisionService.stopScan();
    _ssidController.dispose();
    _passController.dispose();
    _helmetIdController.dispose();
    _ignitionIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Pairing'),
        actions: [
          IconButton(
            tooltip: 'Scan BLE',
            icon: _isScanning
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  )
                : const Icon(Icons.bluetooth_searching, color: AppColors.primary),
            onPressed: _isScanning || _isPairing ? null : _scanBle,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: const Text(
                  'APP-CONTROLLED SETUP (NO LCD REQUIRED)',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 10,
                    fontFamily: 'JetBrains Mono',
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Pair Helmet + Ignition',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              _statusLine,
              style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13),
            ),
            const SizedBox(height: 12),

            // LED legend
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceLow,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LED MEANINGS',
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.outline,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text('Helmet: yellow blink = Wi-Fi / BLE attempt · Y+R alt = SoftAP scan · green = link OK',
                      style: TextStyle(fontSize: 11, fontFamily: 'JetBrains Mono')),
                  SizedBox(height: 4),
                  Text('Ignition: red blink = Wi-Fi try · green blink = SoftAP wait · G/R alt = BLE pair · solid = safety state',
                      style: TextStyle(fontSize: 11, fontFamily: 'JetBrains Mono')),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isScanning || _isPairing ? null : _scanBle,
                    icon: const Icon(Icons.radar, size: 18),
                    label: Text(_isScanning ? 'SCANNING…' : 'SCAN BLE'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.surfaceContainer,
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_hits.isEmpty && !_isScanning)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.outlineVariant),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.bluetooth_searching, size: 40, color: AppColors.primary),
                    SizedBox(height: 12),
                    Text('No provisioning beacons yet',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    SizedBox(height: 4),
                    Text(
                      'Boards auto-advertise BLE after ~20–25s with no link, or hold Button B / Button 2 for 5s.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12),
                    ),
                  ],
                ),
              ),

            ..._hits.map((hit) {
              final selected = (hit.kind == ProvDeviceKind.helmet && _helmet?.id == hit.id) ||
                  (hit.kind == ProvDeviceKind.ignition && _ignition?.id == hit.id);
              final label = hit.kind == ProvDeviceKind.helmet
                  ? 'HELMET'
                  : hit.kind == ProvDeviceKind.ignition
                      ? 'IGNITION'
                      : 'DEVICE';
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? AppColors.primary : AppColors.outlineVariant,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Material(
                  color: AppColors.surfaceLow,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    splashColor: AppColors.primary.withValues(alpha: 0.18),
                    highlightColor: AppColors.primary.withValues(alpha: 0.08),
                    onTap: () {
                      setState(() {
                        if (hit.kind == ProvDeviceKind.helmet) {
                          _helmet = hit;
                        } else if (hit.kind == ProvDeviceKind.ignition) {
                          _ignition = hit;
                        } else if (_helmet == null) {
                          _helmet = hit;
                        } else if (_ignition == null || _ignition?.id == hit.id) {
                          _ignition = hit;
                        } else {
                          _helmet = hit;
                        }
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          Icon(
                            hit.kind == ProvDeviceKind.ignition
                                ? Icons.electrical_services
                                : Icons.sports_motorsports,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(hit.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                Text(
                                  '$label · ${hit.rssi} dBm · ${hit.id}',
                                  style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            selected ? Icons.check_circle : Icons.circle_outlined,
                            color: selected ? AppColors.primary : AppColors.outline,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 8),
            Material(
              color: AppColors.surfaceLow,
              borderRadius: BorderRadius.circular(8),
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                tileColor: AppColors.surfaceLow,
                title: const Text('Peer SoftAP (no phone Wi‑Fi)', style: TextStyle(fontSize: 14)),
                subtitle: const Text(
                  'After pairing, helmet ↔ ignition talk directly. Ignition works offline.',
                  style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                ),
                value: _softApOnly,
                activeThumbColor: AppColors.primary,
                onChanged: _isPairing
                    ? null
                    : (v) => setState(() {
                          _softApOnly = v;
                          _showAdvanced = !v;
                        }),
              ),
            ),
            const SizedBox(height: 8),
            Material(
              color: AppColors.surfaceLow,
              borderRadius: BorderRadius.circular(8),
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                tileColor: AppColors.surfaceLow,
                title: const Text('Default auto-connect', style: TextStyle(fontSize: 14)),
                subtitle: const Text(
                  'Boards reconnect SoftAP / Wi‑Fi after reboot',
                  style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                ),
                value: _autoConnect,
                activeThumbColor: AppColors.primary,
                onChanged: _isPairing
                    ? null
                    : (v) async {
                        setState(() => _autoConnect = v);
                        await BleProvisionService.persistCredentials(auto: v);
                      },
              ),
            ),

            InkWell(
              onTap: () => setState(() => _showAdvanced = !_showAdvanced),
              child: Row(
                children: [
                  Text(
                    _showAdvanced ? 'Hide Wi-Fi / IDs' : 'Wi-Fi & device IDs',
                    style: const TextStyle(fontSize: 11, color: AppColors.outline, fontFamily: 'JetBrains Mono'),
                  ),
                  Icon(_showAdvanced ? Icons.expand_less : Icons.expand_more, size: 16, color: AppColors.outline),
                ],
              ),
            ),
            if (_showAdvanced) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _ssidController,
                decoration: const InputDecoration(
                  labelText: 'Shared Wi-Fi SSID (optional cloud monitoring)',
                  filled: true,
                  helperText: 'Only needed if Peer SoftAP is OFF. SoftAP peer works without this.',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Wi-Fi Password', filled: true),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _helmetIdController,
                decoration: const InputDecoration(labelText: 'Helmet Device ID', filled: true),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _ignitionIdController,
                decoration: const InputDecoration(labelText: 'Ignition Device ID', filled: true),
              ),
            ],

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryContainer,
                  foregroundColor: AppColors.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _isPairing ? null : _pairBoth,
                icon: _isPairing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimary),
                      )
                    : const Icon(Icons.link, size: 20),
                label: Text(
                  _isPairing
                      ? 'PAIRING BOTH ($_progress%)…'
                      : _isProvisioned
                          ? 'RE-PAIR BOTH DEVICES'
                          : 'PAIR HELMET + IGNITION',
                  style: const TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),

            if (_isPairing || _isProvisioned) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: _progress / 100.0,
                backgroundColor: AppColors.surfaceContainer,
                color: AppColors.primary,
              ),
              const SizedBox(height: 8),
              Text(
                _auditStep,
                style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 12, color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              _buildAuditItem('Helmet BLE credentials', _progress >= 50),
              _buildAuditItem('Ignition BLE credentials', _progress >= 90),
              _buildAuditItem('Shared PSK + auto-connect saved', _progress >= 100),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAuditItem(String title, bool done) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(done ? Icons.check_circle : Icons.schedule, size: 16, color: done ? AppColors.primary : AppColors.outline),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 12, fontFamily: 'JetBrains Mono')),
        ],
      ),
    );
  }
}
