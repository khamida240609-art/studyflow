import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/enums/app_enums.dart';
import '../core/utils/firestore_x.dart';

class Community {
  const Community({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.locationName,
    this.bannerUrl,
    this.memberCount = 0,
    this.securityEmail,
    this.securityPhone,
    this.emergencyNote,
  });

  final String id;
  final String name;
  final String description;
  final CommunityType type;
  final String locationName;
  final String? bannerUrl;
  final int memberCount;
  final String? securityEmail;
  final String? securityPhone;
  final String? emergencyNote;

  factory Community.fromMap(String id, Map<String, dynamic> map) {
    return Community(
      id: id,
      name: map['name'] as String? ?? 'Сообщество',
      description: map['description'] as String? ?? '',
      type: CommunityType.values.firstWhere(
        (type) => type.name == map['type'],
        orElse: () => CommunityType.campus,
      ),
      locationName: map['locationName'] as String? ?? 'Неизвестно',
      bannerUrl: map['bannerUrl'] as String?,
      memberCount: (map['memberCount'] as int?) ?? 0,
      securityEmail: map['securityEmail'] as String?,
      securityPhone: map['securityPhone'] as String?,
      emergencyNote: map['emergencyNote'] as String?,
    );
  }

  factory Community.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    return Community.fromMap(
      snapshot.id,
      snapshot.data() ?? <String, dynamic>{},
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'description': description,
      'type': type.value,
      'locationName': locationName,
      'bannerUrl': bannerUrl,
      'memberCount': memberCount,
      'securityEmail': securityEmail,
      'securityPhone': securityPhone,
      'emergencyNote': emergencyNote,
      'updatedAt': timestampFromDate(DateTime.now()),
    };
  }
}
