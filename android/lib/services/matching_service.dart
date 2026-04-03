import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

import '../core/constants/app_constants.dart';
import '../models/item_post.dart';

class MatchingMetadata {
  const MatchingMetadata({
    required this.textTags,
    required this.visualTags,
    this.dominantColor,
    this.documentType,
    this.isPriorityDocument = false,
  });

  final List<String> textTags;
  final List<String> visualTags;
  final String? dominantColor;
  final String? documentType;
  final bool isPriorityDocument;
}

class MatchScore {
  const MatchScore({required this.score, required this.reasons});

  final double score;
  final List<String> reasons;
}

class MatchingService {
  Future<MatchingMetadata> analyzeDraft({
    required List<String> imagePaths,
    required String title,
    required String description,
    required String category,
    required String locationName,
    String? documentType,
  }) async {
    final textTags = _extractTextTags(
      '$title $description $category $locationName ${documentType ?? ''}',
    );
    final priority = _isPriorityDocument(
      category: category,
      title: title,
      description: description,
      documentType: documentType,
    );
    final colorFromText = _extractDominantColorFromText(textTags);

    String? dominantColor = colorFromText;
    final visualTags = <String>{...textTags.where(_isColorTag)};

    String? localPath;
    for (final path in imagePaths) {
      if (!path.startsWith('http') && path.isNotEmpty) {
        localPath = path;
        break;
      }
    }

    if (localPath != null) {
      final image = await _decodeImage(localPath);
      if (image != null) {
        dominantColor ??= _estimateDominantColor(image);
        final aspectRatio = image.width / image.height;
        if (aspectRatio > 1.15) {
          visualTags.add('wide');
        } else if (aspectRatio < 0.85) {
          visualTags.add('tall');
        } else {
          visualTags.add('square');
        }

        final brightness = _estimateBrightness(image);
        if (brightness < 85) {
          visualTags.add('dark');
        } else if (brightness > 170) {
          visualTags.add('light');
        } else {
          visualTags.add('neutral');
        }
      }
    }

    if (dominantColor != null) {
      visualTags.add(dominantColor);
    }

    return MatchingMetadata(
      textTags: textTags.toList()..sort(),
      visualTags: visualTags.toList()..sort(),
      dominantColor: dominantColor,
      documentType: documentType,
      isPriorityDocument: priority,
    );
  }

  MatchScore score(ItemPost base, ItemPost candidate) {
    final reasons = <String>[];
    var score = 0.0;

    if (base.type == candidate.type) {
      return const MatchScore(score: 0, reasons: <String>[]);
    }

    if (_sameLabel(base.category, candidate.category)) {
      score += 24;
      reasons.add('Совпадает категория');
    }

    if ((base.documentType?.isNotEmpty ?? false) &&
        (candidate.documentType?.isNotEmpty ?? false) &&
        _sameLabel(base.documentType!, candidate.documentType!)) {
      score += 18;
      reasons.add('Совпадает тип документа');
    }

    if (base.isPriorityDocument || candidate.isPriorityDocument) {
      score += 8;
      reasons.add('Приоритетный документ');
    }

    if ((base.rewardAmount > 0 || candidate.rewardAmount > 0) &&
        (base.type.name == 'lost' || candidate.type.name == 'lost')) {
      score += 4;
      reasons.add('Есть объявление с вознаграждением');
    }

    final textOverlap = _overlapScore(base.textTags, candidate.textTags);
    if (textOverlap > 0) {
      score += textOverlap * 36;
      reasons.add('Есть пересечение по описанию и названию');
    }

    final visualOverlap = _overlapScore(base.visualTags, candidate.visualTags);
    if (visualOverlap > 0) {
      score += visualOverlap * 18;
      reasons.add('Похожая визуальная сигнатура');
    }

    if (base.dominantColor != null &&
        candidate.dominantColor != null &&
        base.dominantColor == candidate.dominantColor) {
      score += 12;
      reasons.add('Совпадает основной цвет');
    }

    if (base.communityId == candidate.communityId) {
      score += 8;
      reasons.add('Один и тот же community');
    }

    final locationDistanceKm = _distanceKm(
      base.latitude,
      base.longitude,
      candidate.latitude,
      candidate.longitude,
    );
    if (locationDistanceKm <= 2) {
      score += 12;
      reasons.add('Точки на карте очень близко');
    } else if (locationDistanceKm <= 10) {
      score += 7;
      reasons.add('Локации находятся рядом');
    }

    final daysDiff = base.createdAt
        .difference(candidate.createdAt)
        .inDays
        .abs();
    if (daysDiff <= 1) {
      score += 10;
      reasons.add('Посты опубликованы почти одновременно');
    } else if (daysDiff <= 3) {
      score += 6;
      reasons.add('Посты опубликованы в близкий период');
    } else if (daysDiff <= 7) {
      score += 3;
      reasons.add('Периоды публикации пересекаются');
    }

    return MatchScore(score: score, reasons: reasons.take(5).toList());
  }

  bool isStrongMatch(MatchScore score) => score.score >= 34;

  bool inferPriorityDocument({
    required String category,
    required String title,
    required String description,
    String? documentType,
  }) {
    return _isPriorityDocument(
      category: category,
      title: title,
      description: description,
      documentType: documentType,
    );
  }

  Future<img.Image?> _decodeImage(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) {
        return null;
      }
      final bytes = await file.readAsBytes();
      return img.decodeImage(bytes);
    } catch (_) {
      return null;
    }
  }

  List<String> _extractTextTags(String source) {
    final tokens = source
        .toLowerCase()
        .split(RegExp(r'[^a-zA-Zа-яА-ЯёЁ0-9]+'))
        .where((token) => token.trim().length > 2)
        .toSet();

    for (final entry in AppConstants.colorKeywords.entries) {
      if (entry.value.any(tokens.contains)) {
        tokens.add(entry.key);
      }
    }

    return tokens.toList();
  }

  bool _isPriorityDocument({
    required String category,
    required String title,
    required String description,
    String? documentType,
  }) {
    final haystack =
        '${category.toLowerCase()} ${title.toLowerCase()} ${description.toLowerCase()} ${(documentType ?? '').toLowerCase()}';

    final isDocumentCategory =
        AppConstants.displayCategory(category).toLowerCase() == 'документы';
    if (!isDocumentCategory) {
      return false;
    }

    return AppConstants.priorityDocumentKeywords.any(haystack.contains);
  }

  String? _extractDominantColorFromText(List<String> tags) {
    for (final entry in AppConstants.colorKeywords.entries) {
      if (tags.contains(entry.key)) {
        return entry.key;
      }
    }
    return null;
  }

  String _estimateDominantColor(img.Image image) {
    var red = 0;
    var green = 0;
    var blue = 0;
    var count = 0;
    final step = math.max(1, math.min(image.width, image.height) ~/ 24);
    for (var y = 0; y < image.height; y += step) {
      for (var x = 0; x < image.width; x += step) {
        final pixel = image.getPixel(x, y);
        red += pixel.r.toInt();
        green += pixel.g.toInt();
        blue += pixel.b.toInt();
        count++;
      }
    }

    if (count == 0) {
      return 'neutral';
    }

    final avgR = red / count;
    final avgG = green / count;
    final avgB = blue / count;

    if ((avgR - avgG).abs() < 18 && (avgG - avgB).abs() < 18) {
      if (avgR < 60) {
        return 'black';
      }
      if (avgR > 190) {
        return 'white';
      }
      return 'gray';
    }
    if (avgR > avgG && avgR > avgB) {
      if (avgG > avgB + 18) {
        return 'orange';
      }
      return 'red';
    }
    if (avgG > avgR && avgG > avgB) {
      if (avgR > avgB + 16) {
        return 'yellow';
      }
      return 'green';
    }
    if (avgB > avgR && avgB > avgG) {
      return 'blue';
    }
    return 'brown';
  }

  double _estimateBrightness(img.Image image) {
    var total = 0.0;
    var count = 0;
    final step = math.max(1, math.min(image.width, image.height) ~/ 24);
    for (var y = 0; y < image.height; y += step) {
      for (var x = 0; x < image.width; x += step) {
        final pixel = image.getPixel(x, y);
        total += 0.2126 * pixel.r + 0.7152 * pixel.g + 0.0722 * pixel.b;
        count++;
      }
    }
    return count == 0 ? 0 : total / count;
  }

  double _overlapScore(List<String> a, List<String> b) {
    if (a.isEmpty || b.isEmpty) {
      return 0;
    }
    final first = a.toSet();
    final second = b.toSet();
    final intersection = first.intersection(second).length;
    final denominator = math.max(first.length, second.length);
    return intersection / denominator;
  }

  double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
    if ((lat1 == 0 && lon1 == 0) || (lat2 == 0 && lon2 == 0)) {
      return double.infinity;
    }
    const radius = 6371.0;
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return radius * c;
  }

  double _degreesToRadians(double degrees) => degrees * math.pi / 180;

  bool _sameLabel(String left, String right) {
    return left.trim().toLowerCase() == right.trim().toLowerCase();
  }

  bool _isColorTag(String tag) => AppConstants.colorKeywords.keys.contains(tag);
}
