import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/utils/firestore_x.dart';

class PostReport {
  const PostReport({
    required this.id,
    required this.postId,
    required this.reporterId,
    required this.reason,
    required this.details,
    required this.createdAt,
    this.status = 'pending',
  });

  final String id;
  final String postId;
  final String reporterId;
  final String reason;
  final String details;
  final String status;
  final DateTime createdAt;

  factory PostReport.fromMap(String id, Map<String, dynamic> map) {
    return PostReport(
      id: id,
      postId: map['postId'] as String? ?? '',
      reporterId: map['reporterId'] as String? ?? '',
      reason: map['reason'] as String? ?? '',
      details: map['details'] as String? ?? '',
      status: map['status'] as String? ?? 'pending',
      createdAt: dateTimeFromFirestore(map['createdAt']),
    );
  }

  factory PostReport.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    return PostReport.fromMap(
      snapshot.id,
      snapshot.data() ?? <String, dynamic>{},
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'postId': postId,
      'reporterId': reporterId,
      'reason': reason,
      'details': details,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
