import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/widgets/common.dart';
import '../../domain/models.dart';
import '../feed/post_detail_page.dart';
import 'heritage_map.dart';

class PlacesPage extends StatefulWidget {
  const PlacesPage({super.key});
  @override
  State<PlacesPage> createState() => _PlacesPageState();
}

class _PlacesPageState extends State<PlacesPage> {
  final _places = <HeritagePost>[];
  bool _started = false, _busy = false, _more = true, _map = true;
  String? _cursor;
  HeritagePost? _selected;
  int _generation = 0;
  Object? _error;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _load();
    }
  }

  Future<void> _load({bool reset = false}) async {
    if (_busy && !reset) return;
    final generation = ++_generation;
    setState(() {
      _busy = true;
      _error = null;
      if (reset) {
        _selected = null;
        _places.clear();
        _cursor = null;
        _more = true;
      }
    });
    try {
      final page = await RepositoryScope.of(
        context,
      ).fetchPosts(cursor: _cursor);
      if (!mounted || generation != _generation) return;
      setState(() {
        final ids = _places.map((p) => p.id).toSet();
        _places.addAll(
          page.items.where(
            (p) => (p.place.isNotEmpty || p.latitude != null) && ids.add(p.id),
          ),
        );
        _cursor = page.cursor;
        _more = page.hasMore;
      });
    } catch (e) {
      if (mounted && generation == _generation) setState(() => _error = e);
    } finally {
      if (mounted && generation == _generation) setState(() => _busy = false);
    }
  }

  Future<void> _open(HeritagePost p) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => PostDetailPage(postId: p.id)),
    );
    if (mounted) await _load(reset: true);
  }

  Widget _controls() => Material(
    color: const Color(0xFFFFEEDB),
    borderRadius: BorderRadius.circular(24),
    elevation: 2,
    child: Row(
      children: [
        const BackButton(),
        const Expanded(
          child: Text(
            'Cultural map',
            style: TextStyle(
              fontFamily: 'CinzelDecorative',
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Refresh places',
          onPressed: _busy ? null : () => _load(reset: true),
          icon: const Icon(Icons.refresh),
        ),
        IconButton(
          tooltip: _map ? 'Show places list' : 'Show map',
          onPressed: () => setState(() => _map = !_map),
          icon: Icon(_map ? Icons.list : Icons.map_outlined),
        ),
      ],
    ),
  );

  Widget _status() => Padding(
    padding: const EdgeInsets.all(12),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _places.isEmpty
              ? 'No places in the loaded stories yet.'
              : '${_places.length} places from loaded stories.',
          style: const TextStyle(fontSize: 12),
        ),
        if (_error != null) Text(errorMessage(_error!)),
        if (_busy)
          const LinearProgressIndicator()
        else if (_more || _error != null)
          TextButton(
            onPressed: () => _load(),
            child: Text(_error == null ? 'Explore more stories' : 'Retry'),
          ),
      ],
    ),
  );

  Widget _preview(HeritagePost p) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (p.image.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: HeritageImage(p.image),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.place.isEmpty ? 'Shared location' : p.place,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(p.caption, maxLines: 3, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Close place preview',
              onPressed: () => setState(() => _selected = null),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: () => _open(p),
          child: const Text('View full story'),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Stack(
        children: [
          Positioned.fill(
            child: _map
                ? HeritageMap(
                    feedbackTop: 96,
                    markers: [
                      for (final p in _places)
                        if (p.latitude != null && p.longitude != null)
                          Marker(
                            point: LatLng(p.latitude!, p.longitude!),
                            width: 48,
                            height: 48,
                            child: IconButton(
                              tooltip: p.place.isEmpty
                                  ? 'Preview this place'
                                  : p.place,
                              onPressed: () => setState(() => _selected = p),
                              icon: Icon(
                                Icons.location_pin,
                                size: 40,
                                color: _selected?.id == p.id
                                    ? const Color(0xFF652C12)
                                    : const Color(0xFFE3473F),
                              ),
                            ),
                          ),
                    ],
                  )
                : ContentWidth(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 90, 20, 140),
                      children: [
                        if (_places.isEmpty)
                          const EmptyState(
                            title: 'Places shared by the community',
                            message:
                                'Add a location when you share a cultural story. Stories with coordinates appear as pins.',
                          ),
                        ..._places.map(
                          (p) => ListTile(
                            leading: const Icon(Icons.place_outlined),
                            title: Text(
                              p.place.isEmpty ? 'Shared location' : p.place,
                            ),
                            subtitle: Text(
                              p.caption,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () => _open(p),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: _controls(),
              ),
            ),
          ),
          Positioned(
            bottom: _map ? 36 : 12,
            left: 20,
            right: 20,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Material(
                  color: const Color(0xFFFFEEDB),
                  elevation: 5,
                  borderRadius: BorderRadius.circular(18),
                  child: _map && _selected != null
                      ? _preview(_selected!)
                      : _status(),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
