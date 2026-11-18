import 'package:material_ui/material_ui.dart';

import '../../core/constants.dart';
import 'request_form_screen.dart';

class _CareItem {
  const _CareItem(this.title, this.icon, this.color, this.check, this.warning);
  final String title;
  final IconData icon;
  final Color color;
  final String check;
  final String warning;
}

const List<_CareItem> _items = [
  _CareItem(
    'Engine oil',
    Icons.oil_barrel,
    Colors.orange,
    'Check about once a month with the engine off, on level ground. The level '
        'on the dipstick should sit between the min and max marks.',
    'Oil warning light, burning smell or knocking noises: stop driving and ask for help.',
  ),
  _CareItem(
    'Engine coolant',
    Icons.thermostat,
    Colors.lightGreen,
    'Look at the coolant reservoir and keep the level between min and max. '
        'Only open the cap when the engine is completely cold.',
    'Temperature gauge in the red or steam from the hood: pull over safely and switch the engine off.',
  ),
  _CareItem(
    'Brake fluid',
    Icons.error_outline,
    Colors.redAccent,
    'The reservoir level should be between min and max. Brake fluid ages, so '
        'replace it as your car manual says.',
    'Soft or sinking brake pedal, or a brake warning light: do not drive, request towing.',
  ),
  _CareItem(
    'Power steering fluid',
    Icons.settings,
    Colors.white70,
    'Check the reservoir if your car has hydraulic power steering (cars with '
        'electric steering have no fluid).',
    'Heavy steering or a whining noise when turning often means low fluid.',
  ),
  _CareItem(
    'Windscreen washer fluid',
    Icons.water_drop,
    Colors.lightBlueAccent,
    'Top up the washer reservoir with proper washer fluid so you can always '
        'clean the glass.',
    'Dirty glass with nothing coming out of the jets: refill before you drive at night.',
  ),
  _CareItem(
    'Clutch fluid',
    Icons.sync,
    Colors.amber,
    'Manual cars only. On many cars the clutch shares its reservoir with the '
        'brake fluid, so check the level there.',
    'Spongy clutch pedal or difficulty changing gears can mean low fluid or air in the system.',
  ),
];

/// "Practical advice related to car maintenance" from the project's feature list.
class CarCareScreen extends StatelessWidget {
  const CarCareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Car care guide')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Which fluids need checking?',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          const Text(
              'General tips only. Your car manual has the exact levels and '
              'service intervals for your model.'),
          const SizedBox(height: 12),
          for (final item in _items)
            Card(
              child: ExpansionTile(
                leading: Icon(item.icon, color: item.color, size: 30),
                title: Text(item.title),
                shape: const Border(),
                collapsedShape: const Border(),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('What to check',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(item.check),
                  const SizedBox(height: 8),
                  const Text('Warning signs',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(item.warning),
                ],
              ),
            ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (_) => RequestFormScreen(
                        initialType: serviceTypes[5].id))),
            icon: const Icon(Icons.build),
            label: const Text('Something looks wrong? Request help'),
          ),
        ],
      ),
    );
  }
}
