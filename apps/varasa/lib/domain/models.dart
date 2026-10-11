import 'dart:typed_data';

class Profile {
  const Profile({
    required this.id,
    required this.name,
    required this.username,
    this.bio = '',
    this.photo = '',
    this.avatarPath = '',
    this.followerTotal,
    this.followingTotal,
    this.friendTotal = 0,
    this.suspended = false,
    this.following = const [],
    this.followers = const [],
  });
  final String id, name, username, bio, photo, avatarPath;
  final List<String> following, followers;
  final int? followerTotal, followingTotal;
  final int friendTotal;
  final bool suspended;
  int get followersCount => followerTotal ?? followers.length;
  int get followingCount => followingTotal ?? following.length;
  factory Profile.fromMap(String id, Map<String, dynamic> m) => Profile(
    id: id,
    name: m['displayName'] as String? ?? 'Varasa member',
    username: m['username'] as String? ?? '',
    bio: m['bio'] as String? ?? '',
    photo: m['photoUrl'] as String? ?? '',
    avatarPath: m['avatarPath'] as String? ?? '',
    followerTotal: (m['followersCount'] as num?)?.toInt(),
    followingTotal: (m['followingCount'] as num?)?.toInt(),
    friendTotal: (m['friendsCount'] as num?)?.toInt() ?? 0,
    suspended: m['suspended'] == true,
    following: List<String>.from(m['following'] as List? ?? []),
    followers: List<String>.from(m['followers'] as List? ?? []),
  );
  Map<String, dynamic> toMap() => {
    'displayName': name,
    'username': username,
    'username_lower': username.toLowerCase(),
    'bio': bio,
    'photoUrl': photo,
    'avatarPath': avatarPath,
    'following': following,
    'followers': followers,
  };
}

class HeritagePost {
  const HeritagePost({
    required this.id,
    required this.userId,
    required this.username,
    required this.caption,
    this.image = '',
    this.photo = '',
    this.createdAt,
    this.likes = const [],
    this.likeTotal,
    this.liked = false,
    this.place = '',
    this.latitude,
    this.longitude,
    this.attachmentName = '',
    this.attachmentUrl = '',
    this.storagePath = '',
    this.deleted = false,
  });
  final String id, userId, username, caption, image, photo, place;
  final String attachmentName, attachmentUrl, storagePath;
  final DateTime? createdAt;
  final List<String> likes;
  final double? latitude, longitude;
  final bool deleted, liked;
  final int? likeTotal;
  int get likeCount => likeTotal ?? likes.length;
  factory HeritagePost.fromMap(
    String id,
    Map<String, dynamic> m, {
    DateTime? date,
  }) => HeritagePost(
    id: id,
    userId: m['userId'] as String? ?? '',
    username: m['username'] as String? ?? 'Member',
    caption: m['caption'] as String? ?? '',
    image: m['imageUrl'] as String? ?? '',
    photo: m['photoUrl'] as String? ?? '',
    createdAt: date,
    likes: List<String>.from(m['likes'] as List? ?? []),
    likeTotal: (m['likeCount'] as num?)?.toInt(),
    liked: m['liked'] == true,
    place: m['place'] as String? ?? '',
    latitude: (m['latitude'] as num?)?.toDouble(),
    longitude: (m['longitude'] as num?)?.toDouble(),
    attachmentName: m['attachmentName'] as String? ?? '',
    attachmentUrl: m['attachmentUrl'] as String? ?? '',
    storagePath: m['storagePath'] as String? ?? '',
    deleted: m['deleted'] == true,
  );
  Map<String, dynamic> toMap() => {
    'userId': userId,
    'username': username,
    'caption': caption,
    'imageUrl': image,
    'photoUrl': photo,
    'likes': likes,
    'place': place,
    'latitude': latitude,
    'longitude': longitude,
    'attachmentName': attachmentName,
    'attachmentUrl': attachmentUrl,
    'storagePath': storagePath,
    'deleted': deleted,
  };
}

class PostComment {
  const PostComment({
    required this.id,
    required this.userId,
    required this.name,
    required this.text,
  });
  final String id, userId, name, text;
}

class UploadFile {
  const UploadFile({
    required this.name,
    required this.bytes,
    required this.contentType,
  });
  final String name, contentType;
  final Uint8List bytes;
  bool get isImage => contentType.startsWith('image/');
  void validate({bool imagesOnly = false, int maxBytes = 10 * 1024 * 1024}) {
    if (bytes.isEmpty ||
        bytes.length > maxBytes ||
        ![
          'image/jpeg',
          'image/png',
          'image/webp',
          if (!imagesOnly) 'application/pdf',
        ].contains(contentType)) {
      throw FormatException(
        'Choose ${imagesOnly ? 'a JPG, PNG or WebP image' : 'a JPG, PNG, WebP or PDF'} up to ${maxBytes ~/ (1024 * 1024)} MB.',
      );
    }
  }
}

class PostDraft {
  const PostDraft({
    required this.caption,
    this.file,
    this.place = '',
    this.latitude,
    this.longitude,
  });
  final String caption, place;
  final UploadFile? file;
  final double? latitude, longitude;
  void validate() {
    if (caption.trim().isEmpty || caption.trim().length > 3000) {
      throw const FormatException(
        'Write a story between 1 and 3,000 characters.',
      );
    }
    if (place.length > 120) {
      throw const FormatException('Keep the place name under 120 characters.');
    }
    if ((latitude == null) != (longitude == null) ||
        (latitude != null &&
            (!latitude!.isFinite || latitude! < -90 || latitude! > 90)) ||
        (longitude != null &&
            (!longitude!.isFinite || longitude! < -180 || longitude! > 180))) {
      throw const FormatException(
        'Enter both a valid latitude and longitude, or leave both empty.',
      );
    }
    if (file != null &&
        (file!.bytes.isEmpty ||
            file!.bytes.length > 10 * 1024 * 1024 ||
            ![
              'image/jpeg',
              'image/png',
              'image/webp',
              'application/pdf',
            ].contains(file!.contentType))) {
      throw const FormatException(
        'Choose a JPG, PNG, WebP or PDF up to 10 MB.',
      );
    }
  }
}

class CursorPage<T> {
  const CursorPage(this.items, this.cursor);
  final List<T> items;
  final String? cursor;
  bool get hasMore => cursor != null;
}

class SocialConnection {
  const SocialConnection({
    this.following = false,
    this.friends = false,
    this.sent = false,
    this.received = false,
    this.blocked = false,
  });
  final bool following, friends, sent, received, blocked;
}

class AccountJob {
  const AccountJob({
    required this.id,
    required this.type,
    required this.status,
    this.section = 0,
  });
  final String id, type, status;
  final int section;
  factory AccountJob.fromMap(String id, Map<String, dynamic> m) => AccountJob(
    id: id,
    type: m['type'] as String? ?? '',
    status: m['status'] as String? ?? '',
    section: (m['section'] as num?)?.toInt() ?? 0,
  );
}
