import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../core/constants/app_constants.dart';
import '../core/enums/app_enums.dart';
import '../models/app_user.dart';
import '../models/item_post.dart';
import '../models/post_save_result.dart';
import '../services/firestore_service.dart';
import '../services/matching_service.dart';
import '../services/qr_service.dart';
import '../services/storage_service.dart';

class PostsRepository {
  PostsRepository(
    this._firestoreService,
    this._storageService,
    this._qrService,
    this._matchingService,
  );

  final FirestoreService _firestoreService;
  final StorageService _storageService;
  final QrService _qrService;
  final MatchingService _matchingService;
  final Uuid _uuid = const Uuid();

  Stream<List<ItemPost>> streamPosts({
    PostType? type,
    String? communityId,
    bool includeArchived = false,
  }) {
    return _firestoreService.posts.snapshots().map((snapshot) {
      final posts =
          snapshot.docs
              .map(ItemPost.fromSnapshot)
              .where((post) => includeArchived || !post.isArchived)
              .where((post) => type == null || post.type == type)
              .where(
                (post) =>
                    communityId == null || post.communityId == communityId,
              )
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return posts;
    });
  }

  Stream<ItemPost?> streamPost(String postId) {
    return _firestoreService.posts.doc(postId).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }
      return ItemPost.fromSnapshot(snapshot);
    });
  }

  Future<ItemPost?> getPost(String postId) async {
    final snapshot = await _firestoreService.posts.doc(postId).get();
    if (!snapshot.exists) {
      return null;
    }
    return ItemPost.fromSnapshot(snapshot);
  }

  Stream<List<ItemPost>> streamUserPosts(String userId) {
    return streamPosts().map(
      (posts) => posts.where((post) => post.userId == userId).toList(),
    );
  }

  Stream<List<ItemPost>> searchPosts({
    String query = '',
    String? category,
    PostType? type,
    PostStatus? status,
    String? communityId,
    String? locationQuery,
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    final normalizedLocation = locationQuery?.trim().toLowerCase() ?? '';

    return streamPosts().map((posts) {
      return posts.where((post) {
        final matchesQuery =
            normalizedQuery.isEmpty ||
            post.title.toLowerCase().contains(normalizedQuery) ||
            post.description.toLowerCase().contains(normalizedQuery) ||
            post.textTags.any((tag) => tag.contains(normalizedQuery));
        final matchesCategory =
            category == null ||
            category == 'All' ||
            AppConstants.displayCategory(post.category) ==
                AppConstants.displayCategory(category);
        final matchesType = type == null || post.type == type;
        final matchesStatus = status == null || post.status == status;
        final matchesCommunity =
            communityId == null ||
            communityId == 'all' ||
            post.communityId == communityId;
        final matchesLocation =
            normalizedLocation.isEmpty ||
            post.locationName.toLowerCase().contains(normalizedLocation);

        return matchesQuery &&
            matchesCategory &&
            matchesType &&
            matchesStatus &&
            matchesCommunity &&
            matchesLocation;
      }).toList();
    });
  }

  Stream<List<ItemPost>> matchSuggestions(ItemPost basePost) {
    return streamPosts(type: basePost.type.opposite).map((posts) {
      final matches =
          posts
              .where((candidate) => candidate.id != basePost.id)
              .where((candidate) => candidate.status != PostStatus.returned)
              .where((candidate) {
                final score = _matchingService.score(basePost, candidate);
                return _matchingService.isStrongMatch(score);
              })
              .toList()
            ..sort((a, b) {
              final left = _matchingService.score(basePost, a).score;
              final right = _matchingService.score(basePost, b).score;
              return right.compareTo(left);
            });

      return matches.take(6).toList();
    });
  }

  Future<PostSaveResult> createPost({
    required AppUser author,
    required PostType type,
    required String title,
    required String description,
    required String category,
    required String locationName,
    required double latitude,
    required double longitude,
    required String communityId,
    required List<String> imagePaths,
    required double rewardAmount,
    required bool isAnonymous,
    String? documentType,
    bool qrEnabled = true,
  }) async {
    final postId = _firestoreService.posts.doc().id;
    final metadata = await _matchingService.analyzeDraft(
      imagePaths: imagePaths,
      title: title,
      description: description,
      category: category,
      locationName: locationName,
      documentType: documentType,
    );
    final imageResult = await _resolveImageUrls(
      userId: author.id,
      postId: postId,
      imagePaths: imagePaths,
    );
    final itemCode = _qrService.generateItemCode(
      postId: postId,
      type: type.name,
    );
    final now = DateTime.now();
    final post = ItemPost(
      id: postId,
      itemCode: itemCode,
      userId: author.id,
      authorName: author.displayName,
      authorPhotoUrl: author.photoUrl,
      type: type,
      title: title.trim(),
      description: description.trim(),
      category: category,
      status: type == PostType.lost ? PostStatus.lost : PostStatus.found,
      locationName: locationName.trim(),
      latitude: latitude,
      longitude: longitude,
      imageUrls: imageResult.urls,
      createdAt: now,
      updatedAt: now,
      communityId: communityId,
      isVerified: false,
      trustScore: author.trustScore,
      matchedPostIds: const <String>[],
      qrCodeValue: _qrService.buildQrValue(itemCode),
      qrEnabled: qrEnabled,
      rewardAmount: rewardAmount,
      dominantColor: metadata.dominantColor,
      visualTags: metadata.visualTags,
      textTags: metadata.textTags,
      documentType: documentType,
      isPriorityDocument: metadata.isPriorityDocument,
      isAnonymous: isAnonymous,
    );

    await _firestoreService.posts.doc(postId).set(post.toMap());
    await _syncMatchesAndNotify(post);
    return PostSaveResult(
      postId: postId,
      uploadAttemptCount: imageResult.uploadAttemptCount,
      uploadSuccessCount: imageResult.uploadSuccessCount,
    );
  }

  Future<PostSaveResult> updatePost({
    required ItemPost existing,
    required String title,
    required String description,
    required String category,
    required String locationName,
    required double latitude,
    required double longitude,
    required String communityId,
    required List<String> imagePaths,
    required double rewardAmount,
    required bool isAnonymous,
    String? documentType,
  }) async {
    final metadata = await _matchingService.analyzeDraft(
      imagePaths: imagePaths,
      title: title,
      description: description,
      category: category,
      locationName: locationName,
      documentType: documentType,
    );
    final imageResult = await _resolveImageUrls(
      userId: existing.userId,
      postId: existing.id,
      imagePaths: imagePaths,
    );

    final updated = existing.copyWith(
      title: title.trim(),
      description: description.trim(),
      category: category,
      locationName: locationName.trim(),
      latitude: latitude,
      longitude: longitude,
      communityId: communityId,
      imageUrls: imageResult.urls,
      rewardAmount: rewardAmount,
      isAnonymous: isAnonymous,
      documentType: documentType,
      dominantColor: metadata.dominantColor,
      visualTags: metadata.visualTags,
      textTags: metadata.textTags,
      isPriorityDocument: metadata.isPriorityDocument,
      qrCodeValue: _qrService.buildQrValue(existing.itemCode),
      updatedAt: DateTime.now(),
    );

    await _firestoreService.posts.doc(existing.id).set(updated.toMap());
    await _syncMatchesAndNotify(updated);
    return PostSaveResult(
      postId: existing.id,
      uploadAttemptCount: imageResult.uploadAttemptCount,
      uploadSuccessCount: imageResult.uploadSuccessCount,
    );
  }

  Future<void> deletePost(ItemPost post) async {
    for (final imageUrl in post.imageUrls) {
      await _storageService.deleteByUrl(imageUrl);
    }

    final relatedMatches = await _firestoreService.matches
        .where('postIds', arrayContains: post.id)
        .get();
    final relatedClaims = await _firestoreService.claims
        .where('postId', isEqualTo: post.id)
        .get();
    final relatedReports = await _firestoreService.reports
        .where('postId', isEqualTo: post.id)
        .get();
    final relatedNotifications = await _firestoreService.notifications
        .where('referenceId', isEqualTo: post.id)
        .get();
    final relatedPickupSchedules = await _firestoreService.pickupSchedules
        .where('postId', isEqualTo: post.id)
        .get();
    final usersWithSavedPost = await _firestoreService.users
        .where('savedPostIds', arrayContains: post.id)
        .get();
    final postsWithMatchedReference = await _firestoreService.posts
        .where('matchedPostIds', arrayContains: post.id)
        .get();

    final batch = _firestoreService.firestore.batch();
    for (final doc in relatedMatches.docs) {
      batch.delete(doc.reference);
    }
    for (final doc in relatedClaims.docs) {
      batch.delete(doc.reference);
    }
    for (final doc in relatedReports.docs) {
      batch.delete(doc.reference);
    }
    for (final doc in relatedNotifications.docs) {
      batch.delete(doc.reference);
    }
    for (final doc in relatedPickupSchedules.docs) {
      batch.delete(doc.reference);
    }
    for (final doc in usersWithSavedPost.docs) {
      batch.update(doc.reference, <String, dynamic>{
        'savedPostIds': FieldValue.arrayRemove(<String>[post.id]),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    }
    for (final doc in postsWithMatchedReference.docs) {
      if (doc.id == post.id) {
        continue;
      }
      batch.update(doc.reference, <String, dynamic>{
        'matchedPostIds': FieldValue.arrayRemove(<String>[post.id]),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    }
    batch.delete(_firestoreService.posts.doc(post.id));
    await batch.commit();
  }

  Future<void> updateStatus({
    required String postId,
    required PostStatus status,
    String? notifyUserId,
  }) async {
    await _firestoreService.posts.doc(postId).set(<String, dynamic>{
      'status': status.value,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    }, SetOptions(merge: true));

    if (notifyUserId != null) {
      await _firestoreService.notifications.add(<String, dynamic>{
        'userId': notifyUserId,
        'title': 'Статус предмета обновлён',
        'body':
            'Объявление, за которым вы следите, теперь: ${status.label.toLowerCase()}.',
        'type': NotificationType.status.value,
        'referenceId': postId,
        'isRead': false,
        'data': <String, String>{'postId': postId},
        'createdAt': Timestamp.fromDate(DateTime.now()),
      });
    }
  }

  Future<ItemPost?> findByQrValue(String qrValue) async {
    final parsedId = _qrService.parseItemId(qrValue);
    if (parsedId == null) {
      return null;
    }

    final byCode = await _firestoreService.posts
        .where('itemCode', isEqualTo: parsedId)
        .limit(1)
        .get();
    if (byCode.docs.isNotEmpty) {
      return ItemPost.fromSnapshot(byCode.docs.first);
    }

    return getPost(parsedId);
  }

  Future<_ImageResolutionResult> _resolveImageUrls({
    required String userId,
    required String postId,
    required List<String> imagePaths,
  }) async {
    final urls = <String>[];
    var uploadAttemptCount = 0;
    var uploadSuccessCount = 0;

    for (final path in imagePaths) {
      if (path.startsWith('http')) {
        urls.add(path);
      } else {
        uploadAttemptCount += 1;
        final fileName = _uuid.v4();
        final url = await _storageService.uploadFile(
          localPath: path,
          storagePath: 'posts/$userId/$postId/$fileName.jpg',
        );
        if (url != null && url.isNotEmpty) {
          urls.add(url);
          uploadSuccessCount += 1;
        }
      }
    }
    return _ImageResolutionResult(
      urls: urls,
      uploadAttemptCount: uploadAttemptCount,
      uploadSuccessCount: uploadSuccessCount,
    );
  }

  Future<void> _syncMatchesAndNotify(ItemPost post) async {
    final staleMatches = await _firestoreService.matches
        .where('postIds', arrayContains: post.id)
        .get();
    final cleanupBatch = _firestoreService.firestore.batch();
    for (final doc in staleMatches.docs) {
      cleanupBatch.delete(doc.reference);
    }
    await cleanupBatch.commit();

    final snapshot = await _firestoreService.posts.get();
    final otherPosts = snapshot.docs
        .map(ItemPost.fromSnapshot)
        .where((candidate) => candidate.id != post.id)
        .where((candidate) => candidate.type == post.type.opposite)
        .where((candidate) => candidate.status != PostStatus.returned)
        .toList();

    final strongMatches = <ItemPost>[];

    for (final candidate in otherPosts) {
      final matchScore = _matchingService.score(post, candidate);
      if (!_matchingService.isStrongMatch(matchScore)) {
        continue;
      }

      strongMatches.add(candidate);
      final pairKey = _pairKey(post.id, candidate.id);
      await _firestoreService.matches.doc(pairKey).set(<String, dynamic>{
        'postIds': <String>[post.id, candidate.id],
        'score': matchScore.score,
        'reasons': matchScore.reasons,
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      }, SetOptions(merge: true));

      await _firestoreService.posts.doc(candidate.id).set(<String, dynamic>{
        'matchedPostIds': FieldValue.arrayUnion(<String>[post.id]),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      }, SetOptions(merge: true));
    }

    strongMatches.sort((a, b) {
      final left = _matchingService.score(post, a).score;
      final right = _matchingService.score(post, b).score;
      return right.compareTo(left);
    });

    await _firestoreService.posts.doc(post.id).set(<String, dynamic>{
      'matchedPostIds': strongMatches.map((item) => item.id).toList(),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    }, SetOptions(merge: true));

    for (final match in strongMatches.take(3)) {
      final score = _matchingService.score(post, match);
      await _firestoreService.notifications.add(<String, dynamic>{
        'userId': match.userId,
        'title': post.isPriorityDocument
            ? 'Приоритетное совпадение для документа'
            : 'Найдено возможное совпадение',
        'body':
            'Новый пост похож на ваш предмет. Совпадение: ${score.score.toStringAsFixed(0)} баллов.',
        'type': NotificationType.match.value,
        'referenceId': post.id,
        'isRead': false,
        'data': <String, String>{
          'postId': post.id,
          'matchPostId': match.id,
          'score': score.score.toStringAsFixed(1),
        },
        'createdAt': Timestamp.fromDate(DateTime.now()),
      });
    }
  }

  String _pairKey(String a, String b) {
    final ids = <String>[a, b]..sort();
    return ids.join('__');
  }
}

class _ImageResolutionResult {
  const _ImageResolutionResult({
    required this.urls,
    required this.uploadAttemptCount,
    required this.uploadSuccessCount,
  });

  final List<String> urls;
  final int uploadAttemptCount;
  final int uploadSuccessCount;
}
