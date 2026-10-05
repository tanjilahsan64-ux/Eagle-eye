import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { mainAdmin, coAdmin, fieldAgent }

UserRole roleFromString(String value) {
  switch (value) {
    case 'mainAdmin': return UserRole.mainAdmin;
    case 'coAdmin': return UserRole.coAdmin;
    default: return UserRole.fieldAgent;
  }
}

String roleToString(UserRole role) => switch (role) {
  UserRole.mainAdmin => 'mainAdmin',
  UserRole.coAdmin => 'coAdmin',
  UserRole.fieldAgent => 'fieldAgent',
};

class AppUser {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final List<String> teamIds;
  final bool trackingEnabled;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.teamIds,
    required this.trackingEnabled,
  });

  factory AppUser.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snap) {
    final d = snap.data() ?? {};
    return AppUser(
      id: snap.id,
      name: (d['name'] ?? '') as String,
      email: (d['email'] ?? '') as String,
      role: roleFromString((d['role'] ?? 'fieldAgent') as String),
      teamIds: List<String>.from(d['teamIds'] ?? const <String>[]),
      trackingEnabled: (d['trackingEnabled'] ?? true) as bool,
    );
  }
}

class AgentPosition {
  final String userId;
  final String name;
  final String teamId;
  final double latitude;
  final double longitude;
  final double accuracy;
  final double speed;
  final DateTime timestamp;
  final String status;
  final String? stopId;

  const AgentPosition({
    required this.userId,
    required this.name,
    required this.teamId,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.speed,
    required this.timestamp,
    required this.status,
    this.stopId,
  });

  factory AgentPosition.fromMap(String id, Map<String, dynamic> d) {
    final ts = d['timestamp'];
    return AgentPosition(
      userId: id,
      name: (d['name'] ?? 'Agent') as String,
      teamId: (d['teamId'] ?? '') as String,
      latitude: (d['latitude'] ?? 0).toDouble(),
      longitude: (d['longitude'] ?? 0).toDouble(),
      accuracy: (d['accuracy'] ?? 0).toDouble(),
      speed: (d['speed'] ?? 0).toDouble(),
      timestamp: ts is Timestamp ? ts.toDate() : DateTime.now(),
      status: (d['status'] ?? 'moving') as String,
      stopId: d['stopId'] as String?,
    );
  }
}
