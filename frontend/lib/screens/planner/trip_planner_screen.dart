import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'saved_trips_screen.dart';
import 'trip_result_screen.dart';

class TripPlannerScreen extends StatefulWidget {
  const TripPlannerScreen({super.key});

  @override
  State<TripPlannerScreen> createState() => _TripPlannerScreenState();
}

class _TripPlannerScreenState extends State<TripPlannerScreen> {
  int selectedDays = 3;
  double budget = 500;

  String selectedStyle = 'Adventure';
  String selectedTransport = 'Car';
  String selectedLanguage = 'English';
  String selectedCity = 'Amman';

  bool isLoading = false;

  final List<String> interests = [
    'Archaeology',
    'Food',
    'Hiking',
    'Museums',
    'Desert',
    'Shopping',
    'Beaches',
    'Culture',
  ];

  final Set<String> selectedInterests = {};

  final Dio dio = Dio(
    BaseOptions(
     // baseUrl: 'http://10.0.2.2:8000',
     // baseUrl: 'http://192.168.100.248:8000',
     //mama
      baseUrl: 'http://192.168.100.246:8000',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 90),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  );

  Future<void> generateTrip() async {
    if (selectedInterests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select at least one interest.',
          ),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await dio.post(
        '/planner/',
        data: {
          'days': selectedDays,
          'budget': '${budget.toInt()} JOD',
          'interests': selectedInterests.toList(),
          'style': selectedStyle,
          'transport': selectedTransport,
          'language': selectedLanguage,
          'start_city': selectedCity,
        },
      );

      if (!mounted) return;

      final responseData = response.data;

      dynamic plan;

      if (responseData is Map) {
        plan = responseData['plan'];
      } else {
        plan = responseData;
      }

      if (plan is Map && plan.containsKey('error')) {
        final message =
            plan['fallback_message']?.toString() ??
            plan['error']?.toString() ??
            'The AI planner is currently unavailable.';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 6),
          ),
        );

        return;
      }

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TripResultScreen(
            plan: plan,
            days: selectedDays,
            budget: budget.toInt(),
            interests: selectedInterests.toList(),
          ),
        ),
      );
    } on DioException catch (error) {
      if (!mounted) return;

      String errorMessage =
          'Failed to generate the trip.';

      if (error.type ==
          DioExceptionType.connectionTimeout) {
        errorMessage =
            'Connection timed out. Make sure the backend is running.';
      } else if (error.type ==
          DioExceptionType.receiveTimeout) {
        errorMessage =
            'The AI took too long to respond. Please try again.';
      } else if (error.type ==
          DioExceptionType.connectionError) {
        errorMessage =
            'Cannot connect to the backend. Make sure Uvicorn is running.';
      } else if (error.response != null) {
        errorMessage =
            'Server error: ${error.response?.statusCode}\n'
            '${error.response?.data}';
      } else if (error.message != null) {
        errorMessage = error.message!;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          duration: const Duration(seconds: 6),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unexpected error: $error',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
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
          'AI Trip Planner',
          style: TextStyle(
            color: AppColors.darkBrown,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Saved Trips',
            icon: const Icon(
              Icons.bookmark_rounded,
              color: AppColors.darkBrown,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const SavedTripsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Plan your perfect Jordan trip',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.darkBrown,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Tell us your preferences and let AI create your itinerary.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),

            const SizedBox(height: 28),

            _buildCard(
              title: 'Number of Days',
              child: DropdownButtonFormField<int>(
                initialValue: selectedDays,
                decoration: _inputDecoration(),
                items: List.generate(
                  14,
                  (index) {
                    final days = index + 1;

                    return DropdownMenuItem(
                      value: days,
                      child: Text('$days Days'),
                    );
                  },
                ),
                onChanged: isLoading
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() {
                            selectedDays = value;
                          });
                        }
                      },
              ),
            ),

            const SizedBox(height: 18),

            _buildCard(
              title: 'Budget',
              child: Column(
                children: [
                  Text(
                    '${budget.toInt()} JOD',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.brown,
                    ),
                  ),

                  Slider(
                    value: budget,
                    min: 50,
                    max: 3000,
                    divisions: 59,
                    activeColor: AppColors.brown,
                    onChanged: isLoading
                        ? null
                        : (value) {
                            setState(() {
                              budget = value;
                            });
                          },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            _buildCard(
              title: 'Travel Style',
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  'Luxury',
                  'Adventure',
                  'Family',
                  'Historical',
                  'Nature',
                ].map(
                  (style) {
                    return ChoiceChip(
                      label: Text(style),
                      selected:
                          selectedStyle == style,
                      selectedColor:
                          AppColors.brown.withValues(
                        alpha: 0.25,
                      ),
                      onSelected: isLoading
                          ? null
                          : (_) {
                              setState(() {
                                selectedStyle =
                                    style;
                              });
                            },
                    );
                  },
                ).toList(),
              ),
            ),

            const SizedBox(height: 18),

            _buildCard(
              title: 'Interests',
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: interests.map(
                  (interest) {
                    return FilterChip(
                      label: Text(interest),
                      selected:
                          selectedInterests
                              .contains(interest),
                      selectedColor:
                          AppColors.brown.withValues(
                        alpha: 0.25,
                      ),
                      onSelected: isLoading
                          ? null
                          : (selected) {
                              setState(() {
                                if (selected) {
                                  selectedInterests
                                      .add(interest);
                                } else {
                                  selectedInterests
                                      .remove(interest);
                                }
                              });
                            },
                    );
                  },
                ).toList(),
              ),
            ),

            const SizedBox(height: 18),

            _buildCard(
              title: 'Transportation',
              child:
                  DropdownButtonFormField<String>(
                initialValue: selectedTransport,
                decoration: _inputDecoration(),
                items: const [
                  DropdownMenuItem(
                    value: 'Car',
                    child: Text('Car'),
                  ),
                  DropdownMenuItem(
                    value: 'Public Transport',
                    child:
                        Text('Public Transport'),
                  ),
                  DropdownMenuItem(
                    value: 'Walking',
                    child: Text('Walking'),
                  ),
                ],
                onChanged: isLoading
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() {
                            selectedTransport =
                                value;
                          });
                        }
                      },
              ),
            ),

            const SizedBox(height: 18),

            _buildCard(
              title: 'Language',
              child:
                  DropdownButtonFormField<String>(
                initialValue: selectedLanguage,
                decoration: _inputDecoration(),
                items: const [
                  DropdownMenuItem(
                    value: 'Arabic',
                    child: Text('Arabic'),
                  ),
                  DropdownMenuItem(
                    value: 'English',
                    child: Text('English'),
                  ),
                ],
                onChanged: isLoading
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() {
                            selectedLanguage =
                                value;
                          });
                        }
                      },
              ),
            ),

            const SizedBox(height: 18),

            _buildCard(
              title: 'Start City',
              child:
                  DropdownButtonFormField<String>(
                initialValue: selectedCity,
                decoration: _inputDecoration(),
                items: const [
                  DropdownMenuItem(
                    value: 'Amman',
                    child: Text('Amman'),
                  ),
                  DropdownMenuItem(
                    value: 'Aqaba',
                    child: Text('Aqaba'),
                  ),
                  DropdownMenuItem(
                    value: 'Irbid',
                    child: Text('Irbid'),
                  ),
                  DropdownMenuItem(
                    value: 'Zarqa',
                    child: Text('Zarqa'),
                  ),
                ],
                onChanged: isLoading
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() {
                            selectedCity = value;
                          });
                        }
                      },
              ),
            ),

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      AppColors.darkBrown,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      AppColors.darkBrown
                          .withValues(alpha: 0.65),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                ),
                onPressed:
                    isLoading ? null : generateTrip,
                child: isLoading
                    ? const Row(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .center,
                        children: [
                          SizedBox(
                            width: 23,
                            height: 23,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Generating your trip...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    : const Row(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .center,
                        children: [
                          Icon(
                            Icons.auto_awesome,
                          ),
                          SizedBox(width: 9),
                          Text(
                            'Generate AI Trip',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.05,
            ),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.darkBrown,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: AppColors.sand,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: AppColors.brown,
          width: 1.5,
        ),
      ),
    );
  }
}