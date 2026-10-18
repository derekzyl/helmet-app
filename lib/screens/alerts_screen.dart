import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/telemetry_model.dart';
import '../services/api_service.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  List<SafetyEventModel> _events = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final list = await ApiService.getEvents();
    if (mounted) {
      setState(() {
        _events = list.isNotEmpty
            ? list
            : [
                SafetyEventModel(
                  id: 'evt-101',
                  deviceId: 'HLM-ESP32-001',
                  eventType: 'COLLISION',
                  severity: 'CRITICAL',
                  description: 'Accident impact detected (5.5G). SIM800L dispatched emergency SMS to contacts.',
                  latitude: 6.5244,
                  longitude: 3.3792,
                  isResolved: false,
                  createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
                ),
                SafetyEventModel(
                  id: 'evt-102',
                  deviceId: 'HLM-ESP32-001',
                  eventType: 'HELMET_REMOVED',
                  severity: 'MEDIUM',
                  description: 'Helmet IR proximity unlatched mid-ride. Anti-stall warning sounded.',
                  isResolved: true,
                  createdAt: DateTime.now().subtract(const Duration(hours: 3)),
                ),
              ];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Incident Alerts & SOS'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _loadEvents,
              color: AppColors.primary,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _events.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final e = _events[index];
                  final isCritical = e.severity == 'CRITICAL';
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLow,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isCritical ? AppColors.error : AppColors.outlineVariant,
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
                                Icon(
                                  isCritical ? Icons.warning : Icons.info_outline,
                                  color: isCritical ? AppColors.error : AppColors.secondary,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  e.eventType,
                                  style: TextStyle(
                                    color: isCritical ? AppColors.error : AppColors.onSurface,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    fontFamily: 'JetBrains Mono',
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isCritical
                                    ? AppColors.errorContainer.withValues(alpha: 0.3)
                                    : AppColors.surfaceContainer,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                e.severity,
                                style: TextStyle(
                                  color: isCritical ? AppColors.error : AppColors.outline,
                                  fontSize: 10,
                                  fontFamily: 'JetBrains Mono',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          e.description,
                          style: const TextStyle(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                        if (e.latitude != null && e.longitude != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'COORDINATES: ${e.latitude!.toStringAsFixed(5)}, ${e.longitude!.toStringAsFixed(5)}',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 10,
                              fontFamily: 'JetBrains Mono',
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}
