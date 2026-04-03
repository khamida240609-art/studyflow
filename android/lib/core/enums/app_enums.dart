enum PostType { lost, found }

enum PostStatus { lost, found, matched, returned }

enum ClaimStatus { pending, approved, rejected }

enum NotificationType {
  message,
  claim,
  match,
  status,
  report,
  moderation,
  reminder,
  security,
}

enum CommunityType { campus, school, office, mall }

enum PickupScheduleStatus { proposed, confirmed, completed, cancelled }

extension PostTypeX on PostType {
  String get label => this == PostType.lost ? 'Потеряно' : 'Найдено';

  String get value => name;

  PostType get opposite =>
      this == PostType.lost ? PostType.found : PostType.lost;
}

extension PostStatusX on PostStatus {
  String get label {
    switch (this) {
      case PostStatus.lost:
        return 'Потеряно';
      case PostStatus.found:
        return 'Найдено';
      case PostStatus.matched:
        return 'Совпадение';
      case PostStatus.returned:
        return 'Возвращено';
    }
  }

  String get value => name;
}

extension ClaimStatusX on ClaimStatus {
  String get label {
    switch (this) {
      case ClaimStatus.pending:
        return 'На проверке';
      case ClaimStatus.approved:
        return 'Одобрено';
      case ClaimStatus.rejected:
        return 'Отклонено';
    }
  }
}

extension NotificationTypeX on NotificationType {
  String get value => name;
}

extension PickupScheduleStatusX on PickupScheduleStatus {
  String get value => name;

  String get label {
    switch (this) {
      case PickupScheduleStatus.proposed:
        return 'Предложено';
      case PickupScheduleStatus.confirmed:
        return 'Подтверждено';
      case PickupScheduleStatus.completed:
        return 'Завершено';
      case PickupScheduleStatus.cancelled:
        return 'Отменено';
    }
  }
}

extension CommunityTypeX on CommunityType {
  String get value => name;

  String get label {
    switch (this) {
      case CommunityType.campus:
        return 'Кампус';
      case CommunityType.school:
        return 'Школа';
      case CommunityType.office:
        return 'Офис';
      case CommunityType.mall:
        return 'Торговый центр';
    }
  }
}
