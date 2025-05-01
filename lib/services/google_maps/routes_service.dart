import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../google maps/models/routes models/Locationinfomodel.dart';
import '../../google maps/models/routes_model.dart';

class RoutesService {
  final String baseUrl = "https://routes.googleapis.com/directions/v2:computeRoutes";
  late final String apiKey;

  RoutesService() {
    apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      throw Exception('Google Maps API key not found in environment variables');
    }
  }

  Future<RoutesModel> fetchRoutes({required Locationinfomodel origin, required Locationinfomodel destination}) async {
    Uri url = Uri.parse(baseUrl);

    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'X-Goog-Api-Key': apiKey,
      'X-Goog-FieldMask': 'routes.duration,routes.distanceMeters,routes.polyline.encodedPolyline'
    };

    Map<String, dynamic> body = {
      "origin": origin.toJson(),
      "destination": destination.toJson(),
      "travelMode": "DRIVE",
      "routingPreference": "TRAFFIC_AWARE",
      "computeAlternativeRoutes": false,
      "routeModifiers": {
        "avoidTolls": false,
        "avoidHighways": false,
        "avoidFerries": false
      },
      "languageCode": "en-US",
      "units": "IMPERIAL"
    };


    try {
      var response = await http.post(url, headers: headers, body: jsonEncode(body));

      // Log the API response for debugging
      print("Directions API Response Status Code: ${response.statusCode}");
      print("Directions API Response Body: ${response.body}");

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);

        // Check if the response contains valid data
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          return RoutesModel.fromJson(data);
        } else {
          throw Exception("Invalid response data: No routes found.");
        }
      } else {
        throw Exception("Error fetching routes: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      throw Exception("Failed to fetch routes: $e");
    }
  }
}