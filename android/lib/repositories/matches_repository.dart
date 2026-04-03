import '../models/post_match.dart';
import '../services/firestore_service.dart';

class MatchesRepository {
  MatchesRepository(this._firestoreService);

  final FirestoreService _firestoreService;

  Stream<List<PostMatch>> streamMatchesForPost(String postId) {
    return _firestoreService.matches
        .where('postIds', arrayContains: postId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(PostMatch.fromSnapshot).toList()
                ..sort((a, b) => b.score.compareTo(a.score)),
        );
  }
}
