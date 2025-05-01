class RoutesModel {
  final List<RouteData> routes;

  RoutesModel({required this.routes});

  factory RoutesModel.fromJson(Map<String, dynamic>? json) {
    if (json == null || json['routes'] == null) {
      return RoutesModel(routes: []);
    }

    return RoutesModel(
      routes: (json['routes'] as List)
          .map((route) => RouteData.fromJson(route))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'routes': routes.map((route) => route.toJson()).toList(),
    };
  }
}

class RouteData {
  final int distanceMeters;
  final String duration;
  final PolylineModel polyline;

  RouteData({
    required this.distanceMeters,
    required this.duration,
    required this.polyline,
  });

  factory RouteData.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return RouteData(
        distanceMeters: 0,
        duration: '',
        polyline: PolylineModel(encodedPolyline: ''),
      );
    }

    return RouteData(
      distanceMeters: json['distanceMeters'] ?? 0,
      duration: json['duration'] ?? '',
      polyline: PolylineModel.fromJson(json['polyline']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'distanceMeters': distanceMeters,
      'duration': duration,
      'polyline': polyline.toJson(),
    };
  }
}

class PolylineModel {
  final String encodedPolyline;

  PolylineModel({required this.encodedPolyline});

  factory PolylineModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return PolylineModel(encodedPolyline: '');
    }

    return PolylineModel(
      encodedPolyline: json['encodedPolyline'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'encodedPolyline': encodedPolyline,
    };
  }
}