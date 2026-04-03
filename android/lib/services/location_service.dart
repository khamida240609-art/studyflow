import 'package:geolocator/geolocator.dart';

class LocationLookupResult {
  const LocationLookupResult({required this.position, required this.message});

  final Position? position;
  final String? message;

  bool get hasPosition => position != null;
}

class LocationService {
  static const double fallbackLatitude = 48.0196;
  static const double fallbackLongitude = 66.9237;
  static const String fallbackLocationLabel = 'Центр Казахстана';

  Future<LocationLookupResult> determinePosition({
    bool requestPermission = true,
  }) async {
    try {
      final isEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isEnabled) {
        return const LocationLookupResult(
          position: null,
          message:
              'Службы геолокации отключены. Используем безопасную точку по центру Казахстана.',
        );
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied && requestPermission) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever ||
          permission == LocationPermission.unableToDetermine) {
        return const LocationLookupResult(
          position: null,
          message:
              'Доступ к геолокации недоступен. Используем безопасную точку по центру Казахстана.',
        );
      }

      final position = await Geolocator.getCurrentPosition().timeout(
        const Duration(seconds: 8),
      );

      return LocationLookupResult(position: position, message: null);
    } catch (_) {
      return const LocationLookupResult(
        position: null,
        message:
            'Геолокация недоступна на этом устройстве или эмуляторе. Используем центр Казахстана.',
      );
    }
  }
}
