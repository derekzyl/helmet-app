import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
    setState(() => _isLoading = true);
    final list = await ApiService.getEvents();
    if (mounted) {
      setState(() {
        _events = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _acknowledge(String eventId) async {
    final success = await ApiService.acknowledgeEvent(eventId);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Safety event acknowledged and cleared.',
            style: TextStyle(fontFamily: 'JetBrains Mono', color: AppColors.onPrimary),
          ),
          backgroundColor: AppColors.primaryContainer,
        ),
      );
      _loadEvents();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Incident Alerts & SOS'),
        actions: [
          IconButton(
            tooltip: 'Sync Alerts',
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: _loadEvents,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _events.isEmpty
              ? _buildEmptyState()
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
                      final timeStr = DateFormat('dd MMM, hh:mm a').format(e.createdAt);

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
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  timeStr,
                                  style: const TextStyle(
                                    color: AppColors.outline,
                                    fontSize: 10,
                                    fontFamily: 'JetBrains Mono',
                                  ),
                                ),
                                if (!e.isResolved)
                                  TextButton(
                                    onPressed: () => _acknowledge(e.id),
                                    child: const Text(
                                      'ACKNOWLEDGE',
                                      style: TextStyle(
                                        fontFamily: 'JetBrains Mono',
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  )
                                else
                                  const Text(
                                    'RESOLVED',
                                    style: TextStyle(
                                      color: AppColors.outline,
                                      fontSize: 10,
                                      fontFamily: 'JetBrains Mono',
                                    ),
                                  ),
                              ],
                            ),
                            if (e.latitude != null && e.longitude != null) ...[
                              const SizedBox(height: 6),
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceContainer,
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: const Icon(
                Icons.verified_user_outlined,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'ALL SYSTEMS SECURE',
              style: TextStyle(
                color: AppColors.onSurface,
                fontSize: 15,
                fontWeight: FontWeight.bold,
                fontFamily: 'JetBrains Mono',
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'No impact collisions, unauthorized overrides, or alcohol lockouts detected. Interlock monitors are active and connected.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.onSurfaceVariant,
                fontSize: 12,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.surfaceContainer,
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              onPressed: _loadEvents,
              icon: const Icon(Icons.sync, size: 16),
              label: const Text(
                'REFRESH STATUS',
                style: TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
