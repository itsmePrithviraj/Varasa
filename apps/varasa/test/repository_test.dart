import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:varasa/data/demo_repository.dart';
import 'package:varasa/domain/models.dart';

void main() {
  late DemoVarasaRepository repo;
  setUp(() => repo = DemoVarasaRepository());
  tearDown(() => repo.dispose());
  test(
    'cursor pagination survives deletion and reaches every story once',
    () async {
      for (var i = 0; i < 43; i++) {
        await repo.publish(PostDraft(caption: 'Story $i'));
      }
      final first = await repo.fetchPosts();
      expect(first.items, hasLength(20));
      expect(first.hasMore, isTrue);
      await repo.deletePost(first.items.last);
      final second = await repo.fetchPosts(cursor: first.cursor);
      final third = await repo.fetchPosts(cursor: second.cursor);
      final ids = [
        ...first.items,
        ...second.items,
        ...third.items,
      ].map((p) => p.id).toList();
      expect(ids.toSet().length, 45);
      expect(ids.length, 45);
      expect(third.hasMore, isFalse);
    },
  );
  test(
    'follows and likes are idempotent; blocks hide stories and remove relationships',
    () async {
      await repo.setFollowing('demo-meera', true);
      await repo.setFollowing('demo-meera', true);
      expect((await repo.watchProfile('demo-you').first).followingCount, 1);
      final post = (await repo.fetchPosts(kind: 'following')).items.single;
      await repo.setLiked(post, true);
      await repo.setLiked(post, true);
      expect((await repo.watchPost(post.id).first)!.likeCount, 1);
      await repo.setBlocked('demo-meera', true);
      expect((await repo.fetchPosts(kind: 'following')).items, isEmpty);
      expect(await repo.watchPost(post.id).first, isNull);
      expect(() => repo.setFollowing('demo-meera', true), throwsStateError);
    },
  );
  test(
    'friend acceptance, unique usernames and comments reject invalid transitions',
    () async {
      await repo.friendAction('demo-arjun', 'accept');
      expect((await repo.watchConnection('demo-arjun').first).friends, isTrue);
      expect((await repo.watchProfile('demo-you').first).friendTotal, 1);
      expect(() => repo.friendAction('demo-arjun', 'accept'), throwsStateError);
      expect(
        () => repo.updateProfile(name: 'Me', username: 'meera', bio: ''),
        throwsFormatException,
      );
      expect(() => repo.addComment('missing', 'Hello'), throwsStateError);
    },
  );
  test('comment cursor survives deleting the last item of a page', () async {
    for (var i = 0; i < 25; i++) {
      await repo.addComment('demo-warli', 'Comment $i');
    }
    final first = await repo.fetchComments('demo-warli');
    await repo.deleteComment('demo-warli', first.items.last.id);
    final second = await repo.fetchComments('demo-warli', cursor: first.cursor);
    expect(second.items.length, 5);
    expect(second.hasMore, isFalse);
    expect(
      {
        ...first.items.map((c) => c.id),
        ...second.items.map((c) => c.id),
      }.length,
      25,
    );
  });
  test(
    'moderation removes reported stories; export and deletion retain correct session boundary',
    () async {
      await repo.reportContent(
        kind: 'story',
        targetId: 'demo-warli',
        reason: 'Other',
      );
      final report = (await repo.fetchReports()).items.single;
      await repo.resolveReport(report['id'] as String, 'remove', 'Reviewed');
      expect(await repo.watchPost('demo-warli').first, isNull);
      await repo.publish(const PostDraft(caption: 'Keep my story'));
      await repo.requestExport();
      final job = (await repo.watchJobs().first).single;
      expect(job.status, 'complete');
      final part = (await repo.fetchExportParts(job.id)).items.single;
      final data =
          jsonDecode(
                utf8.decode(await repo.readExportPart(part['path'] as String)),
              )
              as Map;
      expect((data['stories'] as List).length, 1);
      await repo.requestDeletion();
      expect(repo.currentUserId, isNull);
      await repo.signIn('', '');
      expect((await repo.fetchPosts(kind: 'profile')).items, isEmpty);
    },
  );
  test(
    'draft and file validation reject unsupported types and partial or invalid coordinates',
    () {
      expect(
        () => const PostDraft(caption: 'Story', latitude: 10).validate(),
        throwsFormatException,
      );
      expect(
        () => const PostDraft(
          caption: 'Story',
          latitude: 91,
          longitude: 10,
        ).validate(),
        throwsFormatException,
      );
      expect(
        () => UploadFile(
          name: 'code.js',
          bytes: Uint8List.fromList([1]),
          contentType: 'text/javascript',
        ).validate(),
        throwsFormatException,
      );
    },
  );
}
