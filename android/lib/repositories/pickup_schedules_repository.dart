import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/enums/app_enums.dart';
import '../models/pickup_schedule.dart';
import '../services/firestore_service.dart';

class PickupSchedulesRepository {
  PickupSchedulesRepository(this._firestoreService);

  final FirestoreService _firestoreService;

  Stream<PickupSchedule?> watchForClaim(String claimId) {
    return _firestoreService.pickupSchedules
        .where('claimId', isEqualTo: claimId)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) {
            return null;
          }
          final schedules = snapshot.docs
              .map(PickupSchedule.fromSnapshot)
              .toList()
            ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          return schedules.first;
        });
  }

  Future<String> createOrUpdate(PickupSchedule schedule) async {
    final existing = await _firestoreService.pickupSchedules
        .where('claimId', isEqualTo: schedule.claimId)
        .get();

    if (existing.docs.isNotEmpty) {
      final docId = existing.docs.first.id;
      await _firestoreService.pickupSchedules.doc(docId).set(
            schedule.copyWith(updatedAt: DateTime.now()).toMap(),
            SetOptions(merge: true),
          );
      return docId;
    }

    final doc = _firestoreService.pickupSchedules.doc();
    await doc.set(schedule.toMap());
    return doc.id;
  }

  Future<void> updateStatus({
    required String scheduleId,
    required PickupScheduleStatus status,
  }) {
    return _firestoreService.pickupSchedules.doc(scheduleId).set(
      <String, dynamic>{
        'status': status.value,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      },
      SetOptions(merge: true),
    );
  }
}
