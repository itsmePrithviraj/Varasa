import 'dart:typed_data';
import 'models.dart';

/// All remote and demo behavior lives behind this boundary. Widgets never access Firestore.
abstract class VarasaRepository {
  bool get isDemo;
  String? get currentUserId;
  Stream<String?> watchSession();
  Future<void> signIn(String email, String password);
  Future<void> signUp(String name, String email, String password);
  Future<void> signInWithGoogle();
  Future<void> resetPassword(String email);
  Future<void> signOut();
  Future<void> ensureProfile();
  Stream<Profile> watchProfile(String id);
  Future<List<Profile>> searchPeople(String query);
  Future<void> updateProfile({
    required String name,
    required String username,
    required String bio,
    UploadFile? avatar,
    bool removeAvatar = false,
  });
  Future<void> setFollowing(String id, bool follow);
  Stream<HeritagePost?> watchPost(String id);
  Future<void> publish(PostDraft draft);
  Future<void> setLiked(HeritagePost post, bool liked);
  Future<void> deletePost(HeritagePost post);
  Future<void> addComment(String postId, String text);
  Future<CursorPage<HeritagePost>> fetchPosts({
    String kind = 'community',
    String? userId,
    String? cursor,
  });
  Future<CursorPage<PostComment>> fetchComments(
    String postId, {
    String? cursor,
  });
  Future<void> deleteComment(String postId, String commentId);
  Stream<SocialConnection> watchConnection(String userId);
  Future<CursorPage<Profile>> fetchPeople(
    String kind, {
    String? userId,
    String? cursor,
  });
  Future<void> friendAction(String userId, String action);
  Future<void> setBlocked(String userId, bool blocked);
  Future<void> reportContent({
    required String kind,
    required String targetId,
    String? postId,
    required String reason,
    String details = '',
  });
  Future<bool> isModerator();
  Future<CursorPage<Map<String, dynamic>>> fetchReports({String? cursor});
  Future<void> resolveReport(String reportId, String action, String note);
  Future<void> reauthenticate(String? password);
  bool get requiresPassword;
  Future<void> requestExport();
  Future<void> requestDeletion();
  Stream<List<AccountJob>> watchJobs();
  Future<CursorPage<Map<String, dynamic>>> fetchExportParts(
    String jobId, {
    String? cursor,
  });
  Future<Uint8List> readExportPart(String path);
  Future<void> retryJob(String jobId);
  Future<void> dispose();
}
