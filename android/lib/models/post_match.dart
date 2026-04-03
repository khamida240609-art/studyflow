import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/utils/firestore_x.dart';

class PostMatch {
  const PostMatch({
    required this.id,
    required this.postIds,
    required this.score,
    required this.reasons,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final List<String> postIds;
  final double score;
  final List<String> reasons;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory PostMatch.fromMap(String id, Map<String, dynamic> map) {
    return PostMatch(
      id: id,
      postIds: stringListFromDynamic(map['postIds']),
      score: doubleFromDynamic(map['score']),
      reasons: stringListFromDynamic(map['reasons']),
      createdAt: dateTimeFromFirestore(map['createdAt']),
      updatedAt: dateTimeFromFirestore(map['updatedAt']),
    );
  }

  factory PostMatch.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    return PostMatch.fromMap(
      snapshot.id,
      snapshot.data() ?? <String, dynamic>{},
    );
  }

  String? otherPostId(String currentPostId) {
    for (final postId in postIds) {
      if (postId != currentPostId) {
        return postId;
      }
    }
    return null;
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'postIds': postIds,
      'score': score,
      'reasons': reasons,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
