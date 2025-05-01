import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'dart:math';

class DistanceCalculator {
  static double calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    
    double lat1 = point1.latitude * (pi / 180);
    double lat2 = point2.latitude * (pi / 180);
    double lon1 = point1.longitude * (pi / 180);
    double lon2 = point2.longitude * (pi / 180);
    
    double dLat = lat2 - lat1;
    double dLon = lon2 - lon1;
    
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }

  static double calculateDeliveryFee(double distanceInKm) {
    const double baseFee = 1.0; // Base delivery fee for first km in JOD
    const double additionalFeePerKm = 0.15; // Additional fee per km in JOD
    
    // Round up the distance to the nearest kilometer
    double roundedDistance = distanceInKm.ceilToDouble();
    
    if (roundedDistance <= 1) {
      return baseFee;
    } else {
      double additionalDistance = roundedDistance - 1;
      double totalFee = baseFee + (additionalDistance * additionalFeePerKm);
      // Round to 2 decimal places
      return double.parse(totalFee.toStringAsFixed(2));
    }
  }

  static Stream<double> watchDeliveryFee(LatLng storeLocation, LatLng userLocation) {
    return Stream.value(calculateDeliveryFee(calculateDistance(storeLocation, userLocation)));
  }
} 