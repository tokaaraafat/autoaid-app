import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/models.dart';
import '../../services/app_state.dart';
import '../../services/firestore_service.dart';
import '../shared/profile_screen.dart';
import '../shared/request_detail_screen.dart';
import 'car_care_screen.dart';
import 'emergency_screen.dart';
import 'request_form_screen.dart';
import 'vehicles_screen.dart';

class CustomerHome extends StatefulWidget {
  const CustomerHome({super.key});

  @override
  State<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    const titles = ['AutoAid', 'My requests', 'My vehicles', 'Profile'];
    final pages = [
      const _HomeTab(),
      const _RequestsTab(),
      const VehiclesScreen(),
      const ProfileScreen(),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(titles[_index])),
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.list_alt), label: 'Requests'),
          NavigationDestination(
              icon: Icon(Icons.directions_car), label: 'Vehicles'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AppState>().profile!.uid;
    final fs = context.read<FirestoreService>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        StreamBuilder<List<AssistanceRequest>>(
          stream: fs.customerRequests(uid),
          builder: (context, snap) {
            final active =
                (snap.data ?? []).where((r) => r.status.isActive).toList();
            if (active.isEmpty) return const SizedBox.shrink();
            final r = active.first;
            return Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: ListTile(
                leading: Icon(serviceTypeById(r.type).icon),
                title: Text('Active request: ${serviceTypeById(r.type).label}'),
                subtitle: Text(r.status.label),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            RequestDetailScreen(requestId: r.id))),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Text('What do you need?',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: [
            for (final t in serviceTypes.where((t) => t.id != 'accident'))
              Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              RequestFormScreen(initialType: t.id))),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(t.icon,
                          size: 32,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(height: 6),
                      Text(t.label, textAlign: TextAlign.center),
                      if (t.basePrice > 0)
                        Text('from ${t.basePrice} $currency',
                            style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: Icon(Icons.monitor_heart,
                color: Theme.of(context).colorScheme.primary),
            title: const Text('Car care guide'),
            subtitle: const Text('Which fluids to check, and when'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const CarCareScreen())),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const EmergencyScreen())),
          icon: const Icon(Icons.car_crash),
          label: const Text('Accident / emergency'),
        ),
      ],
    );
  }
}

class _RequestsTab extends StatelessWidget {
  const _RequestsTab();

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AppState>().profile!.uid;
    return StreamBuilder<List<AssistanceRequest>>(
      stream: context.read<FirestoreService>().customerRequests(uid),
      builder: (context, snap) {
        if (snap.hasError) return Center(child: Text('${snap.error}'));
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final list = snap.data!;
        if (list.isEmpty) {
          return const Center(child: Text('No requests yet.'));
        }
        return ListView.separated(
          itemCount: list.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final r = list[i];
            final type = serviceTypeById(r.type);
            return ListTile(
              leading: Icon(type.icon),
              title: Text(type.label),
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
                      builder: (_) => RequestDetailScreen(requestId: r.id))),
            );
          },
        );
      },
    );
  }
}
