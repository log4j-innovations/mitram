import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/diagnosis_model.dart';
import '../models/stored_diagnosis.dart';
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

  // Save diagnosis result
  Future<void> saveDiagnosis(DiagnosisResult diagnosis) async {
    try {
      // Create anonymous user if not authenticated
      if (userId == null) {
        await _auth.signInAnonymously();
      }

      if (userId == null) return;

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('diagnoses')
          .add(diagnosis.toJson());

      // Update user stats
      await _updateUserStats();
    } catch (e) {
      debugPrint('Failed to save diagnosis: $e');
    }
  }

  // Get user's diagnosis history
  Future<List<DiagnosisResult>> getDiagnosisHistory() async {
    if (userId == null) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('diagnoses')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      return snapshot.docs
          .map((doc) => DiagnosisResult.fromJson(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Failed to get diagnosis history: $e');
      return [];
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

  // Update user statistics
  Future<void> _updateUserStats() async {
    if (userId == null) return;

    try {
      await _firestore.collection('users').doc(userId).update({
        'totalDiagnoses': FieldValue.increment(1),
        'lastDiagnosisDate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Failed to update user stats: $e');
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

  Future<void> saveStoredDiagnosis(StoredDiagnosis diagnosis) async {
    try {
      // Ensure user is authenticated (or create anonymous user)
      if (_auth.currentUser == null) {
        await _auth.signInAnonymously();
      }
      final userId = _auth.currentUser!.uid;

      // Save to Firestore, under user's collection
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('diagnoses')
          .doc(diagnosis.diagnosisId)
          .set(diagnosis.toJson());

    } catch (e) {
      // Use a logging framework in production
      debugPrint('Failed to save stored diagnosis: $e');
    }
  }
}
