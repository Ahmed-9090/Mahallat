import 'dart:math';
import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';

class DistanceCalculator {
  static const double baseDeliveryFee = 1.0; // Base fee for first km
  static const double additionalKmFee = 0.15; // Fee per additional km

  /// Stream that listens to both store and user location changes
  static Stream<double> watchDeliveryFee({
    required String storeId,
    required String userId,
  }) {
    final storeStream = FirebaseFirestore.instance
        .collection('stores')
        .doc(storeId)
        .snapshots()
        .map((doc) => doc.data()?['storeLocation']);

    final userStream = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.data()?['userLocation']);

    return Rx.combineLatest2(
      storeStream,
      userStream,
      (storeLocation, userLocation) {
        if (storeLocation == null || userLocation == null) return 0.0;

        final storeLatLng = LatLng(
          storeLocation['latitude'],
          storeLocation['longitude'],
        );
        final userLatLng = LatLng(
          userLocation['latitude'],
          userLocation['longitude'],
        );

        final distance = calculateDistance(storeLatLng, userLatLng);
        return calculateDeliveryFee(distance);
      },
    );
  }

  /// Calculates the distance between two points in kilometers using the Haversine formula
  static double calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    
    // Convert latitude and longitude from degrees to radians
    final lat1 = _degreesToRadians(point1.latitude);
    final lon1 = _degreesToRadians(point1.longitude);
    final lat2 = _degreesToRadians(point2.latitude);
    final lon2 = _degreesToRadians(point2.longitude);

    print('Point 1: ${point1.latitude}, ${point1.longitude}');
    print('Point 2: ${point2.latitude}, ${point2.longitude}');

    // Haversine formula
    final dLat = lat2 - lat1;
    final dLon = lon2 - lon1;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    final distance = earthRadius * c;

    print('Calculated Distance: $distance km');
    return distance;
  }

  /// Calculates the delivery fee based on the distance
  /// First km costs 1 JOD, each additional km costs 0.15 JOD
  static double calculateDeliveryFee(double distanceInKm) {
    print('Calculating delivery fee for distance: $distanceInKm km');
    
    if (distanceInKm <= 0) {
      print('Distance is 0 or negative, returning base fee: $baseDeliveryFee');
      return baseDeliveryFee;
    }
    
    // Round up the distance to the nearest kilometer
    double roundedDistance = distanceInKm.ceilToDouble();
    print('Rounded distance: $roundedDistance km');
    
    if (roundedDistance <= 1) {
      print('Distance <= 1km, returning base fee: $baseDeliveryFee');
      return baseDeliveryFee;
    }

    final additionalKm = roundedDistance - 1;
    final additionalFee = additionalKm * additionalKmFee;
    final totalFee = baseDeliveryFee + additionalFee;
    
    print('Additional km: $additionalKm');
    print('Additional fee: $additionalFee');
    print('Total fee: $totalFee');
    
    // Round to 2 decimal places and ensure minimum fee
    final finalFee = double.parse(totalFee.toStringAsFixed(2));
    print('Final delivery fee: $finalFee');
    return finalFee;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }
} 