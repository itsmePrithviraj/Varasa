import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import '../domain/models.dart';
import '../domain/varasa_repository.dart';

/// Session-only sample data. Never reads or writes a Firebase project.
class DemoVarasaRepository extends VarasaRepository {
  final _changes = StreamController<void>.broadcast();
  final _session = StreamController<String?>.broadcast();
  String? _current = 'demo-you';
  final _profiles = <String, Profile>{
    'demo-you': const Profile(
      id: 'demo-you',
      name: 'Your Varasa',
      username: 'you',
      bio: 'A place for the traditions we carry forward.',
    ),
    'demo-meera': const Profile(
      id: 'demo-meera',
      name: 'Meera · Sample profile',
      username: 'meera',
      bio: 'Finding stories in the everyday.',
    ),
    'demo-arjun': const Profile(
      id: 'demo-arjun',
      name: 'Arjun · Sample profile',
      username: 'arjun',
      bio: 'Folk games, old memories and new friends.',
    ),
  };
  final _posts = <HeritagePost>[
    HeritagePost(
      id: 'demo-warli',
      userId: 'demo-meera',
      username: 'meera',
      caption:
          'Every line carries a story. What traditions have been passed down in your family?',
      image: 'assets/Warli.png',
      place: 'Maharashtra',
      latitude: 19.7515,
      longitude: 75.7139,
      createdAt: DateTime(2026, 1, 2),
    ),
    HeritagePost(
      id: 'demo-games',
      userId: 'demo-arjun',
      username: 'arjun',
      caption:
          'A board, a few shells, and an afternoon together. Rediscover Challas Aath in Forgotten Gems.',
      image: 'assets/challas_aath.png',
      createdAt: DateTime(2026, 1, 1),
    ),
  ];
  final _comments = <String, List<PostComment>>{};
  final _blocks = <String>{};
  final _friends = <String>{};
  final _sent = <String>{};
  final _received = <String>{'demo-arjun'};
  final _suspended = <String>{};
  final _reports = <Map<String, dynamic>>[];
  final _jobs = <AccountJob>[];
  final _exports = <String, Uint8List>{};
  bool _visible(String uid) =>
      !_blocks.contains(uid) && !_suspended.contains(uid);
  int _sequence = 0;
  String get _uid =>
      _current ?? (throw StateError('Please enter the demo again.'));
  @override
  bool get isDemo => true;
  @override
  String? get currentUserId => _current;
  @override
  Stream<String?> watchSession() async* {
    yield _current;
    yield* _session.stream;
  }

  Stream<T> _watch<T>(T Function() read) => Stream<T>.multi((controller) {
    void emit() {
      try {
        controller.add(read());
      } catch (e, stack) {
        controller.addError(e, stack);
      }
    }

    emit();
    final sub = _changes.stream.listen(
      (_) => emit(),
      onError: controller.addError,
    );
    controller.onCancel = sub.cancel;
  }, isBroadcast: true);

  @override
  Future<void> signIn(String email, String password) async {
    _current = 'demo-you';
    _profiles.putIfAbsent(
      'demo-you',
      () => const Profile(id: 'demo-you', name: 'Your Varasa', username: 'you'),
    );
    _session.add(_current);
  }

  @override
  Future<void> signUp(String name, String email, String password) =>
      signIn(email, password);
  @override
  Future<void> signInWithGoogle() => signIn('', '');
  @override
  Future<void> resetPassword(String email) async {}
  @override
  Future<void> signOut() async {
    _current = null;
    _session.add(null);
  }

  @override
  Future<void> ensureProfile() async {}
  @override
  Stream<Profile> watchProfile(String id) => _watch(() {
    final p = _profiles[id];
    if (p == null || (id != _uid && !_visible(id))) {
      throw StateError('Profile unavailable.');
    }
    return Profile.fromMap(id, {
      ...p.toMap(),
      'suspended': _suspended.contains(id),
      'friendsCount': id == _uid
          ? _friends.length
          : (_friends.contains(id) ? 1 : 0),
    });
  });
  @override
  Future<List<Profile>> searchPeople(String query) async => _profiles.values
      .where(
        (p) =>
            _visible(p.id) && p.username.startsWith(query.trim().toLowerCase()),
      )
      .take(20)
      .toList();
  @override
  Future<void> updateProfile({
    required String name,
    required String username,
    required String bio,
    UploadFile? avatar,
    bool removeAvatar = false,
  }) async {
    final handle = username.trim().toLowerCase();
    if (name.trim().isEmpty ||
        name.length > 80 ||
        !RegExp(r'^[a-z0-9_]{3,30}$').hasMatch(handle) ||
        bio.length > 300) {
      throw const FormatException('Check your name, username and bio lengths.');
    }
    if (avatar != null && removeAvatar) {
      throw const FormatException('Choose or remove the photo, not both.');
    }
    avatar?.validate(imagesOnly: true, maxBytes: 3 * 1024 * 1024);
    if (_profiles.values.any((p) => p.id != _uid && p.username == handle)) {
      throw const FormatException('That username is already taken.');
    }
    final p = _profiles[_uid]!;
    _profiles[_uid] = Profile(
      id: p.id,
      name: name.trim(),
      username: handle,
      bio: bio.trim(),
      photo: avatar != null
          ? 'data:${avatar.contentType};base64,${base64Encode(avatar.bytes)}'
          : removeAvatar
          ? ''
          : p.photo,
      avatarPath: p.avatarPath,
      following: p.following,
      followers: p.followers,
    );
    _changes.add(null);
  }

  @override
  Future<void> setFollowing(String id, bool follow) async {
    if (id == _uid || !_profiles.containsKey(id)) return;
    if (follow && !_visible(id)) {
      throw StateError('This member is unavailable.');
    }
    final me = _profiles[_uid]!, other = _profiles[id]!;
    final following = {...me.following}, followers = {...other.followers};
    if (follow) {
      following.add(id);
      followers.add(_uid);
    } else {
      following.remove(id);
      followers.remove(_uid);
    }
    _profiles[_uid] = Profile.fromMap(_uid, {
      ...me.toMap(),
      'following': following.toList(),
    });
    _profiles[id] = Profile.fromMap(id, {
      ...other.toMap(),
      'followers': followers.toList(),
    });
    _changes.add(null);
  }

  @override
  Stream<HeritagePost?> watchPost(String id) => _watch(() {
    for (final post in _posts) {
      if (post.id == id && _visible(post.userId)) return post;
    }
    return null;
  });
  @override
  Future<void> publish(PostDraft draft) async {
    draft.validate();
    final p = _profiles[_uid]!;
    final file = draft.file;
    final data = file == null
        ? ''
        : 'data:${file.contentType};base64,${base64Encode(file.bytes)}';
    _posts.insert(
      0,
      HeritagePost(
        id: 'local-${++_sequence}',
        userId: _uid,
        username: p.username,
        photo: p.photo,
        caption: draft.caption.trim(),
        createdAt: DateTime.now(),
        image: file?.isImage == true ? data : '',
        attachmentUrl: file?.isImage == false ? data : '',
        attachmentName: file?.name ?? '',
        place: draft.place.trim(),
        latitude: draft.latitude,
        longitude: draft.longitude,
      ),
    );
    _changes.add(null);
  }

  @override
  Future<void> setLiked(HeritagePost post, bool liked) async {
    final index = _posts.indexWhere((p) => p.id == post.id);
    if (index < 0) return;
    final current = _posts[index];
    final likes = {...current.likes};
    if (liked) {
      likes.add(_uid);
    } else {
      likes.remove(_uid);
    }
    _posts[index] = HeritagePost.fromMap(current.id, {
      ...current.toMap(),
      'likes': likes.toList(),
    }, date: current.createdAt);
    _changes.add(null);
  }

  @override
  Future<void> deletePost(HeritagePost post) async {
    if (post.userId != _uid) {
      throw StateError('Only the author can delete this story.');
    }
    _posts.removeWhere((p) => p.id == post.id);
    _comments.remove(post.id);
    _changes.add(null);
  }

  @override
  Future<void> addComment(String postId, String text) async {
    if (text.trim().isEmpty || text.trim().length > 1000) {
      throw const FormatException('Write 1–1,000 characters.');
    }
    if (!_posts.any((p) => p.id == postId && _visible(p.userId))) {
      throw StateError('Story unavailable.');
    }
    (_comments[postId] ??= []).add(
      PostComment(
        id: 'comment-${++_sequence}',
        userId: _uid,
        name: _profiles[_uid]!.username,
        text: text.trim(),
      ),
    );
    _changes.add(null);
  }

  CursorPage<T> _idsPage<T>(
    List<T> items,
    String? cursor,
    String Function(T) key,
  ) {
    items.sort((a, b) => key(a).compareTo(key(b)));
    final after = items
        .where((item) => cursor == null || key(item).compareTo(cursor) > 0)
        .take(21)
        .toList();
    return CursorPage(
      after.take(20).toList(),
      after.length > 20 ? key(after[19]) : null,
    );
  }

  @override
  Future<CursorPage<HeritagePost>> fetchPosts({
    String kind = 'community',
    String? userId,
    String? cursor,
  }) async {
    final all = _posts
        .where(
          (p) =>
              _visible(p.userId) &&
              (kind != 'profile' || p.userId == (userId ?? _uid)) &&
              (kind != 'following' ||
                  _profiles[_uid]!.following.contains(p.userId)),
        )
        .toList();
    int compare(HeritagePost a, HeritagePost b) {
      final time = (b.createdAt?.millisecondsSinceEpoch ?? 0).compareTo(
        a.createdAt?.millisecondsSinceEpoch ?? 0,
      );
      return time != 0 ? time : b.id.compareTo(a.id);
    }

    all.sort(compare);
    List<HeritagePost> after = all;
    if (cursor != null) {
      final c =
          jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(cursor))))
              as List;
      final marker = HeritagePost(
        id: c[1] as String,
        userId: '',
        username: '',
        caption: '',
        createdAt: DateTime.fromMillisecondsSinceEpoch(c[0] as int),
      );
      after = all.where((p) => compare(p, marker) > 0).toList();
    }
    final visible = after.take(20).toList();
    return CursorPage(
      visible,
      after.length > 20
          ? base64Url.encode(
              utf8.encode(
                jsonEncode([
                  visible.last.createdAt?.millisecondsSinceEpoch ?? 0,
                  visible.last.id,
                ]),
              ),
            )
          : null,
    );
  }

  @override
  Future<CursorPage<PostComment>> fetchComments(
    String postId, {
    String? cursor,
  }) async {
    final comments = (_comments[postId] ?? []).reversed
        .where((c) => _visible(c.userId))
        .toList();
    final cutoff = cursor == null ? null : int.parse(cursor);
    final after = comments
        .where(
          (c) => cutoff == null || int.parse(c.id.split('-').last) < cutoff,
        )
        .take(21)
        .toList();
    return CursorPage(
      after.take(20).toList(),
      after.length > 20 ? after[19].id.split('-').last : null,
    );
  }

  @override
  Future<void> deleteComment(String postId, String commentId) async {
    final post = _posts.where((p) => p.id == postId).firstOrNull;
    final comment = (_comments[postId] ?? [])
        .where((c) => c.id == commentId)
        .firstOrNull;
    if (comment == null) return;
    if (comment.userId != _uid && post?.userId != _uid) {
      throw StateError('You cannot delete this comment.');
    }
    _comments[postId]?.removeWhere((c) => c.id == commentId);
    _changes.add(null);
  }

  @override
  Stream<SocialConnection> watchConnection(String userId) => _watch(
    () => SocialConnection(
      following: _profiles[_uid]?.following.contains(userId) ?? false,
      friends: _friends.contains(userId),
      sent: _sent.contains(userId),
      received: _received.contains(userId),
      blocked: _blocks.contains(userId),
    ),
  );
  @override
  Future<CursorPage<Profile>> fetchPeople(
    String kind, {
    String? userId,
    String? cursor,
  }) async {
    final p = _profiles[userId ?? _uid]!;
    final ids = switch (kind) {
      'followers' => p.followers,
      'following' => p.following,
      'friends' =>
        p.id == _uid
            ? _friends.toList()
            : (_friends.contains(p.id) ? [_uid] : <String>[]),
      'incoming' => _received.toList(),
      'outgoing' => _sent.toList(),
      'blocks' => _blocks.toList(),
      _ => <String>[],
    };
    return _idsPage(
      ids
          .where(
            (id) =>
                _profiles.containsKey(id) && (kind == 'blocks' || _visible(id)),
          )
          .map((id) => _profiles[id]!)
          .toList(),
      cursor,
      (p) => p.id,
    );
  }

  @override
  Future<void> friendAction(String userId, String action) async {
    if (!_visible(userId) && ['send', 'accept'].contains(action)) {
      throw StateError('This member is unavailable.');
    }
    switch (action) {
      case 'send':
        if (_received.contains(userId)) {
          throw StateError('Accept the incoming request instead.');
        }
        _sent.add(userId);
      case 'accept':
        if (!_received.remove(userId)) {
          throw StateError('This request is no longer available.');
        }
        _sent.remove(userId);
        _friends.add(userId);
      case 'cancel':
        _sent.remove(userId);
      case 'decline':
        _received.remove(userId);
      case 'remove':
        _friends.remove(userId);
      default:
        throw StateError('Unknown friend action.');
    }
    _changes.add(null);
  }

  @override
  Future<void> setBlocked(String userId, bool blocked) async {
    if (blocked) {
      _blocks.add(userId);
      await setFollowing(userId, false);
      _friends.remove(userId);
      _sent.remove(userId);
      _received.remove(userId);
    } else {
      _blocks.remove(userId);
    }
    _changes.add(null);
  }

  @override
  Future<void> reportContent({
    required String kind,
    required String targetId,
    String? postId,
    required String reason,
    String details = '',
  }) async {
    if (_reports.any((r) => r['kind'] == kind && r['targetId'] == targetId)) {
      return;
    }
    _reports.add({
      'id': 'report-${++_sequence}',
      'kind': kind,
      'targetId': targetId,
      'postId': postId,
      'reason': reason,
      'details': details,
      'status': 'open',
      'preview': 'Local sample report',
    });
    _changes.add(null);
  }

  @override
  Future<bool> isModerator() async => true;
  @override
  Future<CursorPage<Map<String, dynamic>>> fetchReports({
    String? cursor,
  }) async => _idsPage(
    _reports.where((r) => r['status'] == 'open').toList(),
    cursor,
    (r) => r['id'] as String,
  );
  @override
  Future<void> resolveReport(
    String reportId,
    String action,
    String note,
  ) async {
    final report = _reports.firstWhere((r) => r['id'] == reportId);
    if (action == 'remove') {
      if (report['kind'] == 'story') {
        _posts.removeWhere((p) => p.id == report['targetId']);
        _comments.remove(report['targetId']);
      } else if (report['kind'] == 'comment') {
        _comments[report['postId']]?.removeWhere(
          (c) => c.id == report['targetId'],
        );
      } else {
        _suspended.add(report['targetId'] as String);
      }
    }
    report['status'] = action;
    _changes.add(null);
  }

  @override
  bool get requiresPassword => false;
  @override
  Future<void> reauthenticate(String? password) async {}
  @override
  Future<void> requestExport() async {
    final id = 'export-${++_sequence}', path = 'exports/$_uid/$id/account.json';
    _exports[path] = Uint8List.fromList(
      utf8.encode(
        jsonEncode({
          'demo': true,
          'profile': _profiles[_uid]!.toMap(),
          'stories': _posts
              .where((p) => p.userId == _uid)
              .map((p) => {'id': p.id, ...p.toMap()})
              .toList(),
          'friends': _friends.toList(),
          'blocks': _blocks.toList(),
          'comments': _comments.entries
              .expand(
                (e) => e.value
                    .where((c) => c.userId == _uid)
                    .map((c) => {'postId': e.key, 'text': c.text}),
              )
              .toList(),
        }),
      ),
    );
    _jobs.insert(0, AccountJob(id: id, type: 'export', status: 'complete'));
    _changes.add(null);
  }

  @override
  Future<void> requestDeletion() async {
    final uid = _uid;
    final authored = _posts
        .where((p) => p.userId == uid)
        .map((p) => p.id)
        .toList();
    for (final id in authored) {
      _comments.remove(id);
    }
    for (final p in _profiles.values.toList()) {
      _profiles[p.id] = Profile.fromMap(p.id, {
        ...p.toMap(),
        'following': p.following.where((id) => id != uid).toList(),
        'followers': p.followers.where((id) => id != uid).toList(),
      });
    }
    for (var i = 0; i < _posts.length; i++) {
      final p = _posts[i];
      _posts[i] = HeritagePost.fromMap(p.id, {
        ...p.toMap(),
        'likes': p.likes.where((id) => id != uid).toList(),
      }, date: p.createdAt);
    }
    _reports.clear();
    _posts.removeWhere((p) => p.userId == uid);
    for (final list in _comments.values) {
      list.removeWhere((c) => c.userId == uid);
    }
    _profiles.remove(uid);
    _blocks.clear();
    _friends.clear();
    _sent.clear();
    _received.clear();
    _jobs.clear();
    _exports.clear();
    await signOut();
    _changes.add(null);
  }

  @override
  Stream<List<AccountJob>> watchJobs() =>
      _watch(() => List.unmodifiable(_jobs));
  @override
  Future<CursorPage<Map<String, dynamic>>> fetchExportParts(
    String jobId, {
    String? cursor,
  }) async => CursorPage(
    _exports.keys
        .where((p) => p.contains('/$jobId/'))
        .map(
          (p) => <String, dynamic>{
            'id': 'account',
            'section': 'account',
            'path': p,
          },
        )
        .toList(),
    null,
  );
  @override
  Future<Uint8List> readExportPart(String path) async =>
      _exports[path] ?? (throw StateError('Export unavailable.'));
  @override
  Future<void> retryJob(String jobId) async {}

  @override
  Future<void> dispose() async {
    await _changes.close();
    await _session.close();
  }
}
