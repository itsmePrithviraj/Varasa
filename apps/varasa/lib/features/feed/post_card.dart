import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/widgets/common.dart';
import '../../domain/models.dart';
import '../profile/profile_page.dart';
import '../moderation/report_page.dart';
import 'post_detail_page.dart';

class LivePostCard extends StatefulWidget {
  const LivePostCard({super.key, required this.initial});
  final HeritagePost initial;
  @override
  State<LivePostCard> createState() => _LivePostCardState();
}

class _LivePostCardState extends State<LivePostCard> {
  Stream<HeritagePost?>? _stream;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _stream ??= RepositoryScope.of(context).watchPost(widget.initial.id);
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<HeritagePost?>(
    stream: _stream,
    builder: (context, s) {
      if (s.hasError) {
        return const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'This story is unavailable. Refresh to check for updates.',
          ),
        );
      }
      return s.connectionState == ConnectionState.waiting
          ? PostCard(post: widget.initial)
          : s.data == null
          ? const SizedBox.shrink()
          : PostCard(post: s.data!);
    },
  );
}

class PostCard extends StatefulWidget {
  const PostCard({super.key, required this.post, this.showComments = true});
  final HeritagePost post;
  final bool showComments;
  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool _busy = false;
  Future<void> _act(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.post,
        repo = RepositoryScope.of(context),
        liked = p.liked || p.likes.contains(repo.currentUserId);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9F2),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    alignment: Alignment.centerLeft,
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          ProfilePage(userId: p.userId, standalone: true),
                    ),
                  ),
                  icon: ProfileAvatar(source: p.photo, radius: 22),
                  label: Text(
                    p.username,
                    style: const TextStyle(fontFamily: 'Itim', fontSize: 18),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Story options',
                enabled: !_busy,
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: p.userId == repo.currentUserId ? 'delete' : 'report',
                    child: Text(
                      p.userId == repo.currentUserId
                          ? 'Delete story'
                          : 'Report story',
                    ),
                  ),
                ],
                onSelected: (action) async {
                  if (action == 'report') {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            ReportPage(kind: 'story', targetId: p.id),
                      ),
                    );
                    return;
                  }
                  final yes = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete this story?'),
                      content: const Text(
                        'It will be removed from the community and queued for permanent cleanup.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Keep story'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  if (yes == true && mounted) {
                    await _act(() => repo.deletePost(p));
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            p.caption,
            style: const TextStyle(
              fontFamily: 'Itim',
              fontSize: 17,
              height: 1.45,
              color: Color(0xFF33251E),
            ),
          ),
          if (p.image.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 1.65,
                  child: HeritageImage(p.image),
                ),
              ),
            ),
          if (p.place.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                children: [
                  const Icon(Icons.place_outlined, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(p.place, style: const TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
          if (p.attachmentUrl.isNotEmpty)
            TextButton.icon(
              onPressed: () => openExternal(context, p.attachmentUrl),
              icon: const Icon(Icons.description_outlined),
              label: Text(
                p.attachmentName.isEmpty ? 'Open document' : p.attachmentName,
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                tooltip: liked ? 'Unlike story' : 'Like story',
                onPressed: _busy
                    ? null
                    : () => _act(() => repo.setLiked(p, !liked)),
                icon: Image.asset(
                  'assets/like.png',
                  width: 24,
                  height: 24,
                  color: liked
                      ? const Color(0xFF622A0F)
                      : const Color(0xFFD1A487),
                  excludeFromSemantics: true,
                ),
              ),
              Semantics(
                label: '${p.likeCount} likes',
                child: Text(
                  '${p.likeCount}',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              const SizedBox(width: 12),
              if (widget.showComments)
                IconButton(
                  tooltip: 'Discuss',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => PostDetailPage(postId: p.id),
                    ),
                  ),
                  icon: Image.asset(
                    'assets/comment.png',
                    width: 24,
                    height: 24,
                    excludeFromSemantics: true,
                  ),
                ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Share story',
                onPressed: _busy
                    ? null
                    : () => _act(() async {
                        final box = context.findRenderObject() as RenderBox?;
                        await Share.share(
                          '${p.caption}\n\nShared by @${p.username} on Varasa',
                          sharePositionOrigin: box == null
                              ? null
                              : box.localToGlobal(Offset.zero) & box.size,
                        );
                      }),
                icon: Image.asset(
                  'assets/share.png',
                  width: 24,
                  height: 24,
                  excludeFromSemantics: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
