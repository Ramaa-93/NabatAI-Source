class CrowdPrediction {
  final int placeId;
  final String placeName;
  final String city;

  final int crowdPercentage;
  final String crowdLevel;
  final String crowdLevelArabic;

  final String message;
  final String messageArabic;

  final int? activeUsers;
  final int estimatedCapacity;
  final double? occupancyPercentage;

  final double temperature;
  final double apparentTemperature;
  final String weather;
  final double precipitation;
  final double windSpeed;

  final String visitHour;
  final String dayName;
  final bool isWeekend;
  final String weatherSource;

  final List<String> predictionReasons;
  final List<String> suggestedAlternatives;

  final String lastUpdated;

  CrowdPrediction({
    required this.placeId,
    required this.placeName,
    required this.city,
    required this.crowdPercentage,
    required this.crowdLevel,
    required this.crowdLevelArabic,
    required this.message,
    required this.messageArabic,
    required this.activeUsers,
    required this.estimatedCapacity,
    required this.occupancyPercentage,
    required this.temperature,
    required this.apparentTemperature,
    required this.weather,
    required this.precipitation,
    required this.windSpeed,
    required this.visitHour,
    required this.dayName,
    required this.isWeekend,
    required this.weatherSource,
    required this.predictionReasons,
    required this.suggestedAlternatives,
    required this.lastUpdated,
  });

  factory CrowdPrediction.fromJson(Map<String, dynamic> json) {
    // الـ Backend يرجع البيانات داخل prediction
    final Map<String, dynamic> prediction =
        json["prediction"] is Map<String, dynamic>
            ? json["prediction"] as Map<String, dynamic>
            : json;

    final List<String> reasons =
        prediction["prediction_reasons"] is List
            ? List<String>.from(
                prediction["prediction_reasons"].map(
                  (item) => item.toString(),
                ),
              )
            : <String>[];

    List<String> alternatives = <String>[];

    if (json["suggested_alternatives"] is List) {
      alternatives = List<String>.from(
        json["suggested_alternatives"].map(
          (item) => item.toString(),
        ),
      );
    } else if (prediction["suggested_alternatives"] is List) {
      alternatives = List<String>.from(
        prediction["suggested_alternatives"].map(
          (item) => item.toString(),
        ),
      );
    }

    return CrowdPrediction(
      placeId: _toInt(prediction["place_id"]),
      placeName: prediction["place_name"]?.toString() ?? "",
      city: prediction["city"]?.toString() ?? "",

      crowdPercentage: _toInt(
        prediction["crowd_percentage"],
      ),

      crowdLevel: prediction["crowd_level"]?.toString() ?? "",
      crowdLevelArabic:
          prediction["crowd_level_ar"]?.toString() ?? "",

      message: prediction["message"]?.toString() ?? "",
      messageArabic:
          prediction["message_ar"]?.toString() ?? "",

      activeUsers:
          prediction["active_users"] == null
              ? null
              : _toInt(prediction["active_users"]),

      estimatedCapacity: _toInt(
        prediction["estimated_capacity"],
      ),

      occupancyPercentage:
          prediction["occupancy_percentage"] == null
              ? null
              : _toDouble(
                  prediction["occupancy_percentage"],
                ),

      temperature: _toDouble(
        prediction["temperature"],
      ),

      apparentTemperature: _toDouble(
        prediction["apparent_temperature"],
      ),

      weather: prediction["weather"]?.toString() ?? "",

      precipitation: _toDouble(
        prediction["precipitation"],
      ),

      windSpeed: _toDouble(
        prediction["wind_speed"],
      ),

      visitHour:
          prediction["visit_hour"]?.toString() ?? "",

      dayName:
          prediction["day_name"]?.toString() ?? "",

      isWeekend:
          prediction["is_weekend"] == true,

      weatherSource:
          prediction["weather_source"]?.toString() ?? "",

      predictionReasons: reasons,
      suggestedAlternatives: alternatives,

      lastUpdated:
          prediction["last_updated"]?.toString() ?? "",
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.round();
    }

    return int.tryParse(value?.toString() ?? "") ?? 0;
  }

  static double _toDouble(dynamic value) {
    if (value is double) {
      return value;
    }

    if (value is int) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? "",
        ) ??
        0.0;
  }
}