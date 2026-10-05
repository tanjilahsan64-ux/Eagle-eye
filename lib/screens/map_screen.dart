import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/app_models.dart';

class MapScreen extends StatefulWidget {
  final AppUser viewer;
  const MapScreen({super.key, required this.viewer});
  @override State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  StreamSubscription? _sub;
  final Map<String, AgentPosition> _agents = {};

  @override
  void initState() { super.initState(); _listen(); }

  void _listen() {
    final q = FirebaseFirestore.instance.collection('livePositions');
    _sub = q.snapshots().listen((snapshot) {
      final next = <String, AgentPosition>{};
      for (final d in snapshot.docs) {
        final p = AgentPosition.fromMap(d.id, d.data());
        if (widget.viewer.role == UserRole.fieldAgent && !widget.viewer.teamIds.contains(p.teamId)) continue;
        next[d.id] = p;
      }
      if (mounted) setState(() { _agents..clear()..addAll(next); });
    });
  }

  @override void dispose() { _sub?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final points = _agents.values.toList();
    final center = points.isNotEmpty ? LatLng(points.first.latitude, points.first.longitude) : const LatLng(23.8103, 90.4125);
    return FlutterMap(
      options: MapOptions(initialCenter: center, initialZoom: 12),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.field_tracker',
        ),
        MarkerLayer(markers: points.map((p) => Marker(
          point: LatLng(p.latitude, p.longitude), width: 54, height: 68,
          child: GestureDetector(
            onTap: () => showModalBottomSheet(context: context, builder: (_) => _AgentSheet(position: p)),
            child: Column(children: [
              Icon(Icons.location_pin, size: 42, color: p.status == 'stopped' ? Colors.orange : Colors.blue),
              Flexible(child: Text(p.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11))),
            ]),
          ),
        )).toList()),
        RichAttributionWidget(attributions: [TextSourceAttribution('OpenStreetMap contributors')]),
      ],
    );
  }
}

class _AgentSheet extends StatelessWidget {
  final AgentPosition position;
  const _AgentSheet({required this.position});
  @override Widget build(BuildContext context) => SafeArea(child: Padding(
    padding: const EdgeInsets.all(20),
    child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(position.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      Text('Team: ${position.teamId}'),
      Text('Status: ${position.status}'),
      Text('Accuracy: ${position.accuracy.toStringAsFixed(0)} m'),
      Text('Speed: ${(position.speed * 3.6).toStringAsFixed(1)} km/h'),
      Text('Updated: ${position.timestamp.toLocal()}'),
    ]),
  ));
}
