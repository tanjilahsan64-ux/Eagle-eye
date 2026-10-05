import 'dart:async';
import 'dart:math' as math;
import 'package:background_location/background_location.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_models.dart';

class TrackingService {
  static const stopThreshold = Duration(minutes: 5);
  static const double stopRadiusMeters = 50;
  static const double movingSpeedMetersPerSecond = 2.0;
  static const double maxUsableAccuracyMeters = 100;

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  StreamSubscription? _authSub;
  AppUser? _profile;
  String? _activeStopId;
  DateTime? _stationarySince;
  double? _anchorLat;
  double? _anchorLng;
  bool _started = false;

  Future<void> start(AppUser profile) async {
    if (_started) return;
    _profile = profile;
    if (!profile.trackingEnabled || profile.role != UserRole.fieldAgent) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tracking_enabled', true);

    await BackgroundLocation.stopLocationService();
    await BackgroundLocation.setAndroidNotification(
      title: 'Field tracking active',
      message: 'Your location is being shared with your organization.',
      icon: '@mipmap/ic_launcher',
    );
    await BackgroundLocation.setAndroidConfiguration(15000);
    await BackgroundLocation.startLocationService(distanceFilter: 20);
    BackgroundLocation.getLocationUpdates(_onLocation);
    _started = true;
  }

  Future<void> stop() async {
    await BackgroundLocation.stopLocationService();
    _started = false;
  }

  Future<void> _onLocation(Location location) async {
    final profile = _profile;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (profile == null || uid == null || !profile.trackingEnabled) return;

    final lat = location.latitude;
    final lng = location.longitude;
    final accuracy = location.accuracy;
    final speed = location.speed;
    if (lat == null || lng == null) return;

    final now = DateTime.now();
    final goodAccuracy = accuracy == null || accuracy <= maxUsableAccuracyMeters;
    final isStationary = goodAccuracy && (speed ?? 0) <= movingSpeedMetersPerSecond;

    if (isStationary) {
      _anchorLat ??= lat;
      _anchorLng ??= lng;
      final distanceFromAnchor = _distanceMeters(_anchorLat!, _anchorLng!, lat, lng);
      if (distanceFromAnchor <= stopRadiusMeters) {
        _stationarySince ??= now;
      } else {
        _anchorLat = lat;
        _anchorLng = lng;
        _stationarySince = now;
        _activeStopId = null;
      }
    } else {
      _stationarySince = null;
      _anchorLat = lat;
      _anchorLng = lng;
      _activeStopId = null;
    }

    var status = 'moving';
    String? stopId;
    if (_stationarySince != null && now.difference(_stationarySince!) >= stopThreshold) {
      status = 'stopped';
      _activeStopId ??= '${uid}_${_stationarySince!.millisecondsSinceEpoch}';
      stopId = _activeStopId;
      await _writeStop(uid, profile, lat, lng, accuracy ?? 0, _stationarySince!, now);
    } else if (isStationary) {
      status = 'idle';
    }

    final position = {
      'userId': uid,
      'name': profile.name,
      'teamId': profile.teamIds.isEmpty ? 'unassigned' : profile.teamIds.first,
      'latitude': lat,
      'longitude': lng,
      'accuracy': accuracy ?? 0,
      'speed': speed ?? 0,
      'timestamp': FieldValue.serverTimestamp(),
      'status': status,
      'stopId': stopId,
    };
    await _db.collection('livePositions').doc(uid).set(position, SetOptions(merge: true));
  }

  Future<void> _writeStop(
    String uid,
    AppUser profile,
    double lat,
    double lng,
    double accuracy,
    DateTime started,
    DateTime lastSeen,
  ) async {
    final stopId = _activeStopId!;
    await _db.collection('users').doc(uid).collection('stops').doc(stopId).set({
      'userId': uid,
      'name': profile.name,
      'teamId': profile.teamIds.isEmpty ? 'unassigned' : profile.teamIds.first,
      'latitude': lat,
      'longitude': lng,
      'accuracy': accuracy,
      'startedAt': Timestamp.fromDate(started),
      'lastSeenAt': Timestamp.fromDate(lastSeen),
      'durationSeconds': lastSeen.difference(started).inSeconds,
      'status': 'active',
    }, SetOptions(merge: true));
  }

  double _distanceMeters(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371000.0;
    final p1 = lat1 * math.pi / 180;
    final p2 = lat2 * math.pi / 180;
    final dp = (lat2 - lat1) * math.pi / 180;
    final dl = (lon2 - lon1) * math.pi / 180;
    final a = math.sin(dp / 2) * math.sin(dp / 2) +
        math.cos(p1) * math.cos(p2) * math.sin(dl / 2) * math.sin(dl / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }
}
