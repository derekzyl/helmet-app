import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class BreathalyzerModal extends StatefulWidget {
  const BreathalyzerModal({super.key});

  @override
  State<BreathalyzerModal> createState() => _BreathalyzerModalState();
}

class _BreathalyzerModalState extends State<BreathalyzerModal> {
  double _blowProgress = 0.0;
  bool _isTesting = false;
  bool _isCompleted = false;
  double _measuredBac = 0.0;
  Timer? _timer;

  void _startBreathTest() {
    setState(() {
      _isTesting = true;
      _blowProgress = 0.0;
      _isCompleted = false;
    });

    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_blowProgress >= 1.0) {
        timer.cancel();
        final telemetry = await ApiService.getLatestTelemetry();
        if (mounted) {
          setState(() {
            _blowProgress = 1.0;
            _isTesting = false;
            _isCompleted = true;
            _measuredBac = telemetry?.bacLevel ?? 0.000;
          });
        }
      } else {
        setState(() {
          _blowProgress += 0.04;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(top: BorderSide(color: AppColors.outlineVariant, width: 1.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'MQ-3 BREATHALYZER RETEST',
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
            'Breathe Continuously into Sensor',
            style: TextStyle(
              color: AppColors.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // Central Visualizer
          if (!_isCompleted) ...[
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceContainer,
                border: Border.all(
                  color: _isTesting ? AppColors.tertiary : AppColors.outlineVariant,
                  width: 2,
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.air,
                  size: 48,
                  color: _isTesting ? AppColors.tertiary : AppColors.outline,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _blowProgress,
                backgroundColor: AppColors.surfaceLowest,
                color: AppColors.tertiary,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _isTesting
                ? 'BLOW NOW: Keep steady breath... ${(100 * _blowProgress).toInt()}%'
                : 'Prepare to exhale steadily for 3 seconds.',
              style: const TextStyle(
                color: AppColors.onSurfaceVariant,
                fontSize: 12,
                fontFamily: 'JetBrains Mono',
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryContainer,
                  foregroundColor: AppColors.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                onPressed: _isTesting ? null : _startBreathTest,
                child: Text(
                  _isTesting ? 'ANALYZING BREATH SAMPLE...' : 'START BREATH TEST',
                  style: const TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ] else ...[
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryContainer.withValues(alpha: 0.2),
                border: Border.all(color: AppColors.primary),
              ),
              child: const Icon(Icons.check, color: AppColors.primary, size: 40),
            ),
            const SizedBox(height: 16),
            Text(
              '${_measuredBac.toStringAsFixed(3)}% BAC',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                fontFamily: 'JetBrains Mono',
              ),
            ),
            const Text(
              'SOBER / LEGAL TO RIDE (Threshold 0.050%)',
              style: TextStyle(
                color: AppColors.onSurfaceVariant,
                fontSize: 12,
                fontFamily: 'JetBrains Mono',
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surfaceContainer,
                  foregroundColor: AppColors.onSurface,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'APPLY & RETURN TO COCKPIT',
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
