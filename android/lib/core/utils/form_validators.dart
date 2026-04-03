class FormValidators {
  static String? required(String? value, [String label = 'Поле']) {
    if (value == null || value.trim().isEmpty) {
      return 'Поле "$label" обязательно';
    }
    return null;
  }

  static String? email(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Email обязателен';
    }
    final emailRegExp = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegExp.hasMatch(trimmed)) {
      return 'Введите корректный email';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Пароль обязателен';
    }
    if (value.length < 6) {
      return 'Используйте минимум 6 символов';
    }
    return null;
  }
}
