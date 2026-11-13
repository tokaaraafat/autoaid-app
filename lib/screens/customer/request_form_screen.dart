import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/models.dart';
import '../../core/utils.dart';
import '../../services/app_state.dart';
import '../../services/firestore_service.dart';
import '../../services/location_service.dart';
import '../../widgets/osm_map.dart';
import '../shared/request_detail_screen.dart';

class RequestFormScreen extends StatefulWidget {
  const RequestFormScreen({super.key, required this.initialType});
  final String initialType;

  @override
  State<RequestFormScreen> createState() => _RequestFormScreenState();
}

class _RequestFormScreenState extends State<RequestFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _description = TextEditingController();
  final _mapController = MapController();

  late String _type = widget.initialType;
  late String _severity = widget.initialType == 'accident' ? 'high' : 'medium';
  LatLng? _position;
  Vehicle? _vehicle;
  bool _locating = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _locate();
  }

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<void> _locate() async {
    setState(() => _locating = true);
    final p = await LocationService.current();
    if (!mounted) return;
    setState(() {
      _locating = false;
      if (p != null) {
        _position = p;
        _mapController.move(p, 16);
      }
    });
    if (p == null) {
      showMessage(context,
          'Could not get your location. Tap the map to set it manually.');
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final position = _position;
    if (position == null) {
      showMessage(context, 'Please set your location on the map.');
      return;
    }
    final profile = context.read<AppState>().profile!;
    final fs = context.read<FirestoreService>();
    final navigator = Navigator.of(context);

    setState(() => _submitting = true);
    try {
      final id = await fs.createRequest(AssistanceRequest(
        id: '',
        customerId: profile.uid,
        customerName: profile.name,
        customerPhone: profile.phone,
        type: _type,
        description: _description.text.trim(),
        severity: _severity,
        location: position,
        vehicle: _vehicle?.summary ?? '',
        isAccident: _type == 'accident',
        status: RequestStatus.pending,
        price: serviceTypeById(_type).basePrice,
        createdAt: DateTime.now(),
      ));
      navigator.pushReplacement(MaterialPageRoute(
          builder: (_) => RequestDetailScreen(requestId: id)));
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        showMessage(context, 'Could not send the request: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AppState>().profile!.uid;
    final center = _position ?? const LatLng(defaultLat, defaultLng);

    return Scaffold(
      appBar: AppBar(title: const Text('Request assistance')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Service', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in serviceTypes)
                  ChoiceChip(
                    avatar: Icon(t.icon, size: 18),
                    label: Text(t.label),
                    selected: _type == t.id,
                    onSelected: (_) => setState(() {
                      _type = t.id;
                      if (t.id == 'accident') _severity = 'high';
                    }),
                  ),
              ],
            ),
            if (_type == 'accident')
              Card(
                color: const Color(0xFF3A1620),
                margin: const EdgeInsets.only(top: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Is anyone hurt? Call emergency services now.'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final e in emergencyNumbers.take(2))
                            OutlinedButton.icon(
                              onPressed: () => callNumber(context, e.number),
                              icon: const Icon(Icons.phone),
                              label: Text('${e.name} ${e.number}'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 20),
            Text('Severity', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: [
                for (final s in severities)
                  ButtonSegment(value: s, label: Text(s)),
              ],
              selected: {_severity},
              onSelectionChanged: (s) => setState(() => _severity = s.first),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _description,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Describe the problem',
                border: OutlineInputBorder(),
              ),
              validator: requiredField,
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<Vehicle>>(
              stream: context.read<FirestoreService>().vehicles(uid),
              builder: (context, snap) {
                final vehicles = snap.data ?? [];
                if (vehicles.isEmpty) return const SizedBox.shrink();
                return DropdownButtonFormField<Vehicle>(
                  decoration: const InputDecoration(
                    labelText: 'Vehicle (optional)',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final v in vehicles)
                      DropdownMenuItem(value: v, child: Text(v.summary)),
                  ],
                  onChanged: (v) => setState(() => _vehicle = v),
                );
              },
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text('Your location',
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                TextButton.icon(
                  onPressed: _locating ? null : _locate,
                  icon: const Icon(Icons.my_location),
                  label: const Text('Use GPS'),
                ),
              ],
            ),
            const Text('Tap the map to move the pin.'),
            const SizedBox(height: 8),
            OsmMap(
              center: center,
              controller: _mapController,
              zoom: _position == null ? 11 : 16,
              onTap: (p) => setState(() => _position = p),
              markers: [
                if (_position != null)
                  pinMarker(_position!, Icons.location_on, Colors.red),
              ],
            ),
            if (_locating)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: LinearProgressIndicator(),
              ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Send request'),
            ),
          ],
        ),
      ),
    );
  }
}
