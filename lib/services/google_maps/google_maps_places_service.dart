import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../../google maps/models/autocomplete_model.dart';
import '../../google maps/models/place details/place_details_model/place_details_model.dart';

class GoogleMapsPlacesService {
  final String baseUrl = "https://maps.googleapis.com/maps/api/place";
  final String apiKey = "AIzaSyDPmT35b1IZKZ4knXxlx7Gc9TmpApfkoh4"; // Replace with a secure method to store API keys

  Future<List<AutocompleteModel>> getAutocomplete({required String input, required String sessionToken}) async {
    try {
      var response = await http.get(
        Uri.parse("$baseUrl/autocomplete/json?key=$apiKey&input=$input&sessiontoken=$sessionToken"),
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data['status'] == 'OK') {
          List<AutocompleteModel> places = [];
          for (var item in data['predictions']) {
            places.add(AutocompleteModel.fromJson(item));
          }
          return places;
        } else {
          throw Exception("API Error: ${data['status']} - ${data['error_message'] ?? 'No error message'}");
        }
      } else {
        throw Exception("Failed to load autocomplete: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Failed to fetch autocomplete suggestions: $e");
    }
  }

  Future<PlaceDetailsModel> getPlaceDetails({required String placeID}) async {
    final response = await http.get(Uri.parse('$baseUrl/details/json?&key=$apiKey&place_id=$placeID'));

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body)['result'];
      print("API Response: $data"); // Debugging: Log the API response
      return PlaceDetailsModel.fromJson(data);
    } else {
      throw Exception("Failed to fetch place details: ${response.statusCode}");
    }
  }

  Future<String> getAddressFromLatLng(LatLng latLng) async {
    try {
      final response = await http.get(
        Uri.parse('https://maps.googleapis.com/maps/api/geocode/json?latlng=${latLng.latitude},${latLng.longitude}&key=$apiKey'),
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data['status'] == 'OK') {
          // Extract the formatted address from the first result
          return data['results'][0]['formatted_address'];
        } else {
          throw Exception("API Error: ${data['status']} - ${data['error_message'] ?? 'No error message'}");
        }
      } else {
        throw Exception("Failed to fetch address: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Failed to fetch address: $e");
    }
  }
}