import 'package:cloud_functions/cloud_functions.dart';
import 'package:rxdart/rxdart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../core/config/app_config.dart';
import '../domain/models.dart';
import '../domain/varasa_repository.dart';

class FirebaseVarasaRepository extends VarasaRepository {
  FirebaseVarasaRepository({
    required FirebaseAuth auth,
    required FirebaseFirestore database,
    required FirebaseStorage storage,
    required FirebaseFunctions functions,
  }) : _auth = auth,
       _db = database,
       _storage = storage,
       _functions = functions;
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final FirebaseStorage _storage;
  final FirebaseFunctions _functions;
  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('profiles');
  CollectionReference<Map<String, dynamic>> get _posts =>
      _db.collection('stories');
  String get _uid =>
      _auth.currentUser?.uid ?? (throw StateError('Please sign in again.'));
  @override
  bool get isDemo => false;
  @override
  String? get currentUserId => _auth.currentUser?.uid;
  @override
  Stream<String?> watchSession() => _auth.authStateChanges().map((u) => u?.uid);
  @override
  Future<void> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  @override
  Future<void> signUp(String name, String email, String password) async {
    final result = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await result.user!.updateDisplayName(name.trim());
    await ensureProfile();
    final p = await _users.doc(_uid).get();
    await _call('updateProfile', {
      'name': name.trim(),
      'username': p.data()!['username'],
      'bio': '',
    });
  }

  @override
  Future<void> signInWithGoogle() async {
    if (AppConfig.useEmulators) {
      throw const FormatException(
        'Use email and password with the local backend emulators.',
      );
    }
    if (!kIsWeb &&
        defaultTargetPlatform == TargetPlatform.iOS &&
        const String.fromEnvironment('FIREBASE_IOS_CLIENT_ID').isEmpty) {
      throw const FormatException(
        'Google sign-in needs the iOS client ID and URL scheme. Follow docs/SETUP.md.',
      );
    }
    if (!kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android &&
        AppConfig.googleServerClientId.isEmpty) {
      throw const FormatException(
        'Google sign-in needs GOOGLE_SERVER_CLIENT_ID. Follow docs/SETUP.md.',
      );
    }
    if (kIsWeb) {
      await _auth.signInWithPopup(GoogleAuthProvider());
    } else {
      final account = await GoogleSignIn(
        clientId: defaultTargetPlatform == TargetPlatform.iOS
            ? const String.fromEnvironment('FIREBASE_IOS_CLIENT_ID')
            : null,
        serverClientId: AppConfig.googleServerClientId.isEmpty
            ? null
            : AppConfig.googleServerClientId,
      ).signIn();
      if (account == null) return;
      final tokens = await account.authentication;
      await _auth.signInWithCredential(
        GoogleAuthProvider.credential(
          accessToken: tokens.accessToken,
          idToken: tokens.idToken,
        ),
      );
    }
    await ensureProfile();
  }

  @override
  Future<void> resetPassword(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());
  @override
  Future<void> signOut() => _auth.signOut();
  Map<String, dynamic> _map(Object? value) =>
      Map<String, dynamic>.from(value as Map);
  Future<Map<String, dynamic>> _call(
    String name, [
    Map<String, dynamic> data = const {},
  ]) async {
    final result = await _functions.httpsCallable(name).call<Object?>(data);
    return _map(result.data);
  }

  HeritagePost _post(Map<String, dynamic> value) => HeritagePost.fromMap(
    value['id'] as String,
    value,
    date: value['createdAtMs'] is num
        ? DateTime.fromMillisecondsSinceEpoch(
            (value['createdAtMs'] as num).toInt(),
          )
        : null,
  );
  @override
  Future<void> ensureProfile() async {
    await _call('ensureProfile');
  }

  @override
  Stream<Profile> watchProfile(String id) =>
      _users.doc(id).snapshots().map((d) {
        if (!d.exists) throw StateError('This profile is no longer available.');
        return Profile.fromMap(d.id, d.data()!);
      });
  @override
  Future<List<Profile>> searchPeople(String query) async {
    if (query.trim().isEmpty) return [];
    final result = await _call('searchPeople', {'query': query.trim()});
    return (result['items'] as List).map((v) {
      final m = _map(v);
      return Profile.fromMap(m['id'] as String, m);
    }).toList();
  }

  @override
  Future<void> updateProfile({
    required String name,
    required String username,
    required String bio,
    UploadFile? avatar,
    bool removeAvatar = false,
  }) async {
    if (avatar != null && removeAvatar) {
      throw const FormatException('Choose or remove the photo, not both.');
    }
    avatar?.validate(imagesOnly: true, maxBytes: 3 * 1024 * 1024);
    Reference? uploaded;
    try {
      final data = <String, dynamic>{
        'name': name.trim(),
        'username': username.trim().toLowerCase(),
        'bio': bio.trim(),
        'removeAvatar': removeAvatar,
      };
      if (avatar != null) {
        uploaded = _storage.ref('avatars/$_uid/${_users.doc().id}');
        await uploaded.putData(
          avatar.bytes,
          SettableMetadata(contentType: avatar.contentType),
        );
        data.addAll({
          'avatarPath': uploaded.fullPath,
          'avatarUrl': await uploaded.getDownloadURL(),
        });
      }
      await _call('updateProfile', data);
    } catch (_) {
      // An uncertain transport failure may follow a successful server write.
      // Leave the object for the trusted orphan sweeper instead of deleting an in-use avatar.
      rethrow;
    }
  }

  @override
  Future<void> setFollowing(String id, bool follow) async {
    await _call('setFollowing', {'userId': id, 'follow': follow});
  }

  @override
  Future<CursorPage<HeritagePost>> fetchPosts({
    String kind = 'community',
    String? userId,
    String? cursor,
  }) async {
    final result = await _call('feedPage', {
      'kind': kind,
      'userId': userId,
      'cursor': cursor,
    });
    return CursorPage(
      (result['items'] as List).map((v) => _post(_map(v))).toList(),
      result['cursor'] as String?,
    );
  }

  @override
  Stream<HeritagePost?> watchPost(String id) => Rx.combineLatest2(
    _posts.doc(id).snapshots(),
    _posts.doc(id).collection('likes').doc(_uid).snapshots(),
    (
      DocumentSnapshot<Map<String, dynamic>> post,
      DocumentSnapshot<Map<String, dynamic>> like,
    ) {
      final value = post.data();
      if (value == null ||
          value['deleted'] == true ||
          value['moderated'] == true) {
        return null;
      }
      return _post({'id': post.id, ...value, 'liked': like.exists});
    },
  );
  PostDraft? _pendingDraft;
  String? _pendingPostId, _pendingFileUrl;
  bool _sameDraft(PostDraft a, PostDraft b) =>
      a.caption == b.caption &&
      a.place == b.place &&
      a.latitude == b.latitude &&
      a.longitude == b.longitude &&
      identical(a.file, b.file);
  @override
  Future<void> publish(PostDraft draft) async {
    draft.validate();
    if (_pendingDraft == null || !_sameDraft(_pendingDraft!, draft)) {
      _pendingDraft = draft;
      _pendingPostId = _posts.doc().id;
      _pendingFileUrl = null;
    }
    final id = _pendingPostId!;
    String url = '', path = '';
    if (draft.file != null) {
      final file = draft.file!,
          ref = _storage.ref('posts/$_uid/$id/attachment');
      if (_pendingFileUrl == null) {
        // A previous timed-out upload may already exist; never overwrite it.
        try {
          _pendingFileUrl = await ref.getDownloadURL();
        } on FirebaseException catch (e) {
          if (e.code != 'object-not-found') rethrow;
        }
        if (_pendingFileUrl == null) {
          await ref.putData(
            file.bytes,
            SettableMetadata(contentType: file.contentType),
          );
          _pendingFileUrl = await ref.getDownloadURL();
        }
      }
      url = _pendingFileUrl!;
      path = ref.fullPath;
    }
    await _call('publish', {
      'id': id,
      'caption': draft.caption.trim(),
      'place': draft.place.trim(),
      'latitude': draft.latitude,
      'longitude': draft.longitude,
      'storagePath': path,
      'fileUrl': url,
      'attachmentName': draft.file?.name ?? '',
    });
    _pendingDraft = null;
    _pendingPostId = null;
    _pendingFileUrl = null;
    // Failed/uncertain uploads are reconciled by the server's grace-period sweeper.
  }

  @override
  Future<void> setLiked(HeritagePost post, bool liked) async {
    await _call('setLiked', {'postId': post.id, 'liked': liked});
  }

  @override
  Future<void> deletePost(HeritagePost post) async {
    await _call('deletePost', {'postId': post.id});
  }

  @override
  Future<CursorPage<PostComment>> fetchComments(
    String postId, {
    String? cursor,
  }) async {
    final result = await _call('commentsPage', {
      'postId': postId,
      'cursor': cursor,
    });
    return CursorPage(
      (result['items'] as List).map((v) {
        final m = _map(v);
        return PostComment(
          id: m['id'] as String,
          userId: m['userId'] as String,
          name: m['username'] as String,
          text: m['text'] as String,
        );
      }).toList(),
      result['cursor'] as String?,
    );
  }

  @override
  Future<void> addComment(String postId, String text) async {
    await _call('addComment', {'postId': postId, 'text': text.trim()});
  }

  @override
  Future<void> deleteComment(String postId, String commentId) async {
    await _call('deleteComment', {'postId': postId, 'commentId': commentId});
  }

  @override
  Stream<SocialConnection> watchConnection(String id) => Rx.combineLatest5(
    _users.doc(_uid).collection('following').doc(id).snapshots(),
    _users.doc(_uid).collection('friends').doc(id).snapshots(),
    _users.doc(_uid).collection('outgoing').doc(id).snapshots(),
    _users.doc(_uid).collection('incoming').doc(id).snapshots(),
    _db.doc('accounts/$_uid/blocks/$id').snapshots(),
    (
      DocumentSnapshot a,
      DocumentSnapshot b,
      DocumentSnapshot c,
      DocumentSnapshot d,
      DocumentSnapshot e,
    ) => SocialConnection(
      following: a.exists,
      friends: b.exists,
      sent: c.exists,
      received: d.exists,
      blocked: e.exists,
    ),
  );
  @override
  Future<CursorPage<Profile>> fetchPeople(
    String kind, {
    String? userId,
    String? cursor,
  }) async {
    final result = await _call('peoplePage', {
      'kind': kind,
      'userId': userId,
      'cursor': cursor,
    });
    return CursorPage(
      (result['items'] as List).map((v) {
        final m = _map(v);
        return Profile.fromMap(m['id'] as String, m);
      }).toList(),
      result['cursor'] as String?,
    );
  }

  @override
  Future<void> friendAction(String userId, String action) async {
    await _call('friendship', {'userId': userId, 'action': action});
  }

  @override
  Future<void> setBlocked(String userId, bool blocked) async {
    await _call('setBlocked', {'userId': userId, 'blocked': blocked});
  }

  @override
  Future<void> reportContent({
    required String kind,
    required String targetId,
    String? postId,
    required String reason,
    String details = '',
  }) async {
    await _call('report', {
      'kind': kind,
      'targetId': targetId,
      'postId': postId,
      'reason': reason,
      'details': details,
    });
  }

  @override
  Future<bool> isModerator() async =>
      (await _auth.currentUser?.getIdTokenResult())?.claims?['moderator'] ==
      true;
  @override
  Future<CursorPage<Map<String, dynamic>>> fetchReports({
    String? cursor,
  }) async {
    final result = await _call('moderationPage', {'cursor': cursor});
    return CursorPage(
      (result['items'] as List).map(_map).toList(),
      result['cursor'] as String?,
    );
  }

  @override
  Future<void> resolveReport(
    String reportId,
    String action,
    String note,
  ) async {
    await _call('resolveReport', {
      'reportId': reportId,
      'action': action,
      'note': note,
    });
  }

  @override
  bool get requiresPassword =>
      _auth.currentUser?.providerData.any((p) => p.providerId == 'password') ??
      false;
  @override
  Future<void> reauthenticate(String? password) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Please sign in again.');
    if (requiresPassword) {
      if (password == null || password.isEmpty) {
        throw const FormatException('Enter your current password.');
      }
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: user.email!, password: password),
      );
    } else if (kIsWeb) {
      await user.reauthenticateWithPopup(GoogleAuthProvider());
    } else {
      final google = await GoogleSignIn(
        clientId: defaultTargetPlatform == TargetPlatform.iOS
            ? const String.fromEnvironment('FIREBASE_IOS_CLIENT_ID')
            : null,
        serverClientId: AppConfig.googleServerClientId.isEmpty
            ? null
            : AppConfig.googleServerClientId,
      ).signIn();
      if (google == null) throw StateError('Verification cancelled.');
      final tokens = await google.authentication;
      await user.reauthenticateWithCredential(
        GoogleAuthProvider.credential(
          accessToken: tokens.accessToken,
          idToken: tokens.idToken,
        ),
      );
    }
    await user.getIdToken(true);
  }

  @override
  Future<void> requestExport() async {
    await _call('requestExport');
  }

  @override
  Future<void> requestDeletion() async {
    await _call('requestDeletion');
    await _auth.signOut();
  }

  @override
  Stream<List<AccountJob>> watchJobs() => _db
      .collection('maintenanceJobs')
      .where('uid', isEqualTo: _uid)
      .orderBy('createdAtMs', descending: true)
      .limit(20)
      .snapshots()
      .map(
        (s) => s.docs.map((d) => AccountJob.fromMap(d.id, d.data())).toList(),
      );
  @override
  Future<CursorPage<Map<String, dynamic>>> fetchExportParts(
    String jobId, {
    String? cursor,
  }) async {
    final result = await _call('exportParts', {
      'jobId': jobId,
      'cursor': cursor,
    });
    return CursorPage(
      (result['items'] as List).map(_map).toList(),
      result['cursor'] as String?,
    );
  }

  @override
  Future<Uint8List> readExportPart(String path) async {
    if (!path.startsWith('exports/$_uid/')) {
      throw StateError('This export belongs to another account.');
    }
    final data = await _storage.ref(path).getData(20 * 1024 * 1024);
    return data ??
        (throw StateError('This export has expired. Request a new one.'));
  }

  @override
  Future<void> retryJob(String jobId) async {
    await _call('retryJob', {'jobId': jobId});
  }

  @override
  Future<void> dispose() async {}
}
