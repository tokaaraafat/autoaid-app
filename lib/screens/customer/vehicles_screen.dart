import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/models.dart';
import '../../core/utils.dart';
import '../../services/app_state.dart';
import '../../services/firestore_service.dart';

/// Used as a tab inside CustomerHome (no Scaffold of its own).
class VehiclesScreen extends StatelessWidget {
  const VehiclesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AppState>().profile!.uid;
    final fs = context.read<FirestoreService>();

    return Stack(
      children: [
        StreamBuilder<List<Vehicle>>(
          stream: fs.vehicles(uid),
          builder: (context, snap) {
            if (snap.hasError) return Center(child: Text('${snap.error}'));
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final list = snap.data!;
            if (list.isEmpty) {
              return const Center(
                  child: Text('Add your car so providers know what to expect.'));
            }
            return ListView.separated(
              padding: const EdgeInsets.only(bottom: 88),
              itemCount: list.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final v = list[i];
                return ListTile(
                  leading: const Icon(Icons.directions_car),
                  title: Text(v.model),
                  subtitle: Text([
                    'Plate: ${v.licensePlate}',
                    if (v.insuranceInfo.isNotEmpty)
                      'Insurance: ${v.insuranceInfo}',
                    if (v.registrationInfo.isNotEmpty)
                      'Registration: ${v.registrationInfo}',
                  ].join('\n')),
                  isThreeLine: v.insuranceInfo.isNotEmpty ||
                      v.registrationInfo.isNotEmpty,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => fs.deleteVehicle(uid, v.id),
                  ),
                );
              },
            );
          },
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            onPressed: () => _addVehicle(context, uid, fs),
            icon: const Icon(Icons.add),
            label: const Text('Add vehicle'),
          ),
        ),
      ],
    );
  }

  Future<void> _addVehicle(
      BuildContext context, String uid, FirestoreService fs) async {
    final formKey = GlobalKey<FormState>();
    final model = TextEditingController();
    final plate = TextEditingController();
    final insurance = TextEditingController();
    final registration = TextEditingController();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add vehicle'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                    controller: model,
                    decoration: const InputDecoration(labelText: 'Model'),
                    validator: requiredField),
                TextFormField(
                    controller: plate,
                    decoration:
                        const InputDecoration(labelText: 'License plate'),
                    validator: requiredField),
                TextFormField(
                    controller: insurance,
                    decoration: const InputDecoration(
                        labelText: 'Insurance info (optional)')),
                TextFormField(
                    controller: registration,
                    decoration: const InputDecoration(
                        labelText: 'Registration info (optional)')),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved == true) {
      await fs.addVehicle(
        uid,
        Vehicle(
          id: '',
          model: model.text.trim(),
          licensePlate: plate.text.trim(),
          insuranceInfo: insurance.text.trim(),
          registrationInfo: registration.text.trim(),
        ),
      );
    }
    model.dispose();
    plate.dispose();
    insurance.dispose();
    registration.dispose();
  }
}
