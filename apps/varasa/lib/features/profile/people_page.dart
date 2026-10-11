import 'package:flutter/material.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/paged_list.dart';
import '../../domain/models.dart';
import 'profile_page.dart';

class PeoplePage extends StatefulWidget {
  const PeoplePage({
    super.key,
    required this.kind,
    required this.title,
    this.userId,
  });
  final String kind, title;
  final String? userId;
  @override
  State<PeoplePage> createState() => _PeoplePageState();
}

class _PeoplePageState extends State<PeoplePage> {
  final _list = GlobalKey<PagedListState<Profile>>();
  final _busy = <String>{};
  Future<void> _action(Profile p, String action) async {
    setState(() => _busy.add(p.id));
    try {
      final repo = RepositoryScope.of(context);
      if (action == 'unblock') {
        await repo.setBlocked(p.id, false);
      } else {
        await repo.friendAction(p.id, action);
      }
      if (mounted) await _list.currentState?.refresh();
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy.remove(p.id));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.title)),
    body: ContentWidth(
      child: PagedList<Profile>(
        key: _list,
        load: (cursor) => RepositoryScope.of(
          context,
        ).fetchPeople(widget.kind, userId: widget.userId, cursor: cursor),
        itemId: (p) => p.id,
        emptyTitle: 'No members here yet',
        emptyMessage: 'This list updates as your community grows.',
        itemBuilder: (context, p) => Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: ProfileAvatar(source: p.photo),
              title: Text(p.name),
              subtitle: Text('@${p.username}'),
              onTap: widget.kind == 'blocks'
                  ? null
                  : () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            ProfilePage(userId: p.id, standalone: true),
                      ),
                    ),
            ),
            Wrap(
              spacing: 8,
              children: [
                if (widget.kind == 'incoming') ...[
                  FilledButton(
                    onPressed: _busy.contains(p.id)
                        ? null
                        : () => _action(p, 'accept'),
                    child: const Text('Accept'),
                  ),
                  TextButton(
                    onPressed: _busy.contains(p.id)
                        ? null
                        : () => _action(p, 'decline'),
                    child: const Text('Decline'),
                  ),
                ],
                if (widget.kind == 'outgoing')
                  TextButton(
                    onPressed: _busy.contains(p.id)
                        ? null
                        : () => _action(p, 'cancel'),
                    child: const Text('Cancel request'),
                  ),
                if (widget.kind == 'blocks')
                  OutlinedButton(
                    onPressed: _busy.contains(p.id)
                        ? null
                        : () => _action(p, 'unblock'),
                    child: const Text('Unblock'),
                  ),
                if (widget.kind == 'friends' &&
                    (widget.userId == null ||
                        widget.userId ==
                            RepositoryScope.of(context).currentUserId))
                  TextButton(
                    onPressed: _busy.contains(p.id)
                        ? null
                        : () => _action(p, 'remove'),
                    child: const Text('Remove friend'),
                  ),
              ],
            ),
            const Divider(),
          ],
        ),
      ),
    ),
  );
}
