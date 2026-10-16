import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase_config.dart';

/// A community feed post, backed by the `community_posts` Supabase table.
class CommunityPost {
  CommunityPost({
    this.id,
    this.authorId,
    required this.name,
    required this.initials,
    required this.topic,
    required this.text,
    required this.likes,
    required this.comments,
    required this.createdAt,
    this.isQuestion = false,
  });

  final String? id;

  /// The posting user's id — null for posts made before ownership tracking
  /// was added, which nobody can delete anymore. Used to show the delete
  /// button only on the current user's own posts.
  final String? authorId;
  final String name;
  final String initials;
  final String topic;
  final String text;
  final int likes;
  final int comments;
  final DateTime createdAt;
  final bool isQuestion;

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  factory CommunityPost.fromRow(Map<String, dynamic> row) => CommunityPost(
    id: row['id'] as String,
    authorId: row['user_id'] as String?,
    name: row['author_name'] as String,
    initials: row['initials'] as String,
    topic: row['topic'] as String,
    text: row['body'] as String,
    likes: row['likes'] as int,
    comments: row['comments'] as int,
    createdAt: DateTime.parse(row['created_at'] as String),
    isQuestion: row['is_question'] as bool,
  );

  Map<String, dynamic> toRow() => {
    'author_name': name,
    'initials': initials,
    'topic': topic,
    'body': text,
    'is_question': isQuestion,
  };
}

class CommunityGroup {
  const CommunityGroup({
    required this.id,
    required this.name,
    required this.topic,
    required this.description,
    required this.memberCount,
  });

  final String id;
  final String name;
  final String topic;
  final String description;
  final int memberCount;

  factory CommunityGroup.fromRow(Map<String, dynamic> row) => CommunityGroup(
    id: row['id'] as String,
    name: row['name'] as String,
    topic: row['topic'] as String,
    description: row['description'] as String,
    memberCount: row['member_count'] as int,
  );
}

class CommunityMetrics {
  const CommunityMetrics({
    required this.memberCount,
    required this.postsToday,
    required this.myGroupCount,
  });

  final int memberCount;
  final int postsToday;
  final int myGroupCount;

  factory CommunityMetrics.fromRow(Map<String, dynamic> row) =>
      CommunityMetrics(
        memberCount: (row['member_count'] as num).toInt(),
        postsToday: (row['posts_today'] as num).toInt(),
        myGroupCount: (row['my_group_count'] as num).toInt(),
      );
}

class CommunityComment {
  const CommunityComment({
    required this.id,
    required this.authorName,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String authorName;
  final String body;
  final DateTime createdAt;

  factory CommunityComment.fromRow(Map<String, dynamic> row) =>
      CommunityComment(
        id: row['id'] as String,
        authorName: row['author_name'] as String,
        body: row['body'] as String,
        createdAt: DateTime.parse(row['created_at'] as String),
      );
}

/// Backs [CommunityPost] with Supabase: Create (post), Read (feed), Update
/// (like count), Delete (posts made this session — see community_screen.dart
/// for why deletion is limited to those).
class CommunityStore {
  CommunityStore._();

  static const String _table = 'community_posts';
  static SupabaseClient get _db => SupabaseConfig.client;

  static final ValueNotifier<List<CommunityPost>> posts =
      ValueNotifier<List<CommunityPost>>([]);
  static final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);
  static final ValueNotifier<List<CommunityGroup>> groups =
      ValueNotifier<List<CommunityGroup>>([]);
  static final ValueNotifier<Set<String>> joinedGroupIds =
      ValueNotifier<Set<String>>({});
  static final ValueNotifier<CommunityMetrics?> metrics =
      ValueNotifier<CommunityMetrics?>(null);

  static String get _userId {
    final id = _db.auth.currentUser?.id;
    if (id == null) throw StateError('You must be signed in to use Community.');
    return id;
  }

  /// The signed-in user's id, or null if signed out — used to tell whether
  /// a given post belongs to the current user.
  static String? get currentUserId => _db.auth.currentUser?.id;

  static Future<void> fetchAll() async {
    isLoading.value = true;
    try {
      final rows = await _db
          .from(_table)
          .select()
          .order('created_at', ascending: false);
      posts.value = rows.map(CommunityPost.fromRow).toList();
    } finally {
      isLoading.value = false;
    }
  }

  static Future<CommunityPost> add(CommunityPost draft) async {
    if (draft.text.trim().isEmpty || draft.text.trim().length > 500) {
      throw StateError('Post text must contain between 1 and 500 characters.');
    }
    if (draft.name.trim().isEmpty || draft.topic.trim().isEmpty) {
      throw StateError('Author and topic are required.');
    }
    final row = await _db
        .from(_table)
        .insert({...draft.toRow(), 'user_id': _userId})
        .select()
        .single();
    final created = CommunityPost.fromRow(row);
    posts.value = [created, ...posts.value];
    return created;
  }

  static Future<void> update(CommunityPost post) async {
    if (post.id == null || post.authorId != _userId) {
      throw StateError('You can only edit your own saved posts.');
    }
    if (post.text.trim().isEmpty || post.text.trim().length > 500) {
      throw StateError('Post text must contain between 1 and 500 characters.');
    }
    final row = await _db
        .from(_table)
        .update(post.toRow())
        .eq('id', post.id!)
        .eq('user_id', _userId)
        .select()
        .single();
    final saved = CommunityPost.fromRow(row);
    posts.value = [for (final p in posts.value) p.id == saved.id ? saved : p];
  }

  static Future<void> setLiked(CommunityPost post, bool liked) async {
    if (post.id == null) throw StateError('Cannot like an unsaved post.');
    if (liked) {
      await _db.from('community_post_likes').upsert({
        'post_id': post.id,
        'user_id': _userId,
      }, onConflict: 'post_id,user_id');
    } else {
      await _db
          .from('community_post_likes')
          .delete()
          .eq('post_id', post.id!)
          .eq('user_id', _userId);
    }
    final row = await _db.from(_table).select().eq('id', post.id!).single();
    final updated = CommunityPost.fromRow(row);
    posts.value = [
      for (final p in posts.value) p.id == updated.id ? updated : p,
    ];
  }

  static Future<Set<String>> fetchMyLikedPostIds() async {
    final rows = await _db
        .from('community_post_likes')
        .select('post_id')
        .eq('user_id', _userId);
    return rows.map((row) => row['post_id'] as String).toSet();
  }

  static Future<void> remove(String id) async {
    await _db.from(_table).delete().eq('id', id);
    posts.value = posts.value.where((p) => p.id != id).toList();
  }

  static Future<void> fetchCommunity() async {
    await Future.wait([fetchAll(), _fetchGroupsAndMetrics()]);
  }

  static Future<void> _fetchGroupsAndMetrics() async {
    final groupRows = await _db.from('community_groups').select().order('name');
    final membershipRows = await _db
        .from('group_memberships')
        .select('group_id')
        .eq('user_id', _userId);
    final rawMetrics = await _db.rpc('community_metrics');

    groups.value = groupRows.map(CommunityGroup.fromRow).toList();
    joinedGroupIds.value = membershipRows
        .map((row) => row['group_id'] as String)
        .toSet();
    metrics.value = CommunityMetrics.fromRow(
      Map<String, dynamic>.from(rawMetrics as Map),
    );
  }

  static Future<void> joinGroup(String groupId) async {
    await _db.from('group_memberships').upsert({
      'group_id': groupId,
      'user_id': _userId,
    }, onConflict: 'group_id,user_id');
    await _fetchGroupsAndMetrics();
  }

  static Future<List<CommunityComment>> fetchComments(String postId) async {
    final rows = await _db
        .from('community_comments')
        .select()
        .eq('post_id', postId)
        .order('created_at');
    return rows.map(CommunityComment.fromRow).toList();
  }

  static Future<void> addComment({
    required String postId,
    required String authorName,
    required String body,
  }) async {
    final trimmed = body.trim();
    if (trimmed.isEmpty || trimmed.length > 500) {
      throw StateError('Comment must contain between 1 and 500 characters.');
    }
    await _db.from('community_comments').insert({
      'post_id': postId,
      'user_id': _userId,
      'author_name': authorName,
      'body': trimmed,
    });
    await fetchAll();
  }
}
