import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/place.dart';
import '../../services/favorites_service.dart';
import '../places/place_details_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  bool isLoading = true;
  List<Place> favorites = [];

  @override
  void initState() {
    super.initState();
    loadFavorites();
  }

  Future<void> loadFavorites() async {
    final savedPlaces = await FavoritesService.getFavorites();

    if (!mounted) return;

    setState(() {
      favorites = savedPlaces;
      isLoading = false;
    });
  }

  Future<void> removeFavorite(Place place) async {
    await FavoritesService.removeFavorite(place.id);
    await loadFavorites();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${place.name} removed from favorites.',
        ),
      ),
    );
  }

  String getPlaceImage(String name) {
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
          'Favorites',
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
          : favorites.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(30),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.favorite_border_rounded,
                          size: 72,
                          color: AppColors.brown,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No favorite places yet',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkBrown,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Open a place and tap Add to Favorites.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: loadFavorites,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(18),
                    itemCount: favorites.length,
                    itemBuilder: (context, index) {
                      final place = favorites[index];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Material(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(24),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PlaceDetailsScreen(
                                    place: place,
                                  ),
                                ),
                              );

                              await loadFavorites();
                            },
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(18),
                                    child: Image.asset(
                                      getPlaceImage(place.name),
                                      width: 76,
                                      height: 76,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          place.name,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.darkBrown,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          '${place.city} • ${place.category}',
                                          style: const TextStyle(
                                            color: Colors.black54,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      removeFavorite(place);
                                    },
                                    icon: const Icon(
                                      Icons.favorite_rounded,
                                      color: Colors.red,
                                    ),
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