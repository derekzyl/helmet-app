import 'package:flutter/material.dart';
import '../models/telemetry_model.dart';
import '../theme/app_theme.dart';

/// Shows Local SoftAP link, shared Wi‑Fi, and internet for helmet (+ ignition when known).
class ConnectivityStatusCard extends StatelessWidget {
  const ConnectivityStatusCard({
    super.key,
    required this.telemetry,
    this.cloudWsLive = false,
  });

  final TelemetryModel telemetry;
  final bool cloudWsLive;

  @override
  Widget build(BuildContext context) {
    final localOk = telemetry.localLinkConnected;
    final sharedWifi = telemetry.sharedWifi || telemetry.wifiMode == 'STA';
    final internet = telemetry.internetOk || cloudWsLive;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'LINK STATUS',
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.outline,
            ),
          ),
          const SizedBox(height: 10),
          _row(
            Icons.link,
            'Helmet ↔ Ignition (SoftAP / local)',
            localOk ? 'CONNECTED' : 'NO LINK',
            localOk,
            subtitle: localOk
                ? 'Ignition interlock can arm without phone or internet'
                : 'Waiting for peer SoftAP / heartbeat',
          ),
          const SizedBox(height: 8),
          _row(
            Icons.wifi,
            'Shared Wi‑Fi (both devices)',
            sharedWifi ? 'ON LAN' : (telemetry.wifiMode == 'SOFTAP' ? 'PEER ONLY' : 'OFF'),
            sharedWifi,
            subtitle: sharedWifi
                ? (telemetry.wifiSsid.isNotEmpty ? telemetry.wifiSsid : 'Infrastructure STA')
                : 'Not required for ignition — SoftAP peer is enough',
          ),
          const SizedBox(height: 8),
          _row(
            Icons.cloud_done_outlined,
            'Internet / cloud telemetry',
            internet ? 'ONLINE' : 'OFFLINE',
            internet,
            subtitle: internet
                ? 'App & dashboard receiving live frames'
                : 'Local safety still works offline',
          ),
          if (telemetry.wifiMode.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Mode: ${telemetry.wifiMode} · RSSI ${telemetry.rssiDbm} dBm',
              style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 10, color: AppColors.outline),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(IconData icon, String title, String status, bool ok, {String? subtitle}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: ok ? AppColors.primary : AppColors.outline),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              if (subtitle != null)
                Text(subtitle, style: const TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant)),
            ],
          ),
        ),
        Text(
          status,
          style: TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: ok ? AppColors.primary : AppColors.outline,
          ),
        ),
      ],
    );
  }
}
