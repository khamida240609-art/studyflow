import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/enums/app_enums.dart';
import '../models/claim_request.dart';
import '../services/firestore_service.dart';

class ClaimsRepository {
  ClaimsRepository(this._firestoreService);

  final FirestoreService _firestoreService;

  Stream<List<ClaimRequest>> streamClaimsForPost(String postId) {
    return _firestoreService.claims
        .where('postId', isEqualTo: postId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(ClaimRequest.fromSnapshot).toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
        );
  }

  Stream<List<ClaimRequest>> streamClaimsForUser(String userId) {
    return _firestoreService.claims.snapshots().map(
      (snapshot) =>
          snapshot.docs
              .map(ClaimRequest.fromSnapshot)
              .where(
                (claim) =>
                    claim.claimantId == userId || claim.ownerId == userId,
              )
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
    );
  }

  Future<void> createClaim(ClaimRequest claim) async {
    await _firestoreService.claims.add(claim.toMap());
    await _firestoreService.notifications.add(<String, dynamic>{
      'userId': claim.ownerId,
      'title': 'Новая заявка на подтверждение',
      'body':
          '${claim.claimantName} считает, что этот предмет принадлежит ему.',
      'type': NotificationType.claim.value,
      'referenceId': claim.postId,
      'isRead': false,
      'data': <String, String>{'postId': claim.postId, 'claimId': claim.id},
      'createdAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> updateClaimStatus({
    required ClaimRequest claim,
    required ClaimStatus status,
  }) async {
    await _firestoreService.claims.doc(claim.id).update(<String, dynamic>{
      'status': status.name,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });

    await _firestoreService.notifications.add(<String, dynamic>{
      'userId': claim.claimantId,
      'title': 'Статус заявки: ${status.label.toLowerCase()}',
      'body':
          'Ваш запрос на подтверждение предмета ${status.label.toLowerCase()}.',
      'type': NotificationType.status.value,
      'referenceId': claim.postId,
      'isRead': false,
      'data': <String, String>{'postId': claim.postId, 'claimId': claim.id},
      'createdAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> attachPickupScheduleId({
    required String claimId,
    required String pickupScheduleId,
  }) {
    return _firestoreService.claims.doc(claimId).set(<String, dynamic>{
      'pickupScheduleId': pickupScheduleId,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    }, SetOptions(merge: true));
  }
}
