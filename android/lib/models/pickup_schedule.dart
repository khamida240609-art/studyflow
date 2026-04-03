import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/enums/app_enums.dart';
import '../core/utils/firestore_x.dart';

class PickupSchedule {
  const PickupSchedule({
    required this.id,
    required this.claimId,
    required this.postId,
    required this.ownerId,
    required this.claimantId,
    required this.locationName,
    required this.scheduledAt,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.notes,
  });

  final String id;
  final String claimId;
  final String postId;
  final String ownerId;
  final String claimantId;
  final String locationName;
  final DateTime scheduledAt;
  final PickupScheduleStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? notes;

  factory PickupSchedule.fromMap(String id, Map<String, dynamic> map) {
    return PickupSchedule(
      id: id,
      claimId: map['claimId'] as String? ?? '',
      postId: map['postId'] as String? ?? '',
      ownerId: map['ownerId'] as String? ?? '',
      claimantId: map['claimantId'] as String? ?? '',
      locationName: map['locationName'] as String? ?? '',
      scheduledAt: dateTimeFromFirestore(map['scheduledAt']),
      status: PickupScheduleStatus.values.firstWhere(
        (item) => item.name == map['status'],
        orElse: () => PickupScheduleStatus.proposed,
      ),
      createdAt: dateTimeFromFirestore(map['createdAt']),
      updatedAt: dateTimeFromFirestore(map['updatedAt']),
      notes: map['notes'] as String?,
    );
  }

  factory PickupSchedule.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    return PickupSchedule.fromMap(
      snapshot.id,
      snapshot.data() ?? <String, dynamic>{},
    );
  }

  PickupSchedule copyWith({
    String? locationName,
    DateTime? scheduledAt,
    PickupScheduleStatus? status,
    DateTime? updatedAt,
    String? notes,
  }) {
    return PickupSchedule(
      id: id,
      claimId: claimId,
      postId: postId,
      ownerId: ownerId,
      claimantId: claimantId,
      locationName: locationName ?? this.locationName,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'claimId': claimId,
      'postId': postId,
      'ownerId': ownerId,
      'claimantId': claimantId,
      'locationName': locationName,
      'scheduledAt': Timestamp.fromDate(scheduledAt),
      'status': status.value,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
