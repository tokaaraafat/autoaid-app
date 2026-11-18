import 'package:material_ui/material_ui.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// OpenStreetMap view used across the app.
///
/// Note: the public tile server (tile.openstreetmap.org) is meant for light
/// use. For a production app switch to a tile provider you have an account
/// with (MapTiler, Stadia, your own server...).
class OsmMap extends StatelessWidget {
  const OsmMap({
    super.key,
    required this.center,
    this.zoom = 14,
    this.markers = const [],
    this.controller,
    this.onTap,
    this.height = 260,
  });

  final LatLng center;
  final double zoom;
  final List<Marker> markers;
  final MapController? controller;
  final void Function(LatLng point)? onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: FlutterMap(
          mapController: controller,
          options: MapOptions(
            initialCenter: center,
            initialZoom: zoom,
            onTap: onTap == null ? null : (_, point) => onTap!(point),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.autoaid.app',
            ),
            MarkerLayer(markers: markers),
            const SimpleAttributionWidget(
              source: Text('OpenStreetMap contributors'),
            ),
          ],
        ),
      ),
    );
  }
}

Marker pinMarker(LatLng point, IconData icon, Color color) => Marker(
      point: point,
      width: 44,
      height: 44,
      child: Icon(icon, color: color, size: 40),
    );
