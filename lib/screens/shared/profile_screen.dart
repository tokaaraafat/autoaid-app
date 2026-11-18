import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/models.dart';
import '../../services/app_state.dart';

/// Used as a tab (no Scaffold of its own).
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final p = state.profile;
    if (p == null) return const SizedBox.shrink();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 12),
        CircleAvatar(
          radius: 40,
          child: Text(p.name.isEmpty ? '?' : p.name[0].toUpperCase(),
              style: const TextStyle(fontSize: 32)),
        ),
        const SizedBox(height: 12),
        Center(
            child: Text(p.name,
                style: Theme.of(context).textTheme.titleLarge)),
        Center(child: Text(p.role.name)),
        const SizedBox(height: 16),
        ListTile(
            leading: const Icon(Icons.email), title: Text(p.email)),
        ListTile(
            leading: const Icon(Icons.phone), title: Text(p.phone)),
        if (p.role == UserRole.provider) ...[
          ListTile(
            leading: const Icon(Icons.star, color: Colors.amber),
            title: Text(p.ratingCount == 0
                ? 'No ratings yet'
                : '${p.rating.toStringAsFixed(1)} (${p.ratingCount} ratings)'),
          ),
          ListTile(
            leading: Icon(p.verified ? Icons.verified : Icons.hourglass_top,
                color: p.verified ? Colors.green : Colors.orange),
            title: Text(p.verified
                ? 'Verified provider'
                : 'Waiting for admin verification'),
          ),
        ],
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => state.signOut(),
          icon: const Icon(Icons.logout),
          label: const Text('Sign out'),
        ),
      ],
    );
  }
}
