import 'package:location/location.dart';

class LocationService {
  Location location = Location();

  Future<void> checkAndRequestLocationService() async {

    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
    }
    if (!serviceEnabled) {
     throw LocationServiceException();
    }
  }

  Future<void> checkAndRequestLocationPermission() async {
    var permission = await location.hasPermission();

    if (permission == PermissionStatus.deniedForever) {
      throw LocationPermissionException();
    }

    if (permission == PermissionStatus.denied) {
      permission = await location.requestPermission();
     if (permission != PermissionStatus.granted) {
       throw LocationPermissionException();
     }
    }

  }

  void getRealtimeLocation(void Function(LocationData)? onData)async {
    await checkAndRequestLocationService();
    await checkAndRequestLocationPermission();
    location.onLocationChanged.listen(onData);
  }
  Future<LocationData?> getLocation() async {
    await checkAndRequestLocationService();
    await checkAndRequestLocationPermission();
    return await location.getLocation();
  }
}

class LocationServiceException implements Exception {}

class LocationPermissionException implements Exception {}