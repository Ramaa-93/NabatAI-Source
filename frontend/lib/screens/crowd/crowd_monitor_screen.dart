import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/crowd_prediction.dart';
import '../../services/api_service.dart';

class CrowdMonitorScreen extends StatefulWidget {
  const CrowdMonitorScreen({super.key});

  @override
  State<CrowdMonitorScreen> createState() => _CrowdMonitorScreenState();
}

class _CrowdMonitorScreenState extends State<CrowdMonitorScreen> {
  final ApiService _apiService = ApiService();

  final List<Map<String, dynamic>> _places = const [
  {
    'id': 1,
    'name': 'Petra Archaeological Park',
    'city': 'Ma\'an Governorate',
    'image': 'assets_new/images_copy/petra.jpg',
  },
  {
    'id': 5,
    'name': 'Jerash Archaeological City',
    'city': 'Jerash Governorate',
    'image': 'assets_new/images_copy/jerash.jpg',
  },
  {
    'id': 26,
    'name': 'Wadi Rum Protected Area',
    'city': 'Aqaba Governorate',
    'image': 'assets_new/images_copy/wadi_rum.jpg',
  },
  {
    'id': 27,
    'name': 'Dead Sea',
    'city': 'Balqa Governorate',
    'image': 'assets_new/images_copy/dead_sea.jpg',
  },
  {
    'id': 8,
    'name': 'Amman Citadel',
    'city': 'Amman Governorate',
    'image': 'assets_new/images_copy/amman_citadel.jpg',
  },
];
  final Map<int, CrowdPrediction> _predictions = {};
  final Map<int, String> _errors = {};

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllPredictions();
  }

  Future<void> _loadAllPredictions() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errors.clear();
      });
    }

    await Future.wait(
      _places.map((place) async {
        final placeId = place['id'] as int;

        try {
          final prediction =
              await _apiService.getCrowdPrediction(placeId);

          _predictions[placeId] = prediction;
          _errors.remove(placeId);
        } catch (error) {
          _errors[placeId] = error.toString();
        }
      }),
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });
  }

  Color _getCrowdColor(String crowdLevel) {
    switch (crowdLevel.toLowerCase()) {
      case 'high':
        return const Color(0xFFB6534B);
      case 'medium':
        return const Color(0xFFD39A3E);
      case 'low':
        return const Color(0xFF4DA85C);
      default:
        return AppColors.olive;
    }
  }

  IconData _getCrowdIcon(String crowdLevel) {
    switch (crowdLevel.toLowerCase()) {
      case 'high':
        return Icons.groups_rounded;
      case 'medium':
        return Icons.group_rounded;
      case 'low':
        return Icons.check_circle_outline_rounded;
      default:
        return Icons.people_outline_rounded;
    }
  }

  IconData _getWeatherIcon(String weather) {
    final value = weather.toLowerCase();

    if (value.contains('rain') ||
        value.contains('drizzle') ||
        value.contains('shower')) {
      return Icons.water_drop_rounded;
    }

    if (value.contains('storm') || value.contains('thunder')) {
      return Icons.thunderstorm_rounded;
    }

    if (value.contains('cloud') || value.contains('fog')) {
      return Icons.cloud_rounded;
    }

    if (value.contains('snow')) {
      return Icons.ac_unit_rounded;
    }

    return Icons.wb_sunny_rounded;
  }

  String _bestTimeFor(CrowdPrediction prediction) {
    switch (prediction.crowdLevel.toLowerCase()) {
      case 'high':
        return 'Early morning';
      case 'medium':
        return 'Before 10:00 AM';
      case 'low':
        return 'Now is a good time';
      default:
        return 'Check again shortly';
    }
  }

  String _crowdStatusText(String crowdLevel) {
    switch (crowdLevel.toLowerCase()) {
      case 'high':
        return 'HIGH crowd level';
      case 'medium':
        return 'MEDIUM crowd level';
      case 'low':
        return 'LOW crowd level';
      default:
        return 'Crowd level unavailable';
    }
  }

  String _englishMessage(
    Map<String, dynamic> place,
    CrowdPrediction prediction,
  ) {
    final placeName = place['name'].toString();

    switch (prediction.crowdLevel.toLowerCase()) {
      case 'high':
        return '$placeName is expected to be busy now. '
            'Consider visiting early in the morning or choosing a nearby alternative.';
      case 'medium':
        return '$placeName has moderate visitor activity. '
            'You can still visit comfortably, but some areas may be busy.';
      case 'low':
        return '$placeName is expected to be quiet now. '
            'This is a great time to visit and enjoy the site with fewer crowds.';
      default:
        return 'Crowd information for $placeName is currently limited. '
            'Refresh the prediction for the latest update.';
    }
  }

  void _showRecommendation(
    Map<String, dynamic> place,
    CrowdPrediction prediction,
  ) {
    final crowdColor = _getCrowdColor(prediction.crowdLevel);
    final alternatives = prediction.suggestedAlternatives;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(30),
        ),
      ),
      builder: (sheetContext) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: crowdColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      color: crowdColor,
                      size: 27,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Smart Recommendation',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          place['name'].toString(),
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _CrowdPercentageRing(
                      percentage: prediction.crowdPercentage,
                      color: crowdColor,
                      size: 145,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      children: [
                        _DetailsTile(
                          icon: Icons.schedule_rounded,
                          label: 'Best time',
                          value: _bestTimeFor(prediction),
                        ),
                        const SizedBox(height: 12),
                        _DetailsTile(
                          icon: _getWeatherIcon(prediction.weather),
                          label: 'Weather',
                          value:
                              '${prediction.temperature.toStringAsFixed(1)}°C • ${prediction.weather}',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: crowdColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: crowdColor.withValues(alpha: 0.14),
                  ),
                ),
                child: Text(
                  _englishMessage(place, prediction),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                        height: 1.55,
                      ),
                ),
              ),
              if (alternatives.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'Suggested Alternatives',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: alternatives.map((alternative) {
                    return Chip(
                      avatar: const Icon(
                        Icons.place_outlined,
                        size: 17,
                        color: AppColors.secondary,
                      ),
                      label: Text(alternative),
                      backgroundColor: AppColors.surface,
                      side: const BorderSide(
                        color: AppColors.border,
                      ),
                      labelStyle: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 26),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                  },
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 34,
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: const Column(
        children: [
          CircularProgressIndicator(
            color: AppColors.primary,
          ),
          SizedBox(height: 16),
          Text(
            'Loading live crowd predictions...',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnavailableCard(
    Map<String, dynamic> place,
    String? error,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.cloud_off_rounded,
              color: AppColors.error,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              error == null
                  ? 'Prediction is currently unavailable.'
                  : 'Could not load ${place['name']}.',
              style: const TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          IconButton(
            onPressed: _loadAllPredictions,
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceCard(Map<String, dynamic> place) {
    final placeId = place['id'] as int;
    final prediction = _predictions[placeId];
    final error = _errors[placeId];

    if (prediction == null) {
      return _buildUnavailableCard(place, error);
    }

    final crowdColor = _getCrowdColor(prediction.crowdLevel);

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _showRecommendation(place, prediction);
          },
          borderRadius: BorderRadius.circular(26),
          child: Ink(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: AppColors.border,
              ),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 18,
                  offset: Offset(0, 9),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.asset(
                        place['image'].toString(),
                        width: 74,
                        height: 74,
                        fit: BoxFit.cover,
                        errorBuilder: (_, error, stackTrace) {
                          return Container(
                            width: 74,
                            height: 74,
                            color: AppColors.lightOlive,
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.landscape_rounded,
                              color: AppColors.primary,
                              size: 32,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            place['name'].toString(),
                            style:
                                Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 15,
                                color: AppColors.secondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                place['city'].toString(),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      fontSize: 12,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _crowdStatusText(prediction.crowdLevel),
                            style: TextStyle(
                              color: crowdColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _CrowdPercentageRing(
                      percentage: prediction.crowdPercentage,
                      color: crowdColor,
                      size: 92,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: crowdColor.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    _englishMessage(place, prediction),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimary,
                          height: 1.45,
                          fontSize: 12,
                        ),
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: _CompactInfo(
                        icon: _getWeatherIcon(prediction.weather),
                        label: prediction.weather,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _CompactInfo(
                        icon: Icons.thermostat_rounded,
                        label:
                            '${prediction.temperature.toStringAsFixed(1)}°C',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _CompactInfo(
                        icon: Icons.schedule_rounded,
                        label: _bestTimeFor(prediction),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.olive,
          ],
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -28,
            bottom: -34,
            child: Icon(
              Icons.groups_2_rounded,
              size: 150,
              color: AppColors.white.withValues(alpha: 0.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  color: AppColors.white,
                  size: 28,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Explore Jordan Smarter',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Live crowd predictions powered by time, weather '
                'and visitor activity.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.white.withValues(alpha: 0.82),
                      height: 1.55,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Crowd Prediction'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadAllPredictions,
            tooltip: 'Refresh predictions',
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadAllPredictions,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 34),
          children: [
            _buildHeroSection(),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Current Crowd Levels',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.lightOlive.withValues(alpha: 0.40),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_predictions.length} locations',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading && _predictions.isEmpty)
              _buildLoadingCard()
            else
              ..._places.map(_buildPlaceCard),
          ],
        ),
      ),
    );
  }
}

class _CrowdPercentageRing extends StatelessWidget {
  final int percentage;
  final Color color;
  final double size;

  const _CrowdPercentageRing({
    required this.percentage,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final safePercentage = percentage.clamp(0, 100);
    final progress = safePercentage / 100;
    final strokeWidth = size >= 120 ? 11.0 : 8.0;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: strokeWidth,
              strokeCap: StrokeCap.round,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$safePercentage%',
                style: TextStyle(
                  color: color,
                  fontSize: size >= 120 ? 31 : 20,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              if (size >= 120) ...[
                const SizedBox(height: 5),
                const Text(
                  'Estimated crowd',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _CompactInfo extends StatelessWidget {
  final IconData icon;
  final String label;

  const _CompactInfo({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 70,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 20,
            color: AppColors.secondary,
          ),
          const SizedBox(height: 7),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailsTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.lightGold.withValues(alpha: 0.38),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: AppColors.secondary,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}