import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/utils.dart';
import 'request_form_screen.dart';

class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'If anyone is hurt, call emergency services first.',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          for (final e in emergencyNumbers)
            Card(
              child: ListTile(
                leading: const Icon(Icons.phone, color: Colors.red),
                title: Text(e.name),
                subtitle: Text(e.number),
                trailing: FilledButton(
                  onPressed: () => callNumber(context, e.number),
                  child: const Text('Call'),
                ),
              ),
            ),
          const SizedBox(height: 16),
          const Text(
              'Then report the accident so nearby roadside providers can help '
              'with towing and recovery.'),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        const RequestFormScreen(initialType: 'accident'))),
            icon: const Icon(Icons.report),
            label: const Text('Report accident'),
          ),
        ],
      ),
    );
  }
}
