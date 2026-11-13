import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models.dart';
import '../../services/app_state.dart';
import '../../services/firestore_service.dart';

/// Administrators verify service providers before they can accept requests.
///
/// To make an admin: create a normal account, then set `role` to `admin` on
/// its document in the Firestore console (see README).
class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fs = context.read<FirestoreService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Provider verification'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AppState>().signOut(),
          ),
        ],
      ),
      body: StreamBuilder<List<AppUser>>(
        stream: fs.unverifiedProviders(),
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text('${snap.error}'));
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final providers = snap.data!;
          if (providers.isEmpty) {
            return const Center(child: Text('No providers waiting.'));
          }
          return ListView.separated(
            itemCount: providers.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final p = providers[i];
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.build)),
                title: Text(p.name),
                subtitle: Text('${p.email}\n${p.phone}'),
                isThreeLine: true,
                trailing: FilledButton(
                  onPressed: () => fs.setVerified(p.uid, true),
                  child: const Text('Verify'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
