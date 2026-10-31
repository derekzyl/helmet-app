import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../config/map_config.dart';
import '../models/telemetry_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class LiveMapScreen extends StatefulWidget {
  const LiveMapScreen({super.key});

  @override
  State<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends State<LiveMapScreen> {
  TelemetryModel? _t;
  StreamSubscription? _sub;
  final _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _load();
    _sub = ApiService.telemetryStream.listen((d) {
      if (!mounted) return;
      setState(() => _t = d);
      if (d.latitude.abs() + d.longitude.abs() > 0.01) {
        _mapController.move(LatLng(d.latitude, d.longitude), _mapController.camera.zoom);
      }
    });
  }

  Future<void> _load() async {
    final t = await ApiService.getLatestTelemetry(deviceId: ApiService.activeDeviceId);
    if (mounted) setState(() => _t = t);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    final hasFix = t != null && (t.latitude.abs() + t.longitude.abs() > 0.01);
    final center = hasFix ? LatLng(t.latitude, t.longitude) : const LatLng(6.5244, 3.3792);
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Live Map')),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(initialCenter: center, initialZoom: 14),
            children: [
              TileLayer(
                urlTemplate: MapConfig.rasterUrl(dark: dark),
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.cybergenii.helmet',
              ),
              if (hasFix)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: center,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.location_on, color: AppColors.primary, size: 36),
                    ),
                  ],
                ),
            ],
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceLow.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: Text(
                hasFix
                    ? '${ApiService.activeDeviceId} · ${t!.speedKmh.toStringAsFixed(1)} km/h · '
                        '${t.latitude.toStringAsFixed(5)}, ${t.longitude.toStringAsFixed(5)}'
                    : 'Waiting for GPS fix from helmet…',
                style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11),
              ),
            ),
          ),
          if (MapConfig.apiKey.isEmpty)
            const Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: Material(
                color: Colors.black54,
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: Text(
                    'Set MAP_API_KEY in app/.env for Carto Voyager tiles',
                    style: TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
