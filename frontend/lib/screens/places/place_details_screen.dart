import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../models/place.dart';
import '../../models/crowd_prediction.dart';
import '../../services/api_service.dart';
import '../../services/favorites_service.dart';
import '../guide/voice_guide_screen.dart';

class PlaceDetailsScreen extends StatefulWidget {
  final Place place;

  const PlaceDetailsScreen({
    super.key,
    required this.place,
  });

  @override
  State<PlaceDetailsScreen> createState() => _PlaceDetailsScreenState();
}

class _PlaceDetailsScreenState extends State<PlaceDetailsScreen> {
  bool isFavorite = false;
  bool isUpdatingFavorite = false;

  CrowdPrediction? crowdPrediction;
  bool isLoadingCrowd = true;
  String? crowdError;

  final ApiService _apiService = ApiService();

  Place get place => widget.place;

  @override
  void initState() {
    super.initState();

    loadFavoriteStatus();
    loadCrowdPrediction();
  }

  Future<void> loadFavoriteStatus() async {
    final favorite = await FavoritesService.isFavorite(place.id);

    if (!mounted) return;

    setState(() {
      isFavorite = favorite;
    });
  }

  Future<void> loadCrowdPrediction() async {
    if (mounted) {
      setState(() {
        isLoadingCrowd = true;
        crowdError = null;
      });
    }

    try {
      final prediction = await _apiService.getCrowdPrediction(
        place.id,
      );

      if (!mounted) return;

      setState(() {
        crowdPrediction = prediction;
        isLoadingCrowd = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        crowdPrediction = null;
        isLoadingCrowd = false;
        crowdError = 'Could not load crowd prediction.';
      });

      debugPrint('Crowd prediction error: $error');
    }
  }

  Future<void> toggleFavorite() async {
    if (isUpdatingFavorite) return;

    setState(() {
      isUpdatingFavorite = true;
    });

    try {
      await FavoritesService.toggleFavorite(place);

      if (!mounted) return;

      setState(() {
        isFavorite = !isFavorite;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isFavorite
                ? '${place.name} added to favorites.'
                : '${place.name} removed from favorites.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not update favorites: $error',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isUpdatingFavorite = false;
        });
      }
    }
  }

  String _getPlaceImage(String name) {
    final normalized = name.toLowerCase();

    if (normalized.contains('khazneh')) {
      return 'assets/images/al_khazneh.jpg';
    }

    if (normalized.contains('wadi rum')) {
      return 'assets/images/wadi_rum.jpg';
    }

    if (normalized.contains('petra')) {
      return 'assets/images/petra.jpg';
    }

    if (normalized.contains('jerash')) {
      return 'assets/images/jerash.jpg';
    }

    if (normalized.contains('dead sea')) {
      return 'assets/images/dead_sea.jpg';
    }

    if (normalized.contains('aqaba')) {
      return 'assets/images/aqaba.png';
    }

    if (normalized.contains('amman citadel')) {
      return 'assets/images/amman_citadel.jpg';
    }

    if (normalized.contains('ajloun')) {
      return 'assets/images/ajloun_castle.jpg';
    }

    if (normalized.contains('karak')) {
      return 'assets/images/karak_castle.JPG';
    }

    if (normalized.contains('dana')) {
      return 'assets/images/dana.jpg';
    }

    return 'assets/images/logo.png';
  }

  Future<void> _openNavigation(BuildContext context) async {
    final destination = Uri.encodeComponent(
      '${place.name}, ${place.city}, Jordan',
    );

    final mapsUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=$destination'
      '&travelmode=driving',
    );

    try {
      final opened = await launchUrl(
        mapsUrl,
        mode: LaunchMode.externalApplication,
      );

      if (!opened && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open Google Maps.'),
          ),
        );
      }
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Navigation error: $error'),
        ),
      );
    }
  }

  int _readPlaceId(Place value) {
    return value.id;
  }

  Color _getCrowdColor(String level) {
    switch (level.toLowerCase()) {
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

  IconData _getCrowdIcon(String level) {
    switch (level.toLowerCase()) {
      case 'high':
        return Icons.warning_amber_rounded;
      case 'medium':
        return Icons.groups_2_rounded;
      case 'low':
        return Icons.check_circle_outline_rounded;
      default:
        return Icons.people_outline_rounded;
    }
  }

  IconData _getWeatherIcon(String weather) {
    final normalized = weather.toLowerCase();

    if (normalized.contains('rain') ||
        normalized.contains('drizzle') ||
        normalized.contains('shower')) {
      return Icons.water_drop_rounded;
    }

    if (normalized.contains('storm') ||
        normalized.contains('thunder')) {
      return Icons.thunderstorm_rounded;
    }

    if (normalized.contains('cloud') ||
        normalized.contains('fog')) {
      return Icons.cloud_rounded;
    }

    if (normalized.contains('snow')) {
      return Icons.ac_unit_rounded;
    }

    return Icons.wb_sunny_rounded;
  }

  String _buildEnglishCrowdMessage(
    CrowdPrediction prediction,
  ) {
    switch (prediction.crowdLevel.toLowerCase()) {
      case 'high':
        return '${place.name} is expected to be busy now. '
            'Consider visiting early in the morning or choosing a quieter time.';
      case 'medium':
        return '${place.name} has moderate visitor activity. '
            'You can still visit comfortably, but some areas may be busy.';
      case 'low':
        return '${place.name} is expected to be quiet now. '
            'This is a great time to visit and enjoy the site with fewer crowds.';
      default:
        return 'Crowd information for ${place.name} is currently limited. '
            'Refresh the prediction for the latest update.';
    }
  }

  Widget _buildWeatherItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.border,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: AppColors.secondary,
              size: 23,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCrowdPredictionCard() {
    if (isLoadingCrowd) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
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
        child: const Column(
          children: [
            CircularProgressIndicator(
              color: AppColors.primary,
            ),
            SizedBox(height: 16),
            Text(
              'Analyzing crowd levels...',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      );
    }

    if (crowdPrediction == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: AppColors.border,
          ),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: AppColors.textSecondary,
              size: 42,
            ),
            const SizedBox(height: 12),
            Text(
              crowdError ?? 'Crowd information is unavailable.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: loadCrowdPrediction,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      );
    }

    final prediction = crowdPrediction!;
    final percentage = prediction.crowdPercentage.clamp(0, 100);
    final crowdColor = _getCrowdColor(prediction.crowdLevel);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: crowdColor.withValues(alpha: 0.22),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                  _getCrowdIcon(prediction.crowdLevel),
                  color: crowdColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Smart Crowd Prediction',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${prediction.crowdLevel.toUpperCase()} crowd level',
                      style: TextStyle(
                        color: crowdColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: loadCrowdPrediction,
                tooltip: 'Refresh prediction',
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          LayoutBuilder(
            builder: (context, constraints) {
              final useVerticalLayout = constraints.maxWidth < 360;

              final message = Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: crowdColor.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  prediction.message.isNotEmpty
                      ? prediction.message
                      : _buildEnglishCrowdMessage(prediction),
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(
                        color: AppColors.textPrimary,
                        height: 1.55,
                      ),
                ),
              );

              final ring = _CrowdPercentageRing(
                percentage: percentage,
                color: crowdColor,
              );

              if (useVerticalLayout) {
                return Column(
                  children: [
                    ring,
                    const SizedBox(height: 18),
                    message,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: message),
                  const SizedBox(width: 18),
                  ring,
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Icon(
                Icons.cloud_outlined,
                color: AppColors.primary,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                'Weather Conditions',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildWeatherItem(
                icon: Icons.thermostat_rounded,
                title: 'Temperature',
                value:
                    '${prediction.temperature.toStringAsFixed(1)}°C',
              ),
              const SizedBox(width: 10),
              _buildWeatherItem(
                icon: _getWeatherIcon(prediction.weather),
                title: 'Weather',
                value: prediction.weather.isEmpty
                    ? 'Unknown'
                    : prediction.weather,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildWeatherItem(
                icon: Icons.air_rounded,
                title: 'Wind',
                value:
                    '${prediction.windSpeed.toStringAsFixed(1)} km/h',
              ),
              const SizedBox(width: 10),
              _buildWeatherItem(
                icon: Icons.water_drop_outlined,
                title: 'Rain',
                value:
                    '${prediction.precipitation.toStringAsFixed(1)} mm',
              ),
            ],
          ),
          if (prediction.predictionReasons.isNotEmpty) ...[
            const SizedBox(height: 22),
            Row(
              children: [
                const Icon(
                  Icons.psychology_alt_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  'Why This Prediction?',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...prediction.predictionReasons.map(
              (reason) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Icon(
                        Icons.circle,
                        size: 7,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        reason,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.45,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(
                Icons.schedule_rounded,
                color: AppColors.secondary,
                size: 17,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Updated ${prediction.visitHour}'
                  '${prediction.dayName.isNotEmpty ? ' • ${prediction.dayName}' : ''}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Text(
                prediction.weatherSource,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
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
    final placeName = place.name;
    final placeCity = place.city;
    final placeCategory = place.category;
    final placeDescription = place.description;
    final recommendedAlternatives =
        crowdPrediction?.suggestedAlternatives ?? <String>[];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(placeName),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          await Future.wait([
            loadFavoriteStatus(),
            loadCrowdPrediction(),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Stack(
                  children: [
                    Image.asset(
                      _getPlaceImage(placeName),
                      width: double.infinity,
                      height: 250,
                      fit: BoxFit.cover,
                      errorBuilder: (
                        context,
                        error,
                        stackTrace,
                      ) {
                        return Container(
                          width: double.infinity,
                          height: 250,
                          color: AppColors.primary,
                          child: const Icon(
                            Icons.image_not_supported_rounded,
                            color: AppColors.white,
                            size: 55,
                          ),
                        );
                      },
                    ),
                    Container(
                      width: double.infinity,
                      height: 250,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.78),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 18,
                      left: 18,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(
                          placeCategory,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 22,
                      right: 22,
                      bottom: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            placeName,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 27,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_rounded,
                                color: Colors.white70,
                                size: 18,
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  '$placeCity • $placeCategory',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 15,
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
              const SizedBox(height: 28),
              _buildCrowdPredictionCard(),
              const SizedBox(height: 28),
              Text(
                'About This Place',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(23),
                  border: Border.all(
                    color: AppColors.border,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 15,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Text(
                  placeDescription,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.65,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (recommendedAlternatives.isNotEmpty) ...[
                const SizedBox(height: 26),
                Text(
                  'Lower-Crowd Alternatives',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 94,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: recommendedAlternatives.length,
                    separatorBuilder: (_, __) {
                      return const SizedBox(width: 10);
                    },
                    itemBuilder: (context, index) {
                      final nearbyName = recommendedAlternatives[index];

                      return Container(
                        width: 175,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: AppColors.border,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.shadow,
                              blurRadius: 12,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withValues(
                                  alpha: 0.14,
                                ),
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: const Icon(
                                Icons.place_rounded,
                                color: AppColors.secondary,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                nearbyName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 26),
              Text(
                'Smart Experiences',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 14),
              _ActionCard(
                icon: Icons.record_voice_over_rounded,
                title: 'Ask AI Voice Guide',
                subtitle: 'Ask historical and tourism questions',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VoiceGuideScreen(
                        initialPlaceId: _readPlaceId(place),
                        initialPlaceName: placeName,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 13),
              _ActionCard(
                icon: Icons.auto_awesome_rounded,
                title: 'AI Heritage Reconstruction',
                subtitle: 'Reconstruct the original appearance using AI',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'AI Heritage Reconstruction will be connected next.',
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 13),
              _ActionCard(
                icon: Icons.navigation_rounded,
                title: 'Open Navigation',
                subtitle: 'Open directions in Google Maps',
                onTap: () => _openNavigation(context),
              ),
              const SizedBox(height: 13),
              _ActionCard(
                icon: isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                title: isFavorite
                    ? 'Remove from Favorites'
                    : 'Add to Favorites',
                subtitle: isFavorite
                    ? 'Remove this place from favorites'
                    : 'Save this place for later',
                onTap: isUpdatingFavorite
                    ? () {}
                    : toggleFavorite,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CrowdPercentageRing extends StatelessWidget {
  final int percentage;
  final Color color;

  const _CrowdPercentageRing({
    required this.percentage,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final safePercentage = percentage.clamp(0, 100);

    return SizedBox(
      width: 116,
      height: 116,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 116,
            height: 116,
            child: CircularProgressIndicator(
              value: safePercentage / 100,
              strokeWidth: 10,
              strokeCap: StrokeCap.round,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(
                color,
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$safePercentage%',
                style: TextStyle(
                  color: color,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Estimated crowd',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppColors.border,
            ),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 14,
                offset: Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.secondary,
                size: 17,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
