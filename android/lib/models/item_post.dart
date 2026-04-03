import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';
import '../core/enums/app_enums.dart';
import '../core/utils/firestore_x.dart';

class ItemPost {
  const ItemPost({
    required this.id,
    required this.itemCode,
    required this.userId,
    required this.authorName,
    required this.type,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.imageUrls,
    required this.createdAt,
    required this.updatedAt,
    required this.communityId,
    required this.isVerified,
    required this.trustScore,
    required this.matchedPostIds,
    required this.qrCodeValue,
    required this.qrEnabled,
    required this.rewardAmount,
    required this.visualTags,
    required this.textTags,
    this.authorPhotoUrl,
    this.dominantColor,
    this.documentType,
    this.isPriorityDocument = false,
    this.isAnonymous = false,
    this.isArchived = false,
  });

  final String id;
  final String itemCode;
  final String userId;
  final String authorName;
  final String? authorPhotoUrl;
  final PostType type;
  final String title;
  final String description;
  final String category;
  final PostStatus status;
  final String locationName;
  final double latitude;
  final double longitude;
  final List<String> imageUrls;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String communityId;
  final bool isVerified;
  final double trustScore;
  final List<String> matchedPostIds;
  final String qrCodeValue;
  final bool qrEnabled;
  final double rewardAmount;
  final String? dominantColor;
  final List<String> visualTags;
  final List<String> textTags;
  final String? documentType;
  final bool isPriorityDocument;
  final bool isAnonymous;
  final bool isArchived;

  factory ItemPost.fromMap(String id, Map<String, dynamic> map) {
    return ItemPost(
      id: id,
      itemCode: map['itemCode'] as String? ?? id,
      userId: map['userId'] as String? ?? '',
      authorName:
          map['authorName'] as String? ?? AppConstants.fallbackMemberName,
      authorPhotoUrl: map['authorPhotoUrl'] as String?,
      type: PostType.values.firstWhere(
        (type) => type.name == map['type'],
        orElse: () => PostType.lost,
      ),
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      category: map['category'] as String? ?? 'Другое',
      status: PostStatus.values.firstWhere(
        (status) => status.name == map['status'],
        orElse: () => PostStatus.lost,
      ),
      locationName: map['locationName'] as String? ?? '',
      latitude: doubleFromDynamic(map['latitude']),
      longitude: doubleFromDynamic(map['longitude']),
      imageUrls: stringListFromDynamic(map['imageUrls']),
      createdAt: dateTimeFromFirestore(map['createdAt']),
      updatedAt: dateTimeFromFirestore(map['updatedAt']),
      communityId: map['communityId'] as String? ?? 'campus',
      isVerified: map['isVerified'] as bool? ?? false,
      trustScore: doubleFromDynamic(map['trustScore'], 4.7),
      matchedPostIds: stringListFromDynamic(map['matchedPostIds']),
      qrCodeValue: map['qrCodeValue'] as String? ?? '',
      qrEnabled: map['qrEnabled'] as bool? ?? true,
      rewardAmount: doubleFromDynamic(map['rewardAmount']),
      dominantColor: map['dominantColor'] as String?,
      visualTags: stringListFromDynamic(map['visualTags']),
      textTags: stringListFromDynamic(map['textTags']),
      documentType: map['documentType'] as String?,
      isPriorityDocument: map['isPriorityDocument'] as bool? ?? false,
      isAnonymous: map['isAnonymous'] as bool? ?? false,
      isArchived: map['isArchived'] as bool? ?? false,
    );
  }

  factory ItemPost.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    return ItemPost.fromMap(
      snapshot.id,
      snapshot.data() ?? <String, dynamic>{},
    );
  }

  ItemPost copyWith({
    String? id,
    String? itemCode,
    String? userId,
    String? authorName,
    String? authorPhotoUrl,
    PostType? type,
    String? title,
    String? description,
    String? category,
    PostStatus? status,
    String? locationName,
    double? latitude,
    double? longitude,
    List<String>? imageUrls,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? communityId,
    bool? isVerified,
    double? trustScore,
    List<String>? matchedPostIds,
    String? qrCodeValue,
    bool? qrEnabled,
    double? rewardAmount,
    String? dominantColor,
    List<String>? visualTags,
    List<String>? textTags,
    String? documentType,
    bool? isPriorityDocument,
    bool? isAnonymous,
    bool? isArchived,
  }) {
    return ItemPost(
      id: id ?? this.id,
      itemCode: itemCode ?? this.itemCode,
      userId: userId ?? this.userId,
      authorName: authorName ?? this.authorName,
      authorPhotoUrl: authorPhotoUrl ?? this.authorPhotoUrl,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      status: status ?? this.status,
      locationName: locationName ?? this.locationName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      imageUrls: imageUrls ?? this.imageUrls,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      communityId: communityId ?? this.communityId,
      isVerified: isVerified ?? this.isVerified,
      trustScore: trustScore ?? this.trustScore,
      matchedPostIds: matchedPostIds ?? this.matchedPostIds,
      qrCodeValue: qrCodeValue ?? this.qrCodeValue,
      qrEnabled: qrEnabled ?? this.qrEnabled,
      rewardAmount: rewardAmount ?? this.rewardAmount,
      dominantColor: dominantColor ?? this.dominantColor,
      visualTags: visualTags ?? this.visualTags,
      textTags: textTags ?? this.textTags,
      documentType: documentType ?? this.documentType,
      isPriorityDocument: isPriorityDocument ?? this.isPriorityDocument,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'userId': userId,
      'itemCode': itemCode,
      'authorName': authorName,
      'authorPhotoUrl': authorPhotoUrl,
      'type': type.value,
      'title': title,
      'description': description,
      'category': category,
      'status': status.value,
      'locationName': locationName,
      'latitude': latitude,
      'longitude': longitude,
      'imageUrls': imageUrls,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'communityId': communityId,
      'isVerified': isVerified,
      'trustScore': trustScore,
      'matchedPostIds': matchedPostIds,
      'qrCodeValue': qrCodeValue,
      'qrEnabled': qrEnabled,
      'rewardAmount': rewardAmount,
      'dominantColor': dominantColor,
      'visualTags': visualTags,
      'textTags': textTags,
      'documentType': documentType,
      'isPriorityDocument': isPriorityDocument,
      'isAnonymous': isAnonymous,
      'isArchived': isArchived,
    };
  }
}
