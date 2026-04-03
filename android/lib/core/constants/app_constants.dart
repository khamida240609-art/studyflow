class AppConstants {
  static const String appName = 'Lostly';
  static const String tagline = 'Находите быстрее. Возвращайте умнее.';
  static const String supportEmail = 'hello@lostly.app';
  static const String fallbackMemberName = 'Пользователь Lostly';
  static const String defaultCurrency = 'KZT';

  static const List<String> itemCategories = [
    'Документы',
    'Электроника',
    'Аксессуары',
    'Кошельки',
    'Ключи',
    'Сумки',
    'Одежда',
    'Украшения',
    'Книги',
    'Спорт',
    'Питомцы',
    'Другое',
  ];

  static const List<String> postStatuses = [
    'lost',
    'found',
    'matched',
    'returned',
  ];

  static const List<String> documentTypes = [
    'Паспорт',
    'Удостоверение личности',
    'Студенческий билет',
    'Водительское удостоверение',
    'Банковская карта',
    'Пропуск',
    'Другое',
  ];

  static const List<String> priorityDocumentKeywords = [
    'паспорт',
    'passport',
    'удостоверение',
    'id card',
    'id',
    'student id',
    'студенческий',
    'driver license',
    'водительское',
    'license',
    'driver',
    'банковская карта',
    'карта',
    'пропуск',
    'badge',
  ];

  static const Map<String, List<String>> colorKeywords = {
    'black': ['black', 'черный', 'чёрный', 'қара', 'dark'],
    'white': ['white', 'белый', 'ақ', 'light'],
    'gray': ['gray', 'grey', 'серый', 'сұр'],
    'blue': ['blue', 'синий', 'көк', 'голубой'],
    'red': ['red', 'красный', 'қызыл', 'burgundy'],
    'green': ['green', 'зеленый', 'жасыл'],
    'yellow': ['yellow', 'желтый', 'сары'],
    'orange': ['orange', 'оранжевый', 'қызғылт сары'],
    'brown': ['brown', 'коричневый', 'қоңыр', 'beige', 'бежевый'],
    'purple': ['purple', 'фиолетовый', 'күлгін'],
    'pink': ['pink', 'розовый', 'қызғылт'],
  };

  static const List<Map<String, String>> starterCommunities = [
    {
      'id': 'campus',
      'name': 'Кампус',
      'description': 'Общежития, библиотеки, студенческие центры и аудитории.',
      'type': 'campus',
      'locationName': 'Университетский район',
      'securityEmail': 'security-campus@lostly.app',
      'securityPhone': '+77001000001',
      'emergencyNote':
          'Свяжитесь с кампусной службой безопасности, если потеря связана с документами или подозрительной находкой.',
    },
    {
      'id': 'school',
      'name': 'Школа',
      'description':
          'Шкафчики, кабинеты, спортивные площадки и школьные автобусы.',
      'type': 'school',
      'locationName': 'Школьная зона',
      'securityEmail': 'security-school@lostly.app',
      'securityPhone': '+77001000002',
      'emergencyNote':
          'Для школьных документов и пропусков лучше сразу уведомить администратора или охрану.',
    },
    {
      'id': 'office',
      'name': 'Офис',
      'description': 'Рабочие места, переговорные, кухни и стойки ресепшена.',
      'type': 'office',
      'locationName': 'Бизнес-центр',
      'securityEmail': 'security-office@lostly.app',
      'securityPhone': '+77001000003',
      'emergencyNote':
          'Потерю корпоративных пропусков и техники лучше продублировать в службу безопасности офиса.',
    },
    {
      'id': 'mall',
      'name': 'Торговый центр',
      'description': 'Магазины, фудкорты, парковки и кино-зоны.',
      'type': 'mall',
      'locationName': 'Торговый район',
      'securityEmail': 'security-mall@lostly.app',
      'securityPhone': '+77001000004',
      'emergencyNote':
          'Если вещь потеряна в торговом центре, используйте Lostly и параллельно сообщите на стойку информации или охране.',
    },
  ];

  static const List<String> verificationQuestions = [
    'Какого цвета был предмет?',
    'Какая у него была особая примета или отметка?',
    'Что было внутри, в кармане или прикреплено к нему?',
    'Где вы в последний раз видели этот предмет?',
  ];

  static const Map<String, String> _categoryLabels = {
    'documents': 'Документы',
    'документы': 'Документы',
    'electronics': 'Электроника',
    'электроника': 'Электроника',
    'accessories': 'Аксессуары',
    'аксессуары': 'Аксессуары',
    'wallets': 'Кошельки',
    'кошельки': 'Кошельки',
    'keys': 'Ключи',
    'ключи': 'Ключи',
    'bags': 'Сумки',
    'сумки': 'Сумки',
    'clothing': 'Одежда',
    'одежда': 'Одежда',
    'jewelry': 'Украшения',
    'украшения': 'Украшения',
    'books': 'Книги',
    'книги': 'Книги',
    'sports': 'Спорт',
    'спорт': 'Спорт',
    'pets': 'Питомцы',
    'питомцы': 'Питомцы',
    'other': 'Другое',
    'другое': 'Другое',
  };

  static const Map<String, String> _communityLabels = {
    'campus': 'Кампус',
    'school': 'Школа',
    'office': 'Офис',
    'mall': 'Торговый центр',
    'кампус': 'Кампус',
    'школа': 'Школа',
    'офис': 'Офис',
    'торговый центр': 'Торговый центр',
  };

  static const Map<String, String> _documentLabels = {
    'passport': 'Паспорт',
    'паспорт': 'Паспорт',
    'id card': 'Удостоверение личности',
    'удостоверение личности': 'Удостоверение личности',
    'student id': 'Студенческий билет',
    'студенческий билет': 'Студенческий билет',
    'driver license': 'Водительское удостоверение',
    'водительское удостоверение': 'Водительское удостоверение',
    'bank card': 'Банковская карта',
    'банковская карта': 'Банковская карта',
    'badge': 'Пропуск',
    'пропуск': 'Пропуск',
    'other': 'Другое',
    'другое': 'Другое',
  };

  static String displayCategory(String value) {
    return _categoryLabels[value.trim().toLowerCase()] ?? value;
  }

  static String displayCommunity(String value) {
    return _communityLabels[value.trim().toLowerCase()] ?? value;
  }

  static String displayDocumentType(String value) {
    return _documentLabels[value.trim().toLowerCase()] ?? value;
  }
}
