import 'package:flutter/material.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/paged_list.dart';

class ModerationPage extends StatefulWidget {
  const ModerationPage({super.key});
  @override
  State<ModerationPage> createState() => _ModerationPageState();
}

class _ModerationPageState extends State<ModerationPage> {
  final _list = GlobalKey<PagedListState<Map<String, dynamic>>>();
  final _busy = <String>{};
  Future<void> _resolve(Map<String, dynamic> report, String action) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(
          action == 'dismiss'
              ? 'Dismiss this report?'
              : 'Remove reported content?',
        ),
        content: Text(
          report['kind'] == 'profile' && action == 'remove'
              ? 'This suspends the profile and hides its content. A trusted administrator can review reinstatement.'
              : 'The decision is recorded in the moderation log.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final id = report['id'] as String;
    setState(() => _busy.add(id));
    try {
      await RepositoryScope.of(
        context,
      ).resolveReport(id, action, 'Reviewed in moderation queue');
      if (mounted) await _list.currentState?.refresh();
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Moderation queue')),
    body: ContentWidth(
      child: PagedList<Map<String, dynamic>>(
        key: _list,
        load: (cursor) =>
            RepositoryScope.of(context).fetchReports(cursor: cursor),
        itemId: (r) => r['id'] as String,
        emptyTitle: 'No open reports',
        emptyMessage: 'New reports will appear here for review.',
        itemBuilder: (context, r) => Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${r['kind']} · ${r['reason']}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(r['displayName'] as String? ?? ''),
              Text(r['preview'] as String? ?? ''),
              if ((r['imageUrl'] as String? ?? '').isNotEmpty)
                HeritageImage(r['imageUrl'] as String, height: 200),
              if ((r['details'] as String? ?? '').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text('Reporter context: ${r['details']}'),
                ),
              Wrap(
                spacing: 12,
                children: [
                  OutlinedButton(
                    onPressed: _busy.contains(r['id'])
                        ? null
                        : () => _resolve(r, 'dismiss'),
                    child: const Text('Dismiss'),
                  ),
                  FilledButton(
                    onPressed: _busy.contains(r['id'])
                        ? null
                        : () => _resolve(r, 'remove'),
                    child: Text(
                      r['kind'] == 'profile'
                          ? 'Suspend profile'
                          : 'Remove content',
                    ),
                  ),
                ],
              ),
              const Divider(),
            ],
          ),
        ),
      ),
    ),
  );
}
