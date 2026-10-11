import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/paged_list.dart';
import '../../core/files/pick_upload.dart';
import '../../domain/models.dart';
import '../feed/post_detail_page.dart';
import '../account/account_page.dart';
import '../moderation/report_page.dart';
import '../moderation/moderation_page.dart';
import 'people_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.userId, this.standalone = false});
  final String userId;
  final bool standalone;
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Stream<Profile>? _profile;
  Stream<SocialConnection>? _connection;
  Future<bool>? _moderator;
  final _list = GlobalKey<PagedListState<HeritagePost>>();
  bool _busy = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repo = RepositoryScope.of(context);
    _profile ??= repo.watchProfile(widget.userId);
    _connection ??= repo.watchConnection(widget.userId);
    _moderator ??= repo.isModerator();
  }

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

  void _people(String kind, String title) => Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) =>
          PeoplePage(kind: kind, title: title, userId: widget.userId),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context),
        own = repo.currentUserId == widget.userId;
    final body = ContentWidth(
      child: StreamBuilder<Profile>(
        stream: _profile,
        builder: (context, s) => AsyncState(
          snapshot: s,
          builder: (p) => PagedList<HeritagePost>(
            key: _list,
            showRefresh: false,
            padding: EdgeInsets.zero,
            columns: 2,
            load: (cursor) =>
                repo.fetchPosts(kind: 'profile', userId: p.id, cursor: cursor),
            itemId: (post) => post.id,
            itemBuilder: (context, post) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Material(
                borderRadius: BorderRadius.circular(20),
                clipBehavior: Clip.antiAlias,
                color: const Color(0xFFFFEEDB),
                child: InkWell(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => PostDetailPage(postId: post.id),
                      ),
                    );
                    if (mounted) await _list.currentState?.refresh();
                  },
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: post.image.isNotEmpty
                        ? HeritageImage(post.image)
                        : Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  post.attachmentUrl.isEmpty
                                      ? Icons.auto_stories_outlined
                                      : Icons.description_outlined,
                                ),
                                const SizedBox(height: 8),
                                Expanded(
                                  child: Text(
                                    post.caption,
                                    maxLines: 5,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: 'Itim',
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
              ),
            ),
            headerBuilder: (loaded, hasMore, loading) => Column(
              children: [
                LayoutBuilder(
                  builder: (context, size) => Stack(
                    children: [
                      Positioned.fill(
                        child: Image.asset(
                          'assets/background2.png',
                          fit: BoxFit.fill,
                          excludeFromSemantics: true,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                if (widget.standalone) const BackButton(),
                                Image.asset(
                                  'assets/varasa_logo.png',
                                  height: 26,
                                ),
                                const Spacer(),
                                PopupMenuButton<String>(
                                  tooltip: 'Profile options',
                                  onSelected: (action) async {
                                    if (action == 'edit') {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute<void>(
                                          builder: (_) =>
                                              EditProfilePage(profile: p),
                                        ),
                                      );
                                    } else if (action == 'account') {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute<void>(
                                          builder: (_) => const AccountPage(),
                                        ),
                                      );
                                    } else if (action == 'logout') {
                                      await _act(repo.signOut);
                                    } else if (action == 'report') {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute<void>(
                                          builder: (_) => ReportPage(
                                            kind: 'profile',
                                            targetId: p.id,
                                          ),
                                        ),
                                      );
                                    } else if (action == 'block') {
                                      final yes = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text(
                                            'Block this member?',
                                          ),
                                          content: const Text(
                                            'Their stories will be hidden and your follows and friendship will be removed.',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx, false),
                                              child: const Text('Cancel'),
                                            ),
                                            FilledButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx, true),
                                              child: const Text('Block'),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (yes == true) {
                                        await _act(
                                          () => repo.setBlocked(p.id, true),
                                        );
                                        if (context.mounted &&
                                            widget.standalone) {
                                          Navigator.pop(context);
                                        }
                                      }
                                    }
                                  },
                                  itemBuilder: (_) => own
                                      ? const [
                                          PopupMenuItem(
                                            value: 'edit',
                                            child: Text('Edit profile'),
                                          ),
                                          PopupMenuItem(
                                            value: 'account',
                                            child: Text('Your account & data'),
                                          ),
                                          PopupMenuItem(
                                            value: 'logout',
                                            child: Text('Sign out'),
                                          ),
                                        ]
                                      : const [
                                          PopupMenuItem(
                                            value: 'report',
                                            child: Text('Report member'),
                                          ),
                                          PopupMenuItem(
                                            value: 'block',
                                            child: Text('Block member'),
                                          ),
                                        ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            SizedBox(
                              width: 122,
                              height: 122,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Image.asset(
                                    'assets/logo_pattern.png',
                                    width: 122,
                                    height: 122,
                                    excludeFromSemantics: true,
                                  ),
                                  ProfileAvatar(
                                    source: p.photo.isEmpty
                                        ? 'assets/profile_avatar.png'
                                        : p.photo,
                                    radius: 40,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              p.username,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(p.name),
                            if (p.bio.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  p.bio,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontFamily: 'Itim',
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 62),
                            Text(
                              loading && loaded == 0 ? '…' : '$loaded',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(hasMore || loading ? 'Posts loaded' : 'Posts'),
                            const SizedBox(height: 8),
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 18,
                              children: [
                                TextButton(
                                  onPressed: () =>
                                      _people('followers', 'Followers'),
                                  child: Text(
                                    '${p.followersCount}\nFollowers',
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      _people('following', 'Following'),
                                  child: Text(
                                    '${p.followingCount}\nFollowing',
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (own)
                              Wrap(
                                spacing: 12,
                                runSpacing: 8,
                                alignment: WrapAlignment.center,
                                children: [
                                  FilledButton.tonal(
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute<void>(
                                        builder: (_) =>
                                            EditProfilePage(profile: p),
                                      ),
                                    ),
                                    child: const Text('Edit profile'),
                                  ),
                                  FilledButton.tonal(
                                    onPressed: () => _act(() async {
                                      final box =
                                          context.findRenderObject()
                                              as RenderBox?;
                                      await Share.share(
                                        'Find @${p.username} on Varasa',
                                        sharePositionOrigin: box == null
                                            ? null
                                            : box.localToGlobal(Offset.zero) &
                                                  box.size,
                                      );
                                    }),
                                    child: const Text('Share profile'),
                                  ),
                                ],
                              )
                            else
                              StreamBuilder<SocialConnection>(
                                stream: _connection,
                                builder: (context, c) => AsyncState(
                                  snapshot: c,
                                  builder: (c) => Wrap(
                                    spacing: 12,
                                    runSpacing: 8,
                                    alignment: WrapAlignment.center,
                                    children: [
                                      FilledButton(
                                        onPressed: _busy || c.blocked
                                            ? null
                                            : () => _act(
                                                () => repo.setFollowing(
                                                  p.id,
                                                  !c.following,
                                                ),
                                              ),
                                        child: Text(
                                          c.following ? 'Unfollow' : 'Follow',
                                        ),
                                      ),
                                      OutlinedButton(
                                        onPressed: _busy || c.blocked
                                            ? null
                                            : () => _act(
                                                () => repo.friendAction(
                                                  p.id,
                                                  c.received
                                                      ? 'accept'
                                                      : c.friends
                                                      ? 'remove'
                                                      : c.sent
                                                      ? 'cancel'
                                                      : 'send',
                                                ),
                                              ),
                                        child: Text(
                                          c.received
                                              ? 'Accept request'
                                              : c.friends
                                              ? 'Remove friend'
                                              : c.sent
                                              ? 'Cancel request'
                                              : 'Add friend',
                                        ),
                                      ),
                                      if (c.received)
                                        TextButton(
                                          onPressed: _busy
                                              ? null
                                              : () => _act(
                                                  () => repo.friendAction(
                                                    p.id,
                                                    'decline',
                                                  ),
                                                ),
                                          child: const Text('Decline'),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (own)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: const Text('Community & account'),
                      children: [
                        ListTile(
                          title: Text('Friends (${p.friendTotal})'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _people('friends', 'Friends'),
                        ),
                        ListTile(
                          title: const Text('Friend requests'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _people('incoming', 'Friend requests'),
                        ),
                        ListTile(
                          title: const Text('Sent requests'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _people('outgoing', 'Sent requests'),
                        ),
                        ListTile(
                          title: const Text('Blocked members'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _people('blocks', 'Blocked members'),
                        ),
                        ListTile(
                          title: const Text('Your account & data'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => const AccountPage(),
                            ),
                          ),
                        ),
                        FutureBuilder<bool>(
                          future: _moderator,
                          builder: (context, s) => s.data == true
                              ? ListTile(
                                  title: Text(
                                    repo.isDemo
                                        ? 'Demo moderation queue'
                                        : 'Moderation queue',
                                  ),
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute<void>(
                                      builder: (_) => const ModerationPage(),
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          own ? 'Your contributions' : 'Contributions',
                          style: const TextStyle(
                            fontFamily: 'CormorantGaramond',
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Refresh contributions',
                        onPressed: () => _list.currentState?.refresh(),
                        icon: const Icon(Icons.refresh),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            emptyTitle: 'A story waiting to be told',
            emptyMessage: 'Contributions will appear here.',
          ),
        ),
      ),
    );
    return widget.standalone ? Scaffold(body: SafeArea(child: body)) : body;
  }
}

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key, required this.profile});
  final Profile profile;
  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.profile.name);
  late final _username = TextEditingController(text: widget.profile.username);
  late final _bio = TextEditingController(text: widget.profile.bio);
  UploadFile? _avatar;
  bool _removeAvatar = false, _busy = false;
  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _chooseAvatar() async {
    try {
      final file = await pickUploadFile(
        imagesOnly: true,
        maxBytes: 3 * 1024 * 1024,
      );
      if (!mounted || file == null) return;
      setState(() {
        _avatar = file;
        _removeAvatar = false;
      });
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await RepositoryScope.of(context).updateProfile(
        name: _name.text,
        username: _username.text,
        bio: _bio.text,
        avatar: _avatar,
        removeAvatar: _removeAvatar,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: ContentWidth(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: _avatar == null
                    ? ProfileAvatar(
                        source: _removeAvatar ? '' : widget.profile.photo,
                        radius: 44,
                      )
                    : ClipOval(
                        child: Image.memory(
                          _avatar!.bytes,
                          width: 88,
                          height: 88,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox.square(
                            dimension: 88,
                            child: Icon(Icons.broken_image_outlined),
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                children: [
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _chooseAvatar,
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: const Text('Choose photo'),
                  ),
                  if (_avatar != null ||
                      widget.profile.photo.isNotEmpty && !_removeAvatar)
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => setState(() {
                              _avatar = null;
                              _removeAvatar = true;
                            }),
                      child: const Text('Remove photo'),
                    ),
                ],
              ),
              const Text(
                'JPG, PNG or WebP · Up to 3 MB · Changes apply when you save',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _name,
                enabled: !_busy,
                maxLength: 80,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Enter your name.' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _username,
                enabled: !_busy,
                maxLength: 30,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  helperText: 'Use letters, numbers and underscores.',
                ),
                validator: (v) =>
                    !RegExp(
                      r'^[a-z0-9_]{3,30}$',
                    ).hasMatch(v?.trim().toLowerCase() ?? '')
                    ? 'Use 3–30 letters, numbers or underscores.'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bio,
                enabled: !_busy,
                maxLength: 300,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(labelText: 'Your story'),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _busy ? null : _save,
                child: Text(
                  _busy ? 'Saving… Keep this app open' : 'Save profile',
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
