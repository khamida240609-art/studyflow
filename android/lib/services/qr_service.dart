class QrService {
  String buildQrValue(String itemId) => 'lostly:item:$itemId';

  String generateItemCode({required String postId, required String type}) {
    final prefix = type.toLowerCase() == 'found' ? 'LFD' : 'LLS';
    final hash = postId.replaceAll('-', '').toUpperCase();
    final suffix = hash.length >= 8 ? hash.substring(0, 8) : hash;
    return '$prefix-$suffix';
  }

  String? parseItemId(String rawValue) {
    if (rawValue.startsWith('lostly:item:')) {
      return rawValue.replaceFirst('lostly:item:', '');
    }
    return null;
  }
}
