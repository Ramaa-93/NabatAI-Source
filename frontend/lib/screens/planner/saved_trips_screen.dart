import 'package:flutter/material.dart';

import '../../core/services/trip_storage_service.dart';
import '../../core/theme/app_colors.dart';
import 'trip_result_screen.dart';

class SavedTripsScreen extends StatefulWidget {
  const SavedTripsScreen({super.key});

  @override
  State<SavedTripsScreen> createState() => _SavedTripsScreenState();
}

class _SavedTripsScreenState extends State<SavedTripsScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> savedTrips = [];

  @override
  void initState() {
    super.initState();
    loadTrips();
  }

  Future<void> loadTrips() async {
    final trips = await TripStorageService.getTrips();

    if (!mounted) return;

    setState(() {
      savedTrips = trips.reversed.toList();
      isLoading = false;
    });
  }

  Future<void> deleteTrip(int index) async {
    final originalIndex = savedTrips.length - 1 - index;

    await TripStorageService.deleteTrip(originalIndex);

    if (!mounted) return;

    setState(() {
      savedTrips.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Trip deleted successfully.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.sand,
      appBar: AppBar(
        backgroundColor: AppColors.sand,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: AppColors.darkBrown,
        ),
        title: const Text(
          'Saved Trips',
          style: TextStyle(
            color: AppColors.darkBrown,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.brown,
              ),
            )
          : savedTrips.isEmpty
              ? const _EmptySavedTrips()
              : RefreshIndicator(
                  onRefresh: loadTrips,
                  color: AppColors.brown,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: savedTrips.length,
                    itemBuilder: (context, index) {
                      final trip = savedTrips[index];

                      final int days =
                          int.tryParse(
                            trip['days_count']?.toString() ?? '',
                          ) ??
                          0;

                      final int budget =
                          int.tryParse(
                            trip['budget']?.toString() ?? '',
                          ) ??
                          0;

                      final List<String> interests =
                          trip['interests'] is List
                              ? List<String>.from(trip['interests'])
                              : [];

                      final dynamic plan = trip['plan'];

                      final String savedAt =
                          trip['saved_at']?.toString() ?? '';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Dismissible(
                          key: ValueKey(
                            trip['id'] ?? '$index-$savedAt',
                          ),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 24),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: const Icon(
                              Icons.delete_rounded,
                              color: Colors.white,
                            ),
                          ),
                          confirmDismiss: (_) async {
                            return await showDialog<bool>(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: const Text('Delete Trip'),
                                      content: const Text(
                                        'Are you sure you want to delete this trip?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context, false);
                                          },
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context, true);
                                          },
                                          child: const Text(
                                            'Delete',
                                            style: TextStyle(
                                              color: Colors.red,
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ) ??
                                false;
                          },
                          onDismissed: (_) {
                            deleteTrip(index);
                          },
                          child: InkWell(
                            borderRadius: BorderRadius.circular(22),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TripResultScreen(
                                    plan: plan,
                                    days: days,
                                    budget: budget,
                                    interests: interests,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(22),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 14,
                                    offset: const Offset(0, 7),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 54,
                                    height: 54,
                                    decoration: BoxDecoration(
                                      color:
                                          AppColors.brown.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(17),
                                    ),
                                    child: const Icon(
                                      Icons.luggage_rounded,
                                      color: AppColors.brown,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '$days Day Jordan Trip',
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.darkBrown,
                                          ),
                                        ),
                                        const SizedBox(height: 7),
                                        Text(
                                          '$budget JOD • ${interests.length} interests',
                                          style: const TextStyle(
                                            color: Colors.black54,
                                            fontSize: 13,
                                          ),
                                        ),
                                        if (interests.isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Text(
                                            interests.take(3).join(' • '),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: AppColors.brown,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 17,
                                    color: Colors.black38,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class _EmptySavedTrips extends StatelessWidget {
  const _EmptySavedTrips();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.brown.withOpacity(0.14),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.luggage_outlined,
                size: 44,
                color: AppColors.brown,
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'No saved trips yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.darkBrown,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Generate an AI trip and save it to see it here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black54,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}