import 'package:flutter/material.dart';

import '../models/profile.dart';
import '../services/profile_service.dart';

class ProfileListScreen extends StatefulWidget {
  const ProfileListScreen({super.key, this.service});

  final ProfileService? service;

  @override
  State<ProfileListScreen> createState() => _ProfileListScreenState();
}

class _ProfileListScreenState extends State<ProfileListScreen> {
  late final ProfileService _service;
  late Future<List<Profile>> _future;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? ProfileService();
    _future = _service.getProfiles();
  }

  void _refresh() {
    setState(() {
      _future = _service.getProfiles();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GroupMeMaybe')),
      body: FutureBuilder<List<Profile>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Unable to load profiles.'),
                  const SizedBox(height: 12),
                  FilledButton(onPressed: _refresh, child: const Text('Retry')),
                ],
              ),
            );
          }
          final profiles = snap.data ?? const <Profile>[];
          if (profiles.isEmpty) {
            return const Center(child: Text('No profiles yet.'));
          }
          return ListView.builder(
            itemCount: profiles.length,
            itemBuilder: (_, i) {
              final p = profiles[i];
              return ListTile(
                title: Text(p.name),
                subtitle: Text('${p.preferredRole} • ${p.skills.join(", ")}'),
              );
            },
          );
        },
      ),
    );
  }
}
