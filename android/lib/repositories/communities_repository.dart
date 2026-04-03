import '../core/constants/app_constants.dart';
import '../core/enums/app_enums.dart';
import '../models/community.dart';
import '../services/firestore_service.dart';

class CommunitiesRepository {
  CommunitiesRepository(this._firestoreService);

  final FirestoreService _firestoreService;

  Stream<List<Community>> streamCommunities() {
    return _firestoreService.communities.snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return AppConstants.starterCommunities
            .map(
              (community) => Community(
                id: community['id']!,
                name: community['name']!,
                description: community['description']!,
                type: CommunityType.values.firstWhere(
                  (type) => type.name == community['type'],
                ),
                locationName: community['locationName']!,
                securityEmail: community['securityEmail'],
                securityPhone: community['securityPhone'],
                emergencyNote: community['emergencyNote'],
              ),
            )
            .toList();
      }

      return snapshot.docs.map(Community.fromSnapshot).toList();
    });
  }
}
