import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../services/auth_service.dart';
import '../services/tracking_service.dart';
import 'map_screen.dart';

class DashboardScreen extends StatefulWidget {
  final AppUser user;
  const DashboardScreen({super.key, required this.user});
  @override State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final TrackingService tracker;
  int tab = 0;

  @override
  void initState() {
    super.initState();
    tracker = TrackingService();
    if (widget.user.role == UserRole.fieldAgent) tracker.start(widget.user);
  }

  @override
  void dispose() { tracker.stop(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final admin = widget.user.role != UserRole.fieldAgent;
    return Scaffold(
      appBar: AppBar(
        title: Text(admin ? 'Live Tracking Dashboard' : 'Field Agent'),
        actions: [IconButton(onPressed: () => AuthService().signOut(), icon: const Icon(Icons.logout))],
      ),
      body: tab == 0 ? MapScreen(viewer: widget.user) : _Overview(user: widget.user),
      bottomNavigationBar: NavigationBar(selectedIndex: tab, onDestinationSelected: (i) => setState(() => tab = i), destinations: const [
        NavigationDestination(icon: Icon(Icons.map), label: 'Map'),
        NavigationDestination(icon: Icon(Icons.dashboard), label: 'Overview'),
      ]),
    );
  }
}

class _Overview extends StatelessWidget {
  final AppUser user;
  const _Overview({required this.user});
  @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(20), children: [
    Card(child: ListTile(leading: const Icon(Icons.person), title: Text(user.name), subtitle: Text(user.email), trailing: Text(roleToString(user.role)))),
    Card(child: ListTile(leading: const Icon(Icons.groups), title: const Text('Teams'), subtitle: Text(user.teamIds.isEmpty ? 'No teams assigned' : user.teamIds.join(', ')))),
    if (user.role == UserRole.fieldAgent) const Card(child: ListTile(leading: Icon(Icons.gps_fixed), title: Text('Background tracking'), subtitle: Text('Active while tracking is enabled.'))),
    if (user.role == UserRole.mainAdmin) const Card(child: ListTile(leading: Icon(Icons.admin_panel_settings), title: Text('Main Admin'), subtitle: Text('Full organizational access is enforced by Firestore rules.'))),
    if (user.role == UserRole.coAdmin) const Card(child: ListTile(leading: Icon(Icons.manage_accounts), title: Text('Co-Admin'), subtitle: Text('Administrative access is enforced by Firestore rules.'))),
  ]);
}
