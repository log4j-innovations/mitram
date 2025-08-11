import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:mitram/services/location_service.dart'; // Import LocationService and UserLocation

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final LocationService _locationService = LocationService(); // Instantiate LocationService

  String? get userId => _auth.currentUser?.uid;

  // Save user location
  Future<void> saveUserLocation() async { // No longer needs parameters
    try {
      // Request location permission
      bool permissionGranted = await _locationService.requestLocationPermission();
      if (!permissionGranted) {
        debugPrint('Location permission not granted. Cannot save location.');
        return;
      }

      // Get current location
      final UserLocation? location = await _locationService.getCurrentLocation();
      if (location == null) {
        debugPrint('Could not get current location. Cannot save location.');
        return;
      }

      // Create anonymous user if not authenticated
      if (userId == null) {
        await _auth.signInAnonymously();
      }

      if (userId == null) return;

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('locations')
          .add(location.toJson());

      // Also update the user's current location
      await _firestore.collection('users').doc(userId).set({
        'currentLocation': location.toJson(),
        'lastLocationUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Failed to save location: $e');
    }
  }


  // Get user's current location
  Future<UserLocation?> getCurrentLocation() async {
    if (userId == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      final data = doc.data();
      
      if (data != null && data['currentLocation'] != null) {
        return UserLocation.fromJson(data['currentLocation']);
      }
      return null;
    } catch (e) {
      debugPrint('Failed to get current location: $e');
      return null;
    }
  }


  // Initialize user profile
  Future<void> initializeUserProfile() async {
    try {
      // Create anonymous user if not authenticated
      if (userId == null) {
        await _auth.signInAnonymously();
      }

      if (userId == null) return;

      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (!userDoc.exists) {
        await _firestore.collection('users').doc(userId).set({
          'createdAt': FieldValue.serverTimestamp(),
          'totalDiagnoses': 0,
          'isLocationPermissionGranted': false,
        });
      }
    } catch (e) {
      debugPrint('Failed to initialize user profile: $e');
    }
  }

}
