import 'package:cloud_firestore/cloud_firestore.dart';

DateTime dateTimeFromFirestore(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is DateTime) {
    return value;
  }
  return DateTime.now();
}

Timestamp? timestampFromDate(DateTime? value) {
  if (value == null) {
    return null;
  }
  return Timestamp.fromDate(value);
}

double doubleFromDynamic(dynamic value, [double fallback = 0]) {
  if (value is double) {
    return value;
  }
  if (value is int) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value) ?? fallback;
  }
  return fallback;
}

List<String> stringListFromDynamic(dynamic value) {
  if (value is Iterable) {
    return value.map((element) => '$element').toList();
  }
  return <String>[];
}

Map<String, String> stringMapFromDynamic(dynamic value) {
  if (value is Map) {
    return value.map(
      (key, dynamic mapValue) => MapEntry('$key', '${mapValue ?? ''}'),
    );
  }
  return <String, String>{};
}

Map<String, int> intMapFromDynamic(dynamic value) {
  if (value is Map) {
    return value.map(
      (key, dynamic mapValue) =>
          MapEntry('$key', mapValue is int ? mapValue : 0),
    );
  }
  return <String, int>{};
}
