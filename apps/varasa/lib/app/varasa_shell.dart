import 'package:flutter/material.dart';
import '../core/widgets/common.dart';
import '../core/widgets/heritage_chrome.dart';
import '../core/config/app_config.dart';
import '../domain/models.dart';
import '../features/feed/feed_page.dart';
import '../features/games/games_page.dart';
import '../features/heritage/heritage_page.dart';
import '../features/profile/profile_page.dart';
import '../features/profile/search_page.dart';
import '../features/publish/publish_page.dart';
import '../features/places/places_page.dart';

class VarasaShell extends StatefulWidget {
  const VarasaShell({super.key});
  @override
  State<VarasaShell> createState() => _VarasaShellState();
}

class _VarasaShellState extends State<VarasaShell> {
  int _index = 0;
  final _feedKey = GlobalKey<FeedPageState>();
  final _pages = <int, Widget>{};
  Stream<Profile>? _me;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repo = RepositoryScope.of(context);
    _me ??= repo.watchProfile(repo.currentUserId!);
  }

  Widget _page(int i) => _pages.putIfAbsent(
    i,
    () => switch (i) {
      0 => FeedPage(key: _feedKey),
      1 => const GamesPage(),
      2 => PublishPage(
        onPublished: () {
          setState(() => _index = 0);
          _feedKey.currentState?.refresh();
        },
      ),
      3 => const HeritagePage(),
      _ => ProfilePage(userId: RepositoryScope.of(context).currentUserId!),
    },
  );
  void _select(int i) {
    if (i == 0 && _index == 0) _feedKey.currentState?.refresh();
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);
    _page(_index);
    return LayoutBuilder(
      builder: (context, size) {
        final wide =
            size.maxWidth >= 900 &&
            size.maxHeight >=
                640 * MediaQuery.textScalerOf(context).scale(16) / 16;
        final actions = <Widget>[
          if (repo.isDemo || AppConfig.useEmulators)
            IconButton(
              tooltip: repo.isDemo
                  ? 'Local demo information'
                  : 'Local backend information',
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                showDragHandle: true,
                builder: (_) => const SafeArea(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Local preview\n\nDemo profiles and stories are samples. Demo edits reset when the app restarts. Firebase emulator data is stored only in your local emulators.',
                    ),
                  ),
                ),
              ),
              icon: Text(
                repo.isDemo ? 'Demo' : 'Local',
                style: const TextStyle(fontSize: 11),
              ),
            ),
          IconButton(
            tooltip: 'Find people',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const SearchPage()),
            ),
            icon: const Icon(Icons.search, size: 22),
          ),
        ];
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            bottom: false,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (wide)
                  NavigationRail(
                    selectedIndex: _index,
                    labelType: NavigationRailLabelType.all,
                    onDestinationSelected: _select,
                    destinations: List.generate(
                      5,
                      (i) => NavigationRailDestination(
                        icon: Image.asset(
                          HeritageNavigation.assets[i],
                          width: 28,
                          height: 28,
                        ),
                        label: Text(HeritageNavigation.labels[i]),
                      ),
                    ),
                  ),
                Expanded(
                  child: Column(
                    children: [
                      if (_index != 4)
                        ContentWidth(
                          maxWidth: 900,
                          child: HeritageHeader(
                            home: _index == 0,
                            actions: actions,
                          ),
                        ),
                      Expanded(
                        child: IndexedStack(
                          index: _index,
                          children: List.generate(
                            5,
                            (i) => _pages[i] ?? const SizedBox.shrink(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: _index == 0
              ? FloatingActionButton.small(
                  heroTag: 'cultural-map',
                  tooltip: 'Cultural map',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(builder: (_) => const PlacesPage()),
                  ),
                  child: const Icon(Icons.map_outlined),
                )
              : null,
          bottomNavigationBar: wide
              ? null
              : StreamBuilder<Profile>(
                  stream: _me,
                  builder: (context, s) => HeritageNavigation(
                    index: _index,
                    onChanged: _select,
                    avatar: s.data?.photo ?? '',
                  ),
                ),
        );
      },
    );
  }
}
