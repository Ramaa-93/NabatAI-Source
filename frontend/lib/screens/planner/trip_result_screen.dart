import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/trip_storage_service.dart';

class TripResultScreen extends StatelessWidget {
  final dynamic plan;
  final int days;
  final int budget;
  final List<String> interests;

  const TripResultScreen({
    super.key,
    required this.plan,
    required this.days,
    required this.budget,
    required this.interests,
  });

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> planMap =
        plan is Map<String, dynamic>
            ? plan as Map<String, dynamic>
            : {};

    final String summary =
        planMap['summary']?.toString() ??
        'Your personalized Jordan trip is ready.';

    final List<dynamic> tripDays =
        planMap['days'] is List
            ? planMap['days'] as List<dynamic>
            : [];

    return Scaffold(
      backgroundColor: AppColors.sand,
      appBar: AppBar(
        backgroundColor: AppColors.sand,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: AppColors.darkBrown,
        ),
        title: const Text(
          'Your AI Trip',
          style: TextStyle(
            color: AppColors.darkBrown,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF3C2921),
                    Color(0xFF76503B),
                    Color(0xFFB77E55),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.darkBrown.withOpacity(0.25),
                    blurRadius: 22,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(17),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Your trip is ready!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 27,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    summary,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _InfoBadge(
                        icon: Icons.calendar_month_rounded,
                        text: '$days Days',
                      ),
                      _InfoBadge(
                        icon: Icons.account_balance_wallet_rounded,
                        text: '$budget JOD',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 26),

            const Text(
              'Your interests',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: AppColors.darkBrown,
              ),
            ),

            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: interests.map((interest) {
                return Chip(
                  avatar: const Icon(
                    Icons.favorite_rounded,
                    color: AppColors.brown,
                    size: 17,
                  ),
                  label: Text(interest),
                  backgroundColor: AppColors.white,
                  side: BorderSide.none,
                );
              }).toList(),
            ),

            const SizedBox(height: 28),

            const Text(
              'Daily Itinerary',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.darkBrown,
              ),
            ),

            const SizedBox(height: 14),

            if (tripDays.isEmpty)
              _RawPlanCard(plan: plan)
            else
              ...tripDays.asMap().entries.map((entry) {
                final index = entry.key;
                final value = entry.value;

                Map<String, dynamic> dayData = {};

                if (value is Map<String, dynamic>) {
                  dayData = value;
                } else if (value is Map) {
                  dayData = Map<String, dynamic>.from(value);
                }

                final int dayNumber =
                    int.tryParse(dayData['day']?.toString() ?? '') ??
                    index + 1;

                final String reason =
                    dayData['reason']?.toString() ??
                    dayData['description']?.toString() ??
                    'A balanced day selected by NabatAI.';

                final List<dynamic> places =
                    dayData['places'] is List
                        ? dayData['places'] as List<dynamic>
                        : [];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _DayCard(
                    dayNumber: dayNumber,
                    reason: reason,
                    places: places,
                  ),
                );
              }),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () async {
  final Map<String, dynamic> tripData = {
    'id': DateTime.now().millisecondsSinceEpoch,
    'saved_at': DateTime.now().toIso8601String(),
    'days_count': days,
    'budget': budget,
    'interests': interests,
    'plan': plan,
  };

  await TripStorageService.saveTrip(tripData);

  if (!context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Trip saved successfully.'),
    ),
  );
},
                icon: const Icon(Icons.favorite_border_rounded),
                label: const Text(
                  'Save Trip',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkBrown,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
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

class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoBadge({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 17,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  final int dayNumber;
  final String reason;
  final List<dynamic> places;

  const _DayCard({
    required this.dayNumber,
    required this.reason,
    required this.places,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: AppColors.brown.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Center(
                  child: Text(
                    '$dayNumber',
                    style: const TextStyle(
                      color: AppColors.darkBrown,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Day $dayNumber',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkBrown,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Text(
            reason,
            style: const TextStyle(
              color: Colors.black54,
              height: 1.45,
            ),
          ),

          const SizedBox(height: 16),

          if (places.isEmpty)
            const Text(
              'No places were returned for this day.',
              style: TextStyle(
                color: Colors.black45,
              ),
            )
          else
            ...places.map((value) {
              Map<String, dynamic> place = {};

              if (value is Map<String, dynamic>) {
                place = value;
              } else if (value is Map) {
                place = Map<String, dynamic>.from(value);
              }

              final String name =
                  place['name']?.toString() ??
                  place['name_en']?.toString() ??
                  place['title']?.toString() ??
                  'Tourist destination';

              final String time =
                  place['suggested_time']?.toString() ??
                  place['time']?.toString() ??
                  'Flexible time';

              final String duration =
                  place['duration_hours']?.toString() ??
                  place['duration']?.toString() ??
                  'Not specified';

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.sand,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        color: AppColors.brown,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  Icons.schedule_rounded,
                                  size: 15,
                                  color: Colors.black45,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    '$time • $duration hours',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _RawPlanCard extends StatelessWidget {
  final dynamic plan;

  const _RawPlanCard({
    required this.plan,
  });

  String formatValue(dynamic value, {int level = 0}) {
    final String indent = '  ' * level;

    if (value is Map) {
      return value.entries.map((entry) {
        final String key =
            entry.key.toString().replaceAll('_', ' ');
        final dynamic item = entry.value;

        if (item is Map || item is List) {
          return '$indent$key:\n'
              '${formatValue(item, level: level + 1)}';
        }

        return '$indent$key: $item';
      }).join('\n\n');
    }

    if (value is List) {
      return value.asMap().entries.map((entry) {
        return '$indent${entry.key + 1}. '
            '${formatValue(entry.value, level: level + 1)}';
      }).join('\n\n');
    }

    return '$indent$value';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: SelectableText(
        formatValue(plan),
        style: const TextStyle(
          fontSize: 14,
          height: 1.5,
          color: AppColors.textDark,
        ),
      ),
    );
  }
}