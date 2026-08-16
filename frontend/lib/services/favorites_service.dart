import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/place.dart';

class FavoritesService {
  static const String _key = 'favorite_places';

  static Future<List<Place>> getFavorites() async {
    final preferences = await SharedPreferences.getInstance();
    final savedItems = preferences.getStringList(_key) ?? [];

    return savedItems.map((item) {
      final json = jsonDecode(item) as Map<String, dynamic>;
      return Place.fromJson(json);
    }).toList();
  }

  static Future<bool> isFavorite(int placeId) async {
    final favorites = await getFavorites();

    return favorites.any(
      (place) => place.id == placeId,
    );
  }

  static Future<void> addFavorite(Place place) async {
    final preferences = await SharedPreferences.getInstance();
    final favorites = await getFavorites();

    final alreadyExists = favorites.any(
      (item) => item.id == place.id,
    );

    if (alreadyExists) return;

    favorites.add(place);

    final encodedItems = favorites.map((item) {
      return jsonEncode(item.toJson());
    }).toList();

    await preferences.setStringList(
      _key,
      encodedItems,
    );
  }

  static Future<void> removeFavorite(int placeId) async {
    final preferences = await SharedPreferences.getInstance();
    final favorites = await getFavorites();

    favorites.removeWhere(
      (place) => place.id == placeId,
    );

    final encodedItems = favorites.map((item) {
      return jsonEncode(item.toJson());
    }).toList();

    await preferences.setStringList(
      _key,
      encodedItems,
    );
  }

  static Future<void> toggleFavorite(Place place) async {
    final favorite = await isFavorite(place.id);

    if (favorite) {
      await removeFavorite(place.id);
    } else {
      await addFavorite(place);
    }
  }
}