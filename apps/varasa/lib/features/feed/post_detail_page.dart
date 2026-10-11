import 'package:flutter/material.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/paged_list.dart';
import '../../domain/models.dart';
import '../moderation/report_page.dart';
import 'post_card.dart';

class PostDetailPage extends StatefulWidget {
  const PostDetailPage({super.key, required this.postId});
  final String postId;
  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final _comment = TextEditingController();
  final _list = GlobalKey<PagedListState<PostComment>>();
  Stream<HeritagePost?>? _post;
  bool _busy = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _post ??= RepositoryScope.of(context).watchPost(widget.postId);
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_comment.text.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      await RepositoryScope.of(
        context,
      ).addComment(widget.postId, _comment.text);
      if (!mounted) return;
      _comment.clear();
      await _list.currentState?.refresh();
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Around this story')),
      body: SafeArea(
        child: ContentWidth(
          child: StreamBuilder<HeritagePost?>(
            stream: _post,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return EmptyState(
                  title: 'Couldn’t load this story',
                  message: errorMessage(snapshot.error!),
                  action: OutlinedButton(
                    onPressed: () =>
                        setState(() => _post = repo.watchPost(widget.postId)),
                    child: const Text('Retry'),
                  ),
                );
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final post = snapshot.data;
              if (post == null) {
                return const EmptyState(
                  title: 'This story is no longer available',
                  message:
                      'It may have been removed or its author may be unavailable.',
                );
              }
              return Column(
                children: [
                  Expanded(
                    child: PagedList<PostComment>(
                      key: _list,
                      load: (cursor) =>
                          repo.fetchComments(widget.postId, cursor: cursor),
                      itemId: (c) => c.id,
                      header: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          PostCard(post: post, showComments: false),
                          const Text('Conversation · Newest first'),
                          const SizedBox(height: 12),
                        ],
                      ),
                      emptyTitle: 'Be part of the story',
                      emptyMessage:
                          'Share a memory or ask a thoughtful question.',
                      itemBuilder: (context, c) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('@${c.name}'),
                        subtitle: Text(c.text),
                        trailing: PopupMenuButton<String>(
                          tooltip: 'Comment actions',
                          onSelected: (action) async {
                            if (action == 'report') {
                              await Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) => ReportPage(
                                    kind: 'comment',
                                    targetId: c.id,
                                    postId: post.id,
                                  ),
                                ),
                              );
                              return;
                            }
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Remove this comment?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Cancel'),
                                  ),
                                  FilledButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Remove'),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed != true) return;
                            try {
                              await repo.deleteComment(post.id, c.id);
                              await _list.currentState?.refresh();
                            } catch (e) {
                              if (context.mounted) showError(context, e);
                            }
                          },
                          itemBuilder: (_) => [
                            if (c.userId == repo.currentUserId ||
                                post.userId == repo.currentUserId)
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Remove comment'),
                              ),
                            if (c.userId != repo.currentUserId)
                              const PopupMenuItem(
                                value: 'report',
                                child: Text('Report comment'),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _comment,
                            enabled: !_busy,
                            maxLength: 1000,
                            minLines: 1,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              labelText: 'Add to the conversation',
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Send comment',
                          onPressed: _busy ? null : _send,
                          icon: _busy
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.send_outlined),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
