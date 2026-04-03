import '../models/post_report.dart';
import '../services/firestore_service.dart';

class ReportsRepository {
  ReportsRepository(this._firestoreService);

  final FirestoreService _firestoreService;

  Stream<List<PostReport>> streamReports() {
    return _firestoreService.reports.snapshots().map(
      (snapshot) =>
          snapshot.docs.map(PostReport.fromSnapshot).toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
    );
  }

  Future<void> createReport(PostReport report) {
    return _firestoreService.reports.add(report.toMap());
  }

  Future<void> resolveReport(String reportId) {
    return _firestoreService.reports.doc(reportId).update(<String, dynamic>{
      'status': 'resolved',
    });
  }
}
