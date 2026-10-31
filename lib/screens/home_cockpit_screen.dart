import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/telemetry_model.dart';
import '../services/api_service.dart';
import '../widgets/connectivity_status_card.dart';
import 'breathalyzer_modal.dart';
import 'pre_ride_check_screen.dart';

class HomeCockpitScreen extends StatefulWidget {
  const HomeCockpitScreen({super.key});

  @override
  State<HomeCockpitScreen> createState() => _HomeCockpitScreenState();
}

class _HomeCockpitScreenState extends State<HomeCockpitScreen> {
  TelemetryModel? _telemetry;
  StreamSubscription<TelemetryModel>? _wsSubscription;
  Timer? _pollTimer;
  bool _isLoading = true;
  bool _isWsActive = false;

  @override
  void initState() {
    super.initState();
    _initConnection();
  }

  void _initConnection() {
    _fetchTelemetry();

    // Listen to live WebSocket telemetry stream
    _wsSubscription = ApiService.telemetryStream.listen(
      (data) {
        if (mounted) {
          setState(() {
            _telemetry = data;
            _isLoading = false;
            _isWsActive = true;
          });
        }
      },
      onError: (_) {
        if (mounted) setState(() => _isWsActive = false);
      },
    );

    // Always poll — SoftAP /status is how live PIR/MPU/MQ-3 reach the biker app
    _pollTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _fetchTelemetry();
      if (mounted) setState(() => _isWsActive = ApiService.isWsConnected);
    });
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchTelemetry() async {
    final t = await ApiService.getLatestTelemetry(deviceId: ApiService.activeDeviceId);
    if (!mounted) return;
    setState(() {
      if (t != null) {
        // Prefer fresher SoftAP frames over older cloud/WS snapshots
        final prev = _telemetry;
        if (prev == null ||
            t.isLive ||
            !prev.isLive ||
            t.timestamp.isAfter(prev.timestamp)) {
          _telemetry = t;
        }
      } else {
        _telemetry ??= TelemetryModel.standby(deviceId: ApiService.activeDeviceId);
      }
      _isLoading = false;
      _isWsActive = ApiService.isWsConnected;
    });
  }

  @override
  Widget build(BuildContext context) {
    final current = _telemetry ?? TelemetryModel.standby(deviceId: ApiService.activeDeviceId);
    final isUnlocked = current.isUnlocked;
    final isLive = current.isLive;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                'assets/images/app_icon.png',
                width: 32,
                height: 32,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.shield,
                  color: AppColors.primary,
                  size: 26,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'HELMGUARD',
                        style: TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _isWsActive
                              ? AppColors.primaryContainer.withValues(alpha: 0.3)
                              : (isLive ? AppColors.surfaceContainer : AppColors.surfaceHighest),
                          border: Border.all(
                            color: _isWsActive
                                ? AppColors.primary
                                : (isLive ? AppColors.secondary : AppColors.outline),
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _isWsActive && isLive
                              ? 'LIVE WS'
                              : (isLive ? 'LIVE LOCAL/REST' : 'CLOUD STALE'),
                          style: TextStyle(
                            color: _isWsActive
                                ? AppColors.primary
                                : (isLive ? AppColors.secondary : AppColors.outline),
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'JetBrains Mono',
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'OPERATOR: ${ApiService.riderName.toUpperCase()} (${ApiService.activeDeviceId})',
                    style: const TextStyle(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 10,
                      fontFamily: 'JetBrains Mono',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Sync Live Data',
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: () {
              setState(() => _isLoading = true);
              ApiService.reconnectWebSocket();
              _fetchTelemetry();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: () async {
                ApiService.reconnectWebSocket();
                await _fetchTelemetry();
              },
              color: AppColors.primary,
              backgroundColor: AppColors.surfaceContainer,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ConnectivityStatusCard(
                      telemetry: current,
                      cloudWsLive: _isWsActive,
                    ),
                    const SizedBox(height: 16),

                    // Standby / Connection info banner if awaiting telemetry
                    if (!isLive) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainer,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.outlineVariant),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.sensors, color: AppColors.secondary, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'AWAITING TELEMETRY PACKET',
                                    style: TextStyle(
                                      color: AppColors.onSurface,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'JetBrains Mono',
                                    ),
                                  ),
                                  Text(
                                    'Paired device ${ApiService.activeDeviceId} is in standby. Ignition locked until pre-ride checklist completes.',
                                    style: const TextStyle(
                                      color: AppColors.onSurfaceVariant,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Primary Hero Card: Ignition Interlock Status
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLow,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isUnlocked
                              ? AppColors.primary.withValues(alpha: 0.4)
                              : AppColors.error.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'IGNITION INTERLOCK',
                                style: TextStyle(
                                  color: AppColors.outline,
                                  fontSize: 11,
                                  fontFamily: 'JetBrains Mono',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Icon(
                                isUnlocked ? Icons.lock_open : Icons.lock,
                                color: isUnlocked ? AppColors.primary : AppColors.error,
                                size: 18,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isUnlocked
                                      ? AppColors.primaryContainer.withValues(alpha: 0.2)
                                      : AppColors.errorContainer.withValues(alpha: 0.2),
                                  border: Border.all(
                                    color: isUnlocked ? AppColors.primary : AppColors.error,
                                  ),
                                ),
                                child: Icon(
                                  isUnlocked ? Icons.check_circle_outline : Icons.warning_amber_rounded,
                                  color: isUnlocked ? AppColors.primary : AppColors.error,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      current.ignitionStatus,
                                      style: const TextStyle(
                                        color: AppColors.onSurface,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'JetBrains Mono',
                                      ),
                                    ),
                                    Text(
                                      isUnlocked
                                          ? 'SSR Active (Engine Circuit ON)'
                                          : 'Engine Disabled: Pre-ride check needed',
                                      style: const TextStyle(
                                        color: AppColors.onSurfaceVariant,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (current.isRunningLatched) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainer,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: AppColors.outlineVariant),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.shield, color: AppColors.primary, size: 14),
                                  SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'ANTI-STALL LATCH ACTIVE: Engine will never be cut mid-ride.',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 10,
                                        fontFamily: 'JetBrains Mono',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (!isUnlocked) ...[
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryContainer,
                                  foregroundColor: AppColors.onPrimary,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const PreRideCheckScreen(),
                                    ),
                                  );
                                  if (mounted) _fetchTelemetry();
                                },
                                child: const Text(
                                  'START PRE-RIDE CHECK & UNLOCK',
                                  style: TextStyle(
                                    fontFamily: 'JetBrains Mono',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Speed & Kinematics Gauge
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLow,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.outlineVariant),
                      ),
                      child: Column(
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'REAL-TIME KINEMATICS',
                                style: TextStyle(
                                  color: AppColors.outline,
                                  fontSize: 11,
                                  fontFamily: 'JetBrains Mono',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Icon(Icons.speed, color: AppColors.primary, size: 16),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            current.speedKmh.toStringAsFixed(1),
                            style: const TextStyle(
                              color: AppColors.onSurface,
                              fontSize: 56,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'JetBrains Mono',
                              height: 1.0,
                            ),
                          ),
                          const Text(
                            'KM / H',
                            style: TextStyle(
                              color: AppColors.outline,
                              fontSize: 12,
                              fontFamily: 'JetBrains Mono',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceContainer,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'IMPACT FORCE',
                                        style: TextStyle(
                                          color: AppColors.outline,
                                          fontSize: 9,
                                          fontFamily: 'JetBrains Mono',
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${(current.impactG ?? 1.0).toStringAsFixed(2)} G',
                                        style: const TextStyle(
                                          color: AppColors.onSurface,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'JetBrains Mono',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceContainer,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'TILT ANGLE',
                                        style: TextStyle(
                                          color: AppColors.outline,
                                          fontSize: 9,
                                          fontFamily: 'JetBrains Mono',
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${(current.tiltDegrees ?? 0.0).toStringAsFixed(1)}°',
                                        style: const TextStyle(
                                          color: AppColors.onSurface,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'JetBrains Mono',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Grid: Helmet Presence & Breathalyzer BAC
                    Row(
                      children: [
                        // Card 1: Head Detection
                        Expanded(
                          child: Container(
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
                                  'HELMET IR',
                                  style: TextStyle(
                                    color: AppColors.outline,
                                    fontSize: 10,
                                    fontFamily: 'JetBrains Mono',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Icon(
                                  current.helmetWorn ? Icons.check_circle : Icons.cancel,
                                  color: current.helmetWorn ? AppColors.primary : AppColors.error,
                                  size: 28,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  current.helmetWorn ? 'WORN' : 'REMOVED',
                                  style: const TextStyle(
                                    color: AppColors.onSurface,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'JetBrains Mono',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Card 2: MQ-3 Breathalyzer
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => const BreathalyzerModal(),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceLow,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.outlineVariant),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'ALCOHOL BAC',
                                        style: TextStyle(
                                          color: AppColors.outline,
                                          fontSize: 10,
                                          fontFamily: 'JetBrains Mono',
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Icon(Icons.air, color: AppColors.tertiary, size: 14),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${current.bacLevel.toStringAsFixed(3)}%',
                                    style: TextStyle(
                                      color: current.bacLevel <= 0.05
                                          ? AppColors.primary
                                          : AppColors.error,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'JetBrains Mono',
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    current.bacLevel <= 0.05 ? 'SOBER (PASS)' : 'FAIL',
                                    style: const TextStyle(
                                      color: AppColors.onSurfaceVariant,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Battery & Power
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLow,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.outlineVariant),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.battery_charging_full, color: AppColors.primary, size: 24),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'HELMET BATTERY (1S2P LI-ION)',
                                    style: TextStyle(
                                      color: AppColors.outline,
                                      fontSize: 10,
                                      fontFamily: 'JetBrains Mono',
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${current.batteryPercentage}% (${current.batteryVoltage?.toStringAsFixed(2) ?? '4.05'}V)',
                                    style: const TextStyle(
                                      color: AppColors.onSurface,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'JetBrains Mono',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainer,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.outlineVariant),
                            ),
                            child: Text(
                              current.batteryPercentage > 20 ? 'HEALTHY' : 'LOW',
                              style: TextStyle(
                                color: current.batteryPercentage > 20 ? AppColors.primary : AppColors.error,
                                fontSize: 10,
                                fontFamily: 'JetBrains Mono',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
