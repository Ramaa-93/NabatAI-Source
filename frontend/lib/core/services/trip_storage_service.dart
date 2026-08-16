import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class TripStorageService {
  static const String savedTripsKey = "saved_trips";

  static Future<void> saveTrip(Map<String, dynamic> trip) async {
    final prefs = await SharedPreferences.getInstance();

    final List<String> trips =
        prefs.getStringList(savedTripsKey) ?? [];

    trips.add(jsonEncode(trip));

    await prefs.setStringList(savedTripsKey, trips);
  }

  static Future<List<Map<String, dynamic>>> getTrips() async {
    final prefs = await SharedPreferences.getInstance();

    final List<String> trips =
        prefs.getStringList(savedTripsKey) ?? [];

    return trips
        .map(
          (e) => Map<String, dynamic>.from(
            jsonDecode(e),
          ),
        )
        .toList();
  }

  static Future<void> deleteTrip(int index) async {
    final prefs = await SharedPreferences.getInstance();

    final List<String> trips =
        prefs.getStringList(savedTripsKey) ?? [];

    if (index >= 0 && index < trips.length) {
      trips.removeAt(index);
      await prefs.setStringList(savedTripsKey, trips);
    }
  }

  static Future<void> clearTrips() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(savedTripsKey);
  }
}