import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/firestore_x.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.createdAt,
    required this.updatedAt,
    this.photoUrl,
    this.bio,
    this.communityIds = const <String>[],
    this.savedPostIds = const <String>[],
    this.trustScore = 4.7,
    this.isAdmin = false,
    this.fcmToken,
  });

  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String? bio;
  final List<String> communityIds;
  final List<String> savedPostIds;
  final double trustScore;
  final bool isAdmin;
  final String? fcmToken;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory AppUser.fromMap(String id, Map<String, dynamic> map) {
    return AppUser(
      id: id,
      email: map['email'] as String? ?? '',
      displayName:
          map['displayName'] as String? ?? AppConstants.fallbackMemberName,
      photoUrl: map['photoUrl'] as String?,
      bio: map['bio'] as String?,
      communityIds: stringListFromDynamic(map['communityIds']),
      savedPostIds: stringListFromDynamic(map['savedPostIds']),
      trustScore: doubleFromDynamic(map['trustScore'], 4.7),
      isAdmin: map['isAdmin'] as bool? ?? false,
      fcmToken: map['fcmToken'] as String?,
      createdAt: dateTimeFromFirestore(map['createdAt']),
      updatedAt: dateTimeFromFirestore(map['updatedAt']),
    );
  }

  factory AppUser.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    return AppUser.fromMap(snapshot.id, snapshot.data() ?? <String, dynamic>{});
  }

  AppUser copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    String? bio,
    List<String>? communityIds,
    List<String>? savedPostIds,
    double? trustScore,
    bool? isAdmin,
    String? fcmToken,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
      communityIds: communityIds ?? this.communityIds,
      savedPostIds: savedPostIds ?? this.savedPostIds,
      trustScore: trustScore ?? this.trustScore,
      isAdmin: isAdmin ?? this.isAdmin,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'bio': bio,
      'communityIds': communityIds,
      'savedPostIds': savedPostIds,
      'trustScore': trustScore,
      'isAdmin': isAdmin,
      'fcmToken': fcmToken,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
