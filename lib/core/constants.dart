import 'package:material_ui/material_ui.dart';

const String currency = 'EGP';

class ServiceType {
  const ServiceType(this.id, this.label, this.icon, this.basePrice);
  final String id;
  final String label;
  final IconData icon;

  /// Estimated price. 0 means "agreed on site".
  final int basePrice;
}

const List<ServiceType> serviceTypes = [
  ServiceType('towing', 'Towing', Icons.local_shipping, 300),
  ServiceType('flat_tire', 'Flat tire', Icons.tire_repair, 150),
  ServiceType('battery', 'Battery jump-start', Icons.battery_charging_full, 120),
  ServiceType('fuel', 'Fuel delivery', Icons.local_gas_station, 100),
  ServiceType('lockout', 'Lockout help', Icons.key, 130),
  ServiceType('engine', 'Engine problem', Icons.build, 200),
  ServiceType('accident', 'Accident', Icons.car_crash, 0),
];

ServiceType serviceTypeById(String id) =>
    serviceTypes.firstWhere((t) => t.id == id, orElse: () => serviceTypes.first);

const List<String> severities = ['low', 'medium', 'high'];

class EmergencyNumber {
  const EmergencyNumber(this.name, this.number);
  final String name;
  final String number;
}

/// Egypt emergency numbers. Edit for your country.
const List<EmergencyNumber> emergencyNumbers = [
  EmergencyNumber('Police', '122'),
  EmergencyNumber('Ambulance', '123'),
  EmergencyNumber('Fire department', '180'),
  EmergencyNumber('Traffic police', '128'),
];

/// Map used when the GPS position is not available yet (Cairo).
const double defaultLat = 30.0444;
const double defaultLng = 31.2357;

/// Providers only see pending requests within this distance.
const double maxRequestRadiusKm = 50;

/// Average speed used to estimate arrival time.
const double averageSpeedKmh = 40;
