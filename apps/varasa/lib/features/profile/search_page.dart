import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/widgets/common.dart';
import '../../domain/models.dart';
import 'profile_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  Timer? _timer;
  List<Profile> _people = [];
  String _query = '';
  String? _error;
  bool _loading = false;
  int _request = 0;
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _search(String value) {
    _timer?.cancel();
    final version = ++_request;
    setState(() {
      _query = value.trim();
      _loading = _query.isNotEmpty;
      _error = null;
      _people = [];
    });
    if (_query.isEmpty) return;
    final repo = RepositoryScope.of(context);
    _timer = Timer(const Duration(milliseconds: 300), () async {
      try {
        final result = await repo.searchPeople(value);
        if (mounted && version == _request) setState(() => _people = result);
      } catch (e) {
        if (mounted && version == _request) {
          setState(() => _error = errorMessage(e));
        }
      } finally {
        if (mounted && version == _request) setState(() => _loading = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Find your people')),
    body: SafeArea(
      child: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextField(
              autofocus: true,
              onChanged: _search,
              decoration: const InputDecoration(
                labelText: 'Search by username',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 24),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              EmptyState(
                title: 'Search is unavailable',
                message: _error!,
                action: OutlinedButton(
                  onPressed: () => _search(_query),
                  child: const Text('Retry'),
                ),
              )
            else if (_query.isEmpty)
              const EmptyState(
                title: 'A shared interest starts here',
                message:
                    'Enter the first letters of a username. Try “meera” in the demo.',
              )
            else if (_people.isEmpty)
              const EmptyState(
                title: 'No members found',
                message: 'Try a shorter username prefix.',
              )
            else
              ..._people.map(
                (p) => ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.person_outline),
                  ),
                  title: Text(p.name),
                  subtitle: Text('@${p.username}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          ProfilePage(userId: p.id, standalone: true),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
