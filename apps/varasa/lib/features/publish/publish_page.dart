import 'package:latlong2/latlong.dart';
import '../places/heritage_map.dart';
import '../../core/files/pick_upload.dart';
import 'package:flutter/material.dart';
import '../../core/widgets/common.dart';
import '../../domain/models.dart';

class PublishPage extends StatefulWidget {
  const PublishPage({super.key, required this.onPublished});
  final VoidCallback onPublished;
  @override
  State<PublishPage> createState() => _PublishPageState();
}

class _PublishPageState extends State<PublishPage> {
  final _form = GlobalKey<FormState>();
  final _caption = TextEditingController(),
      _place = TextEditingController(),
      _latitude = TextEditingController(),
      _longitude = TextEditingController();
  UploadFile? _file;
  bool _busy = false;
  String? _error;
  @override
  void dispose() {
    _caption.dispose();
    _place.dispose();
    _latitude.dispose();
    _longitude.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    try {
      final file = await pickUploadFile();
      if (file == null || !mounted) return;
      setState(() {
        _file = file;
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = errorMessage(e));
    }
  }

  Future<void> _publish() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      // Validate even when the optional coordinate fields are collapsed.
      final coordinateError =
          _coordinate(_latitude.text, true) ??
          _coordinate(_longitude.text, false);
      if (coordinateError != null) throw FormatException(coordinateError);
      final draft = PostDraft(
        caption: _caption.text,
        file: _file,
        place: _place.text,
        latitude: _latitude.text.trim().isEmpty
            ? null
            : double.tryParse(_latitude.text.trim()),
        longitude: _longitude.text.trim().isEmpty
            ? null
            : double.tryParse(_longitude.text.trim()),
      );
      await RepositoryScope.of(context).publish(draft);
      if (!mounted) return;
      _caption.clear();
      _place.clear();
      _latitude.clear();
      _longitude.clear();
      setState(() => _file = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your story is now part of Varasa.')),
      );
      widget.onPublished();
    } catch (e) {
      if (mounted) setState(() => _error = errorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _coordinate(String? value, bool latitude) {
    if ((value ?? '').trim().isEmpty) {
      final other = latitude ? _longitude.text : _latitude.text;
      return other.trim().isEmpty
          ? null
          : 'Enter both coordinates, or leave both empty.';
    }
    final n = double.tryParse(value!.trim());
    final bound = latitude ? 90 : 180;
    return n == null || !n.isFinite || n < -bound || n > bound
        ? 'Enter a value from -$bound to $bound.'
        : null;
  }

  @override
  Widget build(BuildContext context) => ContentWidth(
    child: Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Keep a tradition alive',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'A family memory, a folk art, or the rules of an old game. Every contribution adds to our shared heritage.',
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _caption,
            enabled: !_busy,
            maxLength: 3000,
            minLines: 5,
            maxLines: 12,
            decoration: const InputDecoration(
              labelText: 'Tell the story',
              alignLabelWithHint: true,
            ),
            validator: (v) => v == null || v.trim().isEmpty
                ? 'Write a little about this tradition.'
                : null,
          ),
          const SizedBox(height: 16),
          if (_file == null)
            OutlinedButton.icon(
              onPressed: _busy ? null : _pick,
              icon: const Icon(Icons.attach_file),
              label: const Text('Add a photo or PDF · Up to 10 MB'),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_file!.isImage)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      _file!.bytes,
                      height: 220,
                      fit: BoxFit.cover,
                    ),
                  ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.attachment),
                  title: Text(_file!.name),
                  trailing: IconButton(
                    tooltip: 'Remove attachment',
                    onPressed: _busy
                        ? null
                        : () => setState(() => _file = null),
                    icon: const Icon(Icons.close),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _place,
            enabled: !_busy,
            maxLength: 120,
            decoration: const InputDecoration(
              labelText: 'Place · Optional',
              hintText: 'Village, town or region',
            ),
          ),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text('Pin this story to a place'),
            subtitle: const Text(
              'Optional coordinates; your location is never collected automatically.',
            ),
            childrenPadding: const EdgeInsets.only(bottom: 16),
            children: [
              OutlinedButton.icon(
                onPressed: _busy
                    ? null
                    : () async {
                        final lat = double.tryParse(_latitude.text),
                            lng = double.tryParse(_longitude.text);
                        final point = await Navigator.push<LatLng>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PlacePickerPage(
                              initial:
                                  lat != null &&
                                      lng != null &&
                                      lat.isFinite &&
                                      lng.isFinite &&
                                      lat.abs() <= 90 &&
                                      lng.abs() <= 180
                                  ? LatLng(lat, lng)
                                  : null,
                            ),
                          ),
                        );
                        if (point != null && mounted) {
                          _latitude.text = point.latitude.toStringAsFixed(5);
                          _longitude.text = point.longitude.toStringAsFixed(5);
                        }
                      },
                icon: const Icon(Icons.map_outlined),
                label: const Text('Choose on map'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _latitude,
                enabled: !_busy,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                decoration: const InputDecoration(labelText: 'Latitude'),
                validator: (v) => _coordinate(v, true),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _longitude,
                enabled: !_busy,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                decoration: const InputDecoration(labelText: 'Longitude'),
                validator: (v) => _coordinate(v, false),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Share content you have permission to share. Add context and credit the people behind it.',
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Semantics(
                liveRegion: true,
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _busy ? null : _publish,
            icon: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.publish_outlined),
            label: Text(
              _busy
                  ? 'Publishing… Keep this app open'
                  : 'Share with the community',
            ),
          ),
        ],
      ),
    ),
  );
}
