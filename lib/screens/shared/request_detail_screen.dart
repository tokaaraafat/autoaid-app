import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/models.dart';
import '../../core/utils.dart';
import '../../services/app_state.dart';
import '../../services/firestore_service.dart';
import '../../services/location_service.dart';
import '../../widgets/osm_map.dart';
import 'chat_screen.dart';

/// One screen for both roles.
///  - Customer: tracks the provider live, chats, cancels, pays and rates.
///  - Provider (asProvider = true): accepts the request, updates its status and
///    shares live GPS while the job is active.
class RequestDetailScreen extends StatefulWidget {
  const RequestDetailScreen(
      {super.key, required this.requestId, this.asProvider = false});
  final String requestId;
  final bool asProvider;

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  StreamSubscription<LatLng>? _locationSub;
  bool _sharing = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (widget.asProvider) {
      // Ask for the location permission up front.
      LocationService.current();
    }
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    super.dispose();
  }

  /// Providers publish their position while a job is in progress.
  void _syncLocationSharing(AssistanceRequest r, String myUid) {
    final shouldShare = widget.asProvider &&
        r.providerId == myUid &&
        (r.status == RequestStatus.accepted ||
            r.status == RequestStatus.onTheWay ||
            r.status == RequestStatus.arrived);

    if (shouldShare && !_sharing) {
      _sharing = true;
      final fs = context.read<FirestoreService>();
      _locationSub = LocationService.stream().listen(
        (p) => fs.updateProviderLocation(r.id, p),
        onError: (_) {},
      );
    } else if (!shouldShare && _sharing) {
      _locationSub?.cancel();
      _locationSub = null;
      _sharing = false;
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) showMessage(context, 'Something went wrong: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = context.read<AppState>().profile!;
    final fs = context.read<FirestoreService>();

    return StreamBuilder<AssistanceRequest?>(
      stream: fs.requestStream(widget.requestId),
      builder: (context, snap) {
        if (snap.hasError) {
          return Scaffold(
              appBar: AppBar(), body: Center(child: Text('${snap.error}')));
        }
        if (!snap.hasData) {
          return Scaffold(
              appBar: AppBar(),
              body: const Center(child: CircularProgressIndicator()));
        }
        final r = snap.data;
        if (r == null) {
          return Scaffold(
              appBar: AppBar(),
              body: const Center(child: Text('Request not found.')));
        }

        _syncLocationSharing(r, me.uid);

        final type = serviceTypeById(r.type);
        final distanceKm = r.providerLocation == null
            ? null
            : LocationService.distanceKm(r.providerLocation!, r.location);

        return Scaffold(
          appBar: AppBar(title: Text(type.label)),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              OsmMap(
                center: r.location,
                zoom: 14,
                height: 280,
                markers: [
                  pinMarker(r.location, Icons.location_on, Colors.red),
                  if (r.providerLocation != null)
                    pinMarker(r.providerLocation!, Icons.local_shipping,
                        Colors.indigo),
                ],
              ),
              const SizedBox(height: 12),
              _StatusCard(request: r, distanceKm: distanceKm),
              const SizedBox(height: 12),
              _DetailsCard(request: r, asProvider: widget.asProvider),
              if (r.providerId != null) ...[
                const SizedBox(height: 12),
                _ParticipantCard(request: r, asProvider: widget.asProvider),
              ],
              const SizedBox(height: 16),
              ..._actions(context, r, me, fs),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _actions(BuildContext context, AssistanceRequest r, AppUser me,
      FirestoreService fs) {
    final widgets = <Widget>[];
    final hasProvider = r.providerId != null;
    final isMyJob = r.providerId == me.uid;

    // Chat (both roles, once a provider is assigned)
    if (hasProvider && (isMyJob || r.customerId == me.uid)) {
      widgets.add(OutlinedButton.icon(
        onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => ChatScreen(
                    requestId: r.id,
                    title: widget.asProvider
                        ? r.customerName
                        : (r.providerName ?? 'Provider')))),
        icon: const Icon(Icons.chat),
        label: const Text('Chat'),
      ));
      widgets.add(const SizedBox(height: 8));
    }

    if (widget.asProvider) {
      widgets.addAll(_providerActions(context, r, me, fs, isMyJob));
    } else {
      widgets.addAll(_customerActions(context, r, fs));
    }
    return widgets;
  }

  // ------------------------------------------------------------- provider

  List<Widget> _providerActions(BuildContext context, AssistanceRequest r,
      AppUser me, FirestoreService fs, bool isMyJob) {
    final out = <Widget>[];

    if (r.status == RequestStatus.pending) {
      final canAccept = me.verified && me.available;
      out.add(FilledButton.icon(
        onPressed: (_busy || !canAccept)
            ? null
            : () => _run(() async {
                  final loc = await LocationService.current();
                  final ok = await fs.acceptRequest(r.id, me, loc);
                  if (!ok && context.mounted) {
                    showMessage(context,
                        'Another provider accepted this request first.');
                  }
                }),
        icon: const Icon(Icons.check),
        label: const Text('Accept request'),
      ));
      if (!canAccept) {
        out.add(Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(!me.verified
              ? 'Your account must be verified by an administrator first.'
              : 'Switch to "Available" on the home screen to accept requests.'),
        ));
      }
      return out;
    }

    if (!isMyJob) return out;

    if (r.status == RequestStatus.accepted) {
      out.add(FilledButton.icon(
        onPressed:
            _busy ? null : () => _run(() => fs.updateStatus(r.id, RequestStatus.onTheWay)),
        icon: const Icon(Icons.directions_car),
        label: const Text("I'm on my way"),
      ));
    } else if (r.status == RequestStatus.onTheWay) {
      out.add(FilledButton.icon(
        onPressed:
            _busy ? null : () => _run(() => fs.updateStatus(r.id, RequestStatus.arrived)),
        icon: const Icon(Icons.flag),
        label: const Text("I've arrived"),
      ));
    } else if (r.status == RequestStatus.arrived) {
      out.add(FilledButton.icon(
        onPressed: _busy
            ? null
            : () => _run(() => fs.updateStatus(r.id, RequestStatus.completed)),
        icon: const Icon(Icons.task_alt),
        label: const Text('Mark service as completed'),
      ));
    }

    if (r.status == RequestStatus.completed) {
      out.add(Text(r.paid
          ? 'Paid by ${r.paymentMethod ?? 'customer'}.'
          : 'Waiting for the customer to pay.'));
    }
    return out;
  }

  // ------------------------------------------------------------- customer

  List<Widget> _customerActions(
      BuildContext context, AssistanceRequest r, FirestoreService fs) {
    final out = <Widget>[];

    if (r.status.canCancel) {
      out.add(OutlinedButton.icon(
        style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
        onPressed: _busy ? null : () => _confirmCancel(context, r, fs),
        icon: const Icon(Icons.cancel),
        label: const Text('Cancel request'),
      ));
    }

    if (r.status == RequestStatus.completed) {
      if (r.price > 0 && !r.paid) {
        out.add(FilledButton.icon(
          onPressed: _busy ? null : () => _pay(context, r, fs),
          icon: const Icon(Icons.payments),
          label: Text('Pay ${r.price} $currency'),
        ));
        out.add(const SizedBox(height: 8));
      }
      if (r.paid) {
        out.add(Text('Paid by ${r.paymentMethod}.'));
      }
      if (!r.rated && r.providerId != null) {
        out.add(const SizedBox(height: 8));
        out.add(FilledButton.tonalIcon(
          onPressed: _busy ? null : () => _rate(context, r, fs),
          icon: const Icon(Icons.star),
          label: const Text('Rate the provider'),
        ));
      } else if (r.rated) {
        out.add(Text('You rated this service ${r.rating}/5.'));
      }
    }
    return out;
  }

  Future<void> _confirmCancel(
      BuildContext context, AssistanceRequest r, FirestoreService fs) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel this request?'),
        content: r.providerId != null
            ? const Text('The provider will be notified.')
            : null,
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep it')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Cancel request')),
        ],
      ),
    );
    if (yes == true) {
      await _run(() => fs.updateStatus(r.id, RequestStatus.cancelled));
    }
  }

  Future<void> _pay(
      BuildContext context, AssistanceRequest r, FirestoreService fs) async {
    final method = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
                title: Text('Choose a payment method',
                    style: TextStyle(fontWeight: FontWeight.bold))),
            ListTile(
              leading: const Icon(Icons.money),
              title: const Text('Cash'),
              onTap: () => Navigator.pop(ctx, 'cash'),
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet),
              title: const Text('Wallet / Visa (simulated)'),
              onTap: () => Navigator.pop(ctx, 'wallet/visa'),
            ),
          ],
        ),
      ),
    );
    if (method != null) await _run(() => fs.markPaid(r.id, method));
  }

  Future<void> _rate(
      BuildContext context, AssistanceRequest r, FirestoreService fs) async {
    int stars = 5;
    final feedback = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Rate the provider'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 1; i <= 5; i++)
                    IconButton(
                      icon: Icon(i <= stars ? Icons.star : Icons.star_border,
                          color: Colors.amber),
                      onPressed: () => setLocal(() => stars = i),
                    ),
                ],
              ),
              TextField(
                controller: feedback,
                maxLines: 3,
                decoration: const InputDecoration(
                    labelText: 'Feedback (optional)',
                    border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Later')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Submit')),
          ],
        ),
      ),
    );

    if (ok == true) {
      await _run(() => fs.rateProvider(
            requestId: r.id,
            providerId: r.providerId!,
            stars: stars,
            feedback: feedback.text,
          ));
    }
    feedback.dispose();
  }
}

// ------------------------------------------------------------ small widgets

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.request, required this.distanceKm});
  final AssistanceRequest request;
  final double? distanceKm;

  @override
  Widget build(BuildContext context) {
    final r = request;
    final showEta = distanceKm != null &&
        (r.status == RequestStatus.accepted ||
            r.status == RequestStatus.onTheWay);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.circle, size: 14, color: r.status.color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(r.status.label,
                      style: Theme.of(context).textTheme.titleMedium),
                ),
              ],
            ),
            if (showEta) ...[
              const SizedBox(height: 8),
              Text(
                  '${distanceKm!.toStringAsFixed(1)} km away - about '
                  '${LocationService.etaMinutes(distanceKm!)} min'),
            ],
            if (r.status == RequestStatus.pending)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: LinearProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.request, required this.asProvider});
  final AssistanceRequest request;
  final bool asProvider;

  @override
  Widget build(BuildContext context) {
    final r = request;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _row('Problem', r.description),
            _row('Severity', r.severity),
            if (r.vehicle.isNotEmpty) _row('Vehicle', r.vehicle),
            _row('Price',
                r.price == 0 ? 'Agreed on site' : '${r.price} $currency (estimate)'),
            if (asProvider) ...[
              _row('Customer', r.customerName),
              InkWell(
                onTap: () => callNumber(context, r.customerPhone),
                child: _row('Phone', '${r.customerPhone}  (tap to call)'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                width: 80,
                child: Text(label,
                    style: const TextStyle(fontWeight: FontWeight.bold))),
            Expanded(child: Text(value)),
          ],
        ),
      );
}

class _ParticipantCard extends StatelessWidget {
  const _ParticipantCard({required this.request, required this.asProvider});
  final AssistanceRequest request;
  final bool asProvider;

  @override
  Widget build(BuildContext context) {
    final r = request;
    final name = asProvider ? r.customerName : (r.providerName ?? 'Provider');
    final phone = asProvider ? r.customerPhone : (r.providerPhone ?? '');
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person)),
        title: Text(name),
        subtitle: Text(asProvider ? 'Customer' : 'Your service provider'),
        trailing: phone.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.call),
                onPressed: () => callNumber(context, phone),
              ),
      ),
    );
  }
}
