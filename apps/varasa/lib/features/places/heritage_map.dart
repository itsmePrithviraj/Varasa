import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/widgets/common.dart';

class HeritageMap extends StatefulWidget {
  const HeritageMap({
    super.key,
    this.center = const LatLng(20.5937, 78.9629),
    this.markers = const [],
    this.onPick,
    this.feedbackTop = 8,
  });
  final LatLng center;
  final List<Marker> markers;
  final ValueChanged<LatLng>? onPick;
  final double feedbackTop;
  @override
  State<HeritageMap> createState() => _HeritageMapState();
}

class _HeritageMapState extends State<HeritageMap> {
  bool _failed = false;
  @override
  Widget build(BuildContext context) => Stack(
    children: [
      FlutterMap(
        options: MapOptions(
          initialCenter: widget.center,
          initialZoom: 5,
          onTap: (_, point) => widget.onPick?.call(point),
        ),
        children: [
          TileLayer(
            urlTemplate: const String.fromEnvironment(
              'MAP_TILE_URL',
              defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            ),
            userAgentPackageName: 'org.varasa.heritage',
            errorTileCallback: (_, __, ___) {
              if (!_failed && mounted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() => _failed = true);
                });
              }
            },
          ),
          MarkerLayer(markers: widget.markers),
          RichAttributionWidget(
            attributions: [
              TextSourceAttribution(
                const String.fromEnvironment(
                  'MAP_ATTRIBUTION',
                  defaultValue: 'OpenStreetMap contributors',
                ),
                onTap: () => openExternal(
                  context,
                  const String.fromEnvironment(
                    'MAP_ATTRIBUTION_URL',
                    defaultValue: 'https://www.openstreetmap.org/copyright',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      if (_failed)
        Positioned(
          top: widget.feedbackTop,
          left: 8,
          right: 8,
          child: Material(
            color: Theme.of(context).colorScheme.surface,
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Some map tiles could not load. You can still use coordinates or the places list.',
              ),
            ),
          ),
        ),
    ],
  );
}

class PlacePickerPage extends StatefulWidget {
  const PlacePickerPage({super.key, this.initial});
  final LatLng? initial;
  @override
  State<PlacePickerPage> createState() => _PlacePickerPageState();
}

class _PlacePickerPageState extends State<PlacePickerPage> {
  LatLng? _point;
  @override
  void initState() {
    super.initState();
    _point = widget.initial;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Choose a place')),
    body: SafeArea(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Tap the map to place a pin. Choose a public place rather than a private home.',
            ),
          ),
          Expanded(
            child: HeritageMap(
              center: widget.initial ?? const LatLng(20.5937, 78.9629),
              onPick: (point) => setState(() => _point = point),
              markers: [
                if (_point != null)
                  Marker(
                    point: _point!,
                    width: 48,
                    height: 48,
                    child: Icon(
                      Icons.location_pin,
                      size: 40,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  _point == null
                      ? 'No place selected'
                      : '${_point!.latitude.toStringAsFixed(5)}, ${_point!.longitude.toStringAsFixed(5)}',
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _point == null
                      ? null
                      : () => Navigator.pop(context, _point),
                  child: const Text('Use this pin'),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
