import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/utils/firestore_x.dart';

class UserPreferences {
  const UserPreferences({
    required this.userId,
    required this.localeCode,
    required this.pushEnabled,
    required this.emailAlertsEnabled,
    required this.smsAlertsEnabled,
    required this.matchAlertsEnabled,
    required this.claimAlertsEnabled,
    required this.reminderAlertsEnabled,
    required this.updatedAt,
    this.emailAddress,
    this.smsNumber,
  });

  final String userId;
  final String localeCode;
  final bool pushEnabled;
  final bool emailAlertsEnabled;
  final bool smsAlertsEnabled;
  final bool matchAlertsEnabled;
  final bool claimAlertsEnabled;
  final bool reminderAlertsEnabled;
  final String? emailAddress;
  final String? smsNumber;
  final DateTime updatedAt;

  factory UserPreferences.defaults({
    required String userId,
    String? emailAddress,
  }) {
    return UserPreferences(
      userId: userId,
      localeCode: 'ru',
      pushEnabled: true,
      emailAlertsEnabled: false,
      smsAlertsEnabled: false,
      matchAlertsEnabled: true,
      claimAlertsEnabled: true,
      reminderAlertsEnabled: true,
      emailAddress: emailAddress,
      updatedAt: DateTime.now(),
    );
  }

  factory UserPreferences.fromMap(String id, Map<String, dynamic> map) {
    return UserPreferences(
      userId: id,
      localeCode: map['localeCode'] as String? ?? 'ru',
      pushEnabled: map['pushEnabled'] as bool? ?? true,
      emailAlertsEnabled: map['emailAlertsEnabled'] as bool? ?? false,
      smsAlertsEnabled: map['smsAlertsEnabled'] as bool? ?? false,
      matchAlertsEnabled: map['matchAlertsEnabled'] as bool? ?? true,
      claimAlertsEnabled: map['claimAlertsEnabled'] as bool? ?? true,
      reminderAlertsEnabled: map['reminderAlertsEnabled'] as bool? ?? true,
      emailAddress: map['emailAddress'] as String?,
      smsNumber: map['smsNumber'] as String?,
      updatedAt: dateTimeFromFirestore(map['updatedAt']),
    );
  }

  factory UserPreferences.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    return UserPreferences.fromMap(
      snapshot.id,
      snapshot.data() ?? <String, dynamic>{},
    );
  }

  UserPreferences copyWith({
    String? localeCode,
    bool? pushEnabled,
    bool? emailAlertsEnabled,
    bool? smsAlertsEnabled,
    bool? matchAlertsEnabled,
    bool? claimAlertsEnabled,
    bool? reminderAlertsEnabled,
    String? emailAddress,
    String? smsNumber,
    DateTime? updatedAt,
  }) {
    return UserPreferences(
      userId: userId,
      localeCode: localeCode ?? this.localeCode,
      pushEnabled: pushEnabled ?? this.pushEnabled,
      emailAlertsEnabled: emailAlertsEnabled ?? this.emailAlertsEnabled,
      smsAlertsEnabled: smsAlertsEnabled ?? this.smsAlertsEnabled,
      matchAlertsEnabled: matchAlertsEnabled ?? this.matchAlertsEnabled,
      claimAlertsEnabled: claimAlertsEnabled ?? this.claimAlertsEnabled,
      reminderAlertsEnabled:
          reminderAlertsEnabled ?? this.reminderAlertsEnabled,
      emailAddress: emailAddress ?? this.emailAddress,
      smsNumber: smsNumber ?? this.smsNumber,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'localeCode': localeCode,
      'pushEnabled': pushEnabled,
      'emailAlertsEnabled': emailAlertsEnabled,
      'smsAlertsEnabled': smsAlertsEnabled,
      'matchAlertsEnabled': matchAlertsEnabled,
      'claimAlertsEnabled': claimAlertsEnabled,
      'reminderAlertsEnabled': reminderAlertsEnabled,
      'emailAddress': emailAddress,
      'smsNumber': smsNumber,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
