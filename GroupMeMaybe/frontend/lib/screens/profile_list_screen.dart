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
  bool _isMutating = false;

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

  Future<void> _addSample() async {
    if (_isMutating) return;

    setState(() => _isMutating = true);
    try {
      await _service.createProfile(
        Profile(
          name: 'Test User',
          email: 'test${DateTime.now().millisecondsSinceEpoch}@mail.com',
          skills: ['Flutter', 'Laravel'],
          preferredRole: 'Programmer',
          availability: 'Weekends',
        ),
      );
      if (mounted) _refresh();
    } catch (_) {
      _showError('Could not add profile. Please try again.');
    } finally {
      if (mounted) setState(() => _isMutating = false);
    }
  }

  Future<void> _delete(Profile profile) async {
    if (_isMutating || profile.id == null) return;

    setState(() => _isMutating = true);
    try {
      await _service.deleteProfile(profile.id!);
      if (mounted) _refresh();
    } catch (_) {
      _showError('Could not delete profile. Please try again.');
    } finally {
      if (mounted) setState(() => _isMutating = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GroupMeMaybe')),
      floatingActionButton: FloatingActionButton(
        onPressed: _isMutating ? null : _addSample,
        child: _isMutating
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.add),
      ),
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
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: _isMutating ? null : () => _delete(p),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
