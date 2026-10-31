import 'package:flutter/material.dart';
import '../models/telemetry_model.dart';
import '../theme/app_theme.dart';

/// Dual-device link card: Helmet, Ignition, peer SoftAP, and cloud/backend.
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
    final peerOk = telemetry.localLinkConnected;
    final helmetCloud = telemetry.internetOk;
    final appCloud = cloudWsLive || telemetry.isLive;
    // Ignition is "up" when SoftAP status answered or peer heartbeats are flowing
    final ignitionOk = peerOk ||
        telemetry.wifiMode == 'SOFTAP' ||
        (telemetry.lockReason != null && telemetry.lockReason != 'AWAITING_TELEMETRY');
    final helmetOk = peerOk || telemetry.isLive || telemetry.batteryPercentage > 0;
    final bothOk = peerOk;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: bothOk
              ? AppColors.primary.withValues(alpha: 0.45)
              : AppColors.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'DEVICE LINK STATUS',
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.outline,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: bothOk
                      ? AppColors.primaryContainer.withValues(alpha: 0.2)
                      : AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  bothOk ? 'BOTH LINKED' : 'NOT PAIRED LIVE',
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: bothOk ? AppColors.primary : AppColors.outline,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _row(
            Icons.sports_motorsports,
            'Helmet unit',
            helmetOk ? 'SEEN' : 'OFFLINE',
            helmetOk,
            subtitle: helmetOk
                ? 'LED: green = peer · green+yellow = peer+cloud'
                : 'No helmet telemetry yet',
          ),
          const SizedBox(height: 8),
          _row(
            Icons.electrical_services,
            'Ignition unit',
            ignitionOk ? 'SEEN' : 'OFFLINE',
            ignitionOk,
            subtitle: ignitionOk
                ? 'LED: solid green when helmet heartbeat OK'
                : 'Power ignition SoftAP / wait for link',
          ),
          const SizedBox(height: 8),
          _row(
            Icons.link,
            'Helmet ↔ Ignition (SoftAP peer)',
            peerOk ? 'CONNECTED' : 'NO LINK',
            peerOk,
            subtitle: peerOk
                ? 'Interlock path live — both LEDs should be green'
                : 'Helmet must join SH-IGN-* SoftAP',
          ),
          const SizedBox(height: 8),
          _row(
            Icons.cloud_upload_outlined,
            'Helmet → backend (sensor upload)',
            helmetCloud ? 'UPLOADING' : 'NOT UPLOADING',
            helmetCloud,
            subtitle: helmetCloud
                ? 'Ignition STA (home / phone hotspot) forwarding live MPU/PIR/MQ-3'
                : peerOk
                    ? 'Peer OK offline — set home or phone-hotspot SSID on ignition for cloud'
                    : 'No peer SoftAP / no uplink',
          ),
          const SizedBox(height: 8),
          _row(
            Icons.phone_android,
            'App → backend (WS / REST)',
            appCloud ? 'ONLINE' : 'OFFLINE',
            appCloud,
            subtitle: appCloud
                ? 'Stay on home Wi‑Fi or your hotspot — never join SH-IGN-* SoftAP'
                : 'Check phone internet / API URL',
          ),
          if (telemetry.wifiMode.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Mode ${telemetry.wifiMode}'
              '${telemetry.wifiSsid.isNotEmpty ? " · ${telemetry.wifiSsid}" : ""}'
              ' · RSSI ${telemetry.rssiDbm} dBm'
              '${telemetry.isLive ? " · LIVE" : " · STALE"}',
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
