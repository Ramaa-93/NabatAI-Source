import 'package:dio/dio.dart';

import '../models/crowd_prediction.dart';
import '../models/place.dart';

class ApiService {
  late final Dio _dio;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        // للأندرويد Emulator
        //baseUrl: 'http://10.0.2.2:8000',
        //baseUrl: 'http://192.168.100.248:8000',     
        //mama
       baseUrl: 'http://192.168.100.246:8000',
          connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),

        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );
  }

  Future<CrowdPrediction> getCrowdPrediction(
    int placeId,
  ) async {
    try {
      final Response<dynamic> response = await _dio.get(
        '/crowd/predict/$placeId',
      );

      if (response.statusCode == 200 &&
          response.data is Map) {
        final Map<String, dynamic> json =
            Map<String, dynamic>.from(
          response.data as Map,
        );

        return CrowdPrediction.fromJson(json);
      }

      throw Exception(
        'Invalid crowd prediction response.',
      );
    } on DioException catch (error) {
      final dynamic responseData =
          error.response?.data;

      String message =
          'Could not connect to the crowd prediction service.';

      if (responseData is Map &&
          responseData['detail'] != null) {
        message = responseData['detail'].toString();
      } else if (error.type ==
          DioExceptionType.connectionTimeout) {
        message =
            'Connection timed out. Make sure the backend is running.';
      } else if (error.type ==
          DioExceptionType.connectionError) {
        message =
            'Could not connect to the backend server.';
      }

      throw Exception(message);
    } catch (error) {
      throw Exception(
        'Crowd prediction error: $error',
      );
    }
  }

  Future<List<Place>> getPlaces() async {
    try {
      final Response<dynamic> response =
          await _dio.get('/places/');

      if (response.statusCode == 200 &&
          response.data is List) {
        final List<dynamic> data =
            response.data as List<dynamic>;

        return data
            .map(
              (item) => Place.fromJson(
                Map<String, dynamic>.from(
                  item as Map,
                ),
              ),
            )
            .toList();
      }

      throw Exception(
        'Invalid places response.',
      );
    } on DioException catch (error) {
      final dynamic responseData =
          error.response?.data;

      String message =
          'Could not load places.';

      if (responseData is Map &&
          responseData['detail'] != null) {
        message = responseData['detail'].toString();
      }

      throw Exception(message);
    } catch (error) {
      throw Exception(
        'Places loading error: $error',
      );
    }
  }
}