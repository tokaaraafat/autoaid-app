import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/models.dart';
import '../../services/app_state.dart';
import '../../services/firestore_service.dart';
import '../../services/location_service.dart';
import '../shared/profile_screen.dart';
import '../shared/request_detail_screen.dart';

class ProviderHome extends StatefulWidget {
  const ProviderHome({super.key});

  @override
  State<ProviderHome> createState() => _ProviderHomeState();
}

class _ProviderHomeState extends State<ProviderHome> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AppState>().profile!;
    const titles = ['Nearby requests', 'My jobs', 'Profile'];
    final pages = [
      const _NearbyTab(),
      const _JobsTab(),
      const ProfileScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_index]),
        actions: [
          if (_index == 0)
            Row(
              children: [
                Text(me.available ? 'Available' : 'Offline'),
                Switch(
                  value: me.available,
                  onChanged: (v) => context.read<AppState>().setAvailability(v),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          if (!me.verified)
            const MaterialBanner(
              content: Text(
                  'Your account is waiting for administrator verification. '
                  'You can browse requests but not accept them yet.'),
              leading: Icon(Icons.hourglass_top),
              actions: [SizedBox.shrink()],
            ),
          Expanded(child: pages[_index]),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.radar), label: 'Nearby'),
          NavigationDestination(icon: Icon(Icons.work), label: 'My jobs'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

/// Pending requests within [maxRequestRadiusKm] of the provider, nearest first.
class _NearbyTab extends StatefulWidget {
  const _NearbyTab();

  @override
  State<_NearbyTab> createState() => _NearbyTabState();
}

class _NearbyTabState extends State<_NearbyTab> {
  LatLng? _myLocation;
  bool _locating = true;

  @override
  void initState() {
    super.initState();
    _locate();
  }

  Future<void> _locate() async {
    setState(() => _locating = true);
    final p = await LocationService.current();
    if (!mounted) return;
    setState(() {
      _myLocation = p;
      _locating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_locating) return const Center(child: CircularProgressIndicator());

    final mine = _myLocation;
    if (mine == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('We need your location to show nearby requests.'),
            const SizedBox(height: 12),
            FilledButton(onPressed: _locate, child: const Text('Try again')),
          ],
        ),
      );
    }

    return StreamBuilder<List<AssistanceRequest>>(
      stream: context.read<FirestoreService>().pendingRequests(),
      builder: (context, snap) {
        if (snap.hasError) return Center(child: Text('${snap.error}'));
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final items = snap.data!
            .map((r) =>
                (r, LocationService.distanceKm(mine, r.location)))
            .where((e) => e.$2 <= maxRequestRadiusKm)
            .toList()
          ..sort((a, b) => a.$2.compareTo(b.$2));

        if (items.isEmpty) {
          return RefreshIndicator(
            onRefresh: _locate,
            child: ListView(
              children: const [
                SizedBox(height: 120),
                Center(child: Text('No open requests near you right now.')),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _locate,
          child: ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final (r, km) = items[i];
              final type = serviceTypeById(r.type);
              return ListTile(
                leading: Icon(type.icon,
                    color: r.severity == 'high' ? Colors.red : null),
                title: Text('${type.label} - ${km.toStringAsFixed(1)} km away'),
                subtitle: Text(r.description,
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                trailing: Text(r.price == 0 ? '-' : '${r.price} $currency'),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => RequestDetailScreen(
                            requestId: r.id, asProvider: true))),
              );
            },
          ),
        );
      },
    );
  }
}

class _JobsTab extends StatelessWidget {
  const _JobsTab();

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AppState>().profile!.uid;
    return StreamBuilder<List<AssistanceRequest>>(
      stream: context.read<FirestoreService>().providerJobs(uid),
      builder: (context, snap) {
        if (snap.hasError) return Center(child: Text('${snap.error}'));
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final jobs = snap.data!;
        if (jobs.isEmpty) {
          return const Center(child: Text('You have no jobs yet.'));
        }
        return ListView.separated(
          itemCount: jobs.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final r = jobs[i];
            final type = serviceTypeById(r.type);
            return ListTile(
              leading: Icon(type.icon),
              title: Text('${type.label} - ${r.customerName}'),
              subtitle: Text(DateFormat.yMMMd().add_jm().format(r.createdAt)),
              trailing: Chip(
                label: Text(r.status.name,
                    style: const TextStyle(color: Colors.white, fontSize: 12)),
                backgroundColor: r.status.color,
                visualDensity: VisualDensity.compact,
              ),
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => RequestDetailScreen(
                          requestId: r.id, asProvider: true))),
            );
          },
        );
      },
    );
  }
}
