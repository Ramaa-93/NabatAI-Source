import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/place.dart';
import 'api_service.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

final placesProvider = FutureProvider<List<Place>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.getPlaces();
});