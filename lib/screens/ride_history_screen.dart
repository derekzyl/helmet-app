import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class RideHistoryScreen extends StatelessWidget {
  const RideHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final rides = [
      {
        'title': 'Ikeja Commercial Corridor',
        'date': 'Today, 08:30 AM',
        'distance': '18.4 km',
        'duration': '34 mins',
        'avgSpeed': '32.5 km/h',
        'score': '100%',
        'alcohol': '0.000% BAC',
      },
      {
        'title': 'Victoria Island Route A',
        'date': 'Yesterday, 05:15 PM',
        'distance': '24.1 km',
        'duration': '48 mins',
        'avgSpeed': '30.1 km/h',
        'score': '98%',
        'alcohol': '0.012% BAC',
      },
      {
        'title': 'Lekki Phase 1 Courier Run',
        'date': '16 Oct 2026, 01:20 PM',
        'distance': '12.8 km',
        'duration': '22 mins',
        'avgSpeed': '34.9 km/h',
        'score': '100%',
        'alcohol': '0.000% BAC',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip & Ride History'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: rides.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final r = rides[index];
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceLow,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      r['title']!,
                      style: const TextStyle(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        fontFamily: 'JetBrains Mono',
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.primary),
                      ),
                      child: Text(
                        r['score']!,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontFamily: 'JetBrains Mono',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  r['date']!,
                  style: const TextStyle(
                    color: AppColors.outline,
                    fontSize: 11,
                    fontFamily: 'JetBrains Mono',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStat('DISTANCE', r['distance']!),
                    _buildStat('DURATION', r['duration']!),
                    _buildStat('AVG SPEED', r['avgSpeed']!),
                    _buildStat('BREATH', r['alcohol']!),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.outline,
            fontSize: 9,
            fontFamily: 'JetBrains Mono',
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.onSurface,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            fontFamily: 'JetBrains Mono',
          ),
        ),
      ],
    );
  }
}
