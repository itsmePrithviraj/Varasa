import 'package:flutter/material.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/paged_list.dart';
import '../../domain/models.dart';
import 'post_card.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});
  @override
  State<FeedPage> createState() => FeedPageState();
}

class FeedPageState extends State<FeedPage> {
  String _kind = 'community';
  GlobalKey<PagedListState<HeritagePost>> _list = GlobalKey();
  Future<void> refresh() async {
    await _list.currentState?.refresh();
  }

  @override
  Widget build(BuildContext context) => ContentWidth(
    child: PagedList<HeritagePost>(
      key: _list,
      showRefresh: MediaQuery.sizeOf(context).width >= 900,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
      load: (cursor) =>
          RepositoryScope.of(context).fetchPosts(kind: _kind, cursor: cursor),
      itemId: (p) => p.id,
      itemBuilder: (_, p) => LivePostCard(key: ValueKey(p.id), initial: p),
      emptyTitle: _kind == 'following'
          ? 'Find your community'
          : 'Start a conversation',
      emptyMessage: _kind == 'following'
          ? 'Follow people to discover their stories. New stories may take a moment to appear.'
          : 'Share a tradition using Contribute.',
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: SegmentedButton<String>(
              showSelectedIcon: false,
              style: ButtonStyle(
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                backgroundColor: WidgetStateProperty.resolveWith(
                  (s) => s.contains(WidgetState.selected)
                      ? const Color(0xFF622A0F)
                      : Colors.white,
                ),
                foregroundColor: WidgetStateProperty.resolveWith(
                  (s) => s.contains(WidgetState.selected)
                      ? Colors.white
                      : const Color(0xFF622A0F),
                ),
              ),
              segments: const [
                ButtonSegment(value: 'community', label: Text('All Posts')),
                ButtonSegment(value: 'following', label: Text('Following')),
              ],
              selected: {_kind},
              onSelectionChanged: (selection) => setState(() {
                _kind = selection.first;
                _list = GlobalKey();
              }),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    ),
  );
}
