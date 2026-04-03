import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';
import '../core/enums/app_enums.dart';
import '../core/utils/firestore_x.dart';

class ClaimRequest {
  const ClaimRequest({
    required this.id,
    required this.postId,
    required this.claimantId,
    required this.claimantName,
    required this.ownerId,
    required this.message,
    required this.evidence,
    required this.answers,
    required this.verificationChecklist,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.pickupScheduleId,
  });

  final String id;
  final String postId;
  final String claimantId;
  final String claimantName;
  final String ownerId;
  final String message;
  final String evidence;
  final Map<String, String> answers;
  final Map<String, bool> verificationChecklist;
  final ClaimStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? pickupScheduleId;

  factory ClaimRequest.fromMap(String id, Map<String, dynamic> map) {
    return ClaimRequest(
      id: id,
      postId: map['postId'] as String? ?? '',
      claimantId: map['claimantId'] as String? ?? '',
      claimantName:
          map['claimantName'] as String? ?? AppConstants.fallbackMemberName,
      ownerId: map['ownerId'] as String? ?? '',
      message: map['message'] as String? ?? '',
      evidence: map['evidence'] as String? ?? '',
      answers: stringMapFromDynamic(map['answers']),
      verificationChecklist:
          (map['verificationChecklist'] as Map?)?.map(
            (key, value) =>
                MapEntry('$key', value is bool ? value : '$value' == 'true'),
          ) ??
          const <String, bool>{},
      status: ClaimStatus.values.firstWhere(
        (status) => status.name == map['status'],
        orElse: () => ClaimStatus.pending,
      ),
      createdAt: dateTimeFromFirestore(map['createdAt']),
      updatedAt: dateTimeFromFirestore(map['updatedAt']),
      pickupScheduleId: map['pickupScheduleId'] as String?,
    );
  }

  factory ClaimRequest.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    return ClaimRequest.fromMap(
      snapshot.id,
      snapshot.data() ?? <String, dynamic>{},
    );
  }

  ClaimRequest copyWith({
    ClaimStatus? status,
    DateTime? updatedAt,
    String? pickupScheduleId,
  }) {
    return ClaimRequest(
      id: id,
      postId: postId,
      claimantId: claimantId,
      claimantName: claimantName,
      ownerId: ownerId,
      message: message,
      evidence: evidence,
      answers: answers,
      verificationChecklist: verificationChecklist,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      pickupScheduleId: pickupScheduleId ?? this.pickupScheduleId,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'postId': postId,
      'claimantId': claimantId,
      'claimantName': claimantName,
      'ownerId': ownerId,
      'message': message,
      'evidence': evidence,
      'answers': answers,
      'verificationChecklist': verificationChecklist,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'pickupScheduleId': pickupScheduleId,
    };
  }
}
