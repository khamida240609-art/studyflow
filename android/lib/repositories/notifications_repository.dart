import '../core/enums/app_enums.dart';
import '../models/lostly_notification.dart';
import '../services/firestore_service.dart';

class NotificationsRepository {
  NotificationsRepository(this._firestoreService);

  final FirestoreService _firestoreService;

  Stream<List<LostlyNotification>> streamForUser(String userId) {
    return _firestoreService.notifications
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(LostlyNotification.fromSnapshot).toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
        );
  }

  Future<void> createNotification({
    required String userId,
    required String title,
    required String body,
    required NotificationType type,
    String? referenceId,
    Map<String, String> data = const <String, String>{},
  }) {
    return _firestoreService.notifications.add(
      LostlyNotification(
        id: '',
        userId: userId,
        title: title,
        body: body,
        type: type,
        referenceId: referenceId,
        createdAt: DateTime.now(),
        data: data,
      ).toMap(),
    );
  }

  Future<void> markAsRead(String notificationId) {
    return _firestoreService.notifications.doc(notificationId).update(
      <String, dynamic>{'isRead': true},
    );
  }
}
