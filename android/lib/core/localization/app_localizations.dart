import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = [Locale('ru'), Locale('kk'), Locale('en')];

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    AppLocalizationsDelegate(),
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'home': 'Home',
      'search': 'Search',
      'create': 'Create',
      'chats': 'Chats',
      'profile': 'Profile',
      'settings': 'Settings',
      'notifications': 'Notifications',
      'saved_posts': 'Saved posts',
      'community_board': 'Community board',
      'map_view': 'Map view',
      'edit_profile': 'Edit profile',
      'admin_panel': 'Admin panel',
      'language': 'Language',
      'theme': 'Theme',
      'system_theme': 'System',
      'light_theme': 'Light',
      'dark_theme': 'Dark',
      'login': 'Log in',
      'sign_up': 'Sign up',
      'display_name': 'Display name',
      'email': 'Email',
      'password': 'Password',
      'welcome_back': 'Welcome back',
      'sign_in': 'Sign in',
      'create_account': 'Create account',
      'already_have_account': 'I already have an account',
      'back_to_login': 'Back to login',
      'skip': 'Skip',
      'next': 'Next',
      'start_with_lostly': 'Start with Lostly',
      'match_alerts': 'Match alerts',
      'message_alerts': 'Message alerts',
      'location_hints': 'Location suggestions',
      'about_lostly': 'About Lostly',
      'lost_items_feed': 'Lost items feed',
      'found_items_feed': 'Found items feed',
      'report_lost_item': 'Report lost item',
      'report_found_item': 'Report found item',
      'open_qr_scanner': 'Open QR scanner',
      'saved_posts_empty_title': 'Nothing saved yet',
      'saved_posts_empty_subtitle':
          'Bookmark posts you want to revisit and compare later.',
      'logout': 'Log out',
      'lost_something': 'Lost something',
      'found_something': 'Found something',
      'communities': 'Communities',
      'my_posts': 'My posts',
      'say_hello': 'Say hello',
      'send_first_message': 'Send first message',
      'no_chats_yet': 'No chats yet',
      'back': 'Back',
      'appearance': 'Appearance',
      'app_language': 'App language',
    },
    'ru': {
      'home': 'Главная',
      'search': 'Поиск',
      'create': 'Создать',
      'chats': 'Чаты',
      'profile': 'Профиль',
      'settings': 'Настройки',
      'notifications': 'Уведомления',
      'saved_posts': 'Сохранённые',
      'community_board': 'Сообщества',
      'map_view': 'Карта',
      'edit_profile': 'Редактировать профиль',
      'admin_panel': 'Админ-панель',
      'language': 'Язык',
      'theme': 'Тема',
      'system_theme': 'Системная',
      'light_theme': 'Светлая',
      'dark_theme': 'Тёмная',
      'login': 'Войти',
      'sign_up': 'Регистрация',
      'display_name': 'Имя профиля',
      'email': 'Email',
      'password': 'Пароль',
      'welcome_back': 'С возвращением',
      'sign_in': 'Вход',
      'create_account': 'Создать аккаунт',
      'already_have_account': 'У меня уже есть аккаунт',
      'back_to_login': 'Назад ко входу',
      'skip': 'Пропустить',
      'next': 'Далее',
      'start_with_lostly': 'Начать с Lostly',
      'match_alerts': 'Уведомления о совпадениях',
      'message_alerts': 'Уведомления о сообщениях',
      'location_hints': 'Подсказки по локации',
      'about_lostly': 'О Lostly',
      'lost_items_feed': 'Лента потерянных вещей',
      'found_items_feed': 'Лента найденных вещей',
      'report_lost_item': 'Сообщить о потере',
      'report_found_item': 'Сообщить о находке',
      'open_qr_scanner': 'Открыть QR-сканер',
      'saved_posts_empty_title': 'Пока ничего не сохранено',
      'saved_posts_empty_subtitle':
          'Сохраняйте посты, чтобы быстро вернуться к ним позже.',
      'logout': 'Выйти',
      'lost_something': 'Потерял вещь',
      'found_something': 'Нашёл вещь',
      'communities': 'Сообщества',
      'my_posts': 'Мои посты',
      'say_hello': 'Напишите первым',
      'send_first_message': 'Отправить первое сообщение',
      'no_chats_yet': 'Чатов пока нет',
      'back': 'Назад',
      'appearance': 'Внешний вид',
      'app_language': 'Язык приложения',
    },
    'kk': {
      'home': 'Басты бет',
      'search': 'Іздеу',
      'create': 'Қосу',
      'chats': 'Чаттар',
      'profile': 'Профиль',
      'settings': 'Баптаулар',
      'notifications': 'Хабарламалар',
      'saved_posts': 'Сақталғандар',
      'community_board': 'Қауымдастықтар',
      'map_view': 'Карта',
      'edit_profile': 'Профильді өңдеу',
      'admin_panel': 'Админ панелі',
      'language': 'Тіл',
      'theme': 'Тақырып',
      'system_theme': 'Жүйелік',
      'light_theme': 'Ашық',
      'dark_theme': 'Қараңғы',
      'login': 'Кіру',
      'sign_up': 'Тіркелу',
      'display_name': 'Атыңыз',
      'email': 'Email',
      'password': 'Құпиясөз',
      'welcome_back': 'Қайта қош келдің',
      'sign_in': 'Кіру',
      'create_account': 'Аккаунт ашу',
      'already_have_account': 'Менде аккаунт бар',
      'back_to_login': 'Кіруге қайту',
      'skip': 'Өткізу',
      'next': 'Келесі',
      'start_with_lostly': 'Lostly-мен бастау',
      'match_alerts': 'Сәйкестік хабарламалары',
      'message_alerts': 'Хабарлама ескертулері',
      'location_hints': 'Локация ұсыныстары',
      'about_lostly': 'Lostly туралы',
      'lost_items_feed': 'Жоғалған заттар лентасы',
      'found_items_feed': 'Табылған заттар лентасы',
      'report_lost_item': 'Жоғалған затты жариялау',
      'report_found_item': 'Табылған затты жариялау',
      'open_qr_scanner': 'QR сканерді ашу',
      'saved_posts_empty_title': 'Әзірге сақталған жоқ',
      'saved_posts_empty_subtitle':
          'Кейін тез ашу үшін посттарды сақтап қойыңыз.',
      'logout': 'Шығу',
      'lost_something': 'Зат жоғалттым',
      'found_something': 'Зат таптым',
      'communities': 'Қауымдастықтар',
      'my_posts': 'Менің посттарым',
      'say_hello': 'Алғашқы хабарлама жазыңыз',
      'send_first_message': 'Алғашқы хабарлама жіберу',
      'no_chats_yet': 'Әзірге чат жоқ',
      'back': 'Артқа',
      'appearance': 'Көрініс',
      'app_language': 'Қолданба тілі',
    },
  };

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  String _text(String key) {
    return _localizedValues[locale.languageCode]?[key] ??
        _localizedValues['ru']![key]!;
  }

  String get home => _text('home');
  String get search => _text('search');
  String get create => _text('create');
  String get chats => _text('chats');
  String get profile => _text('profile');
  String get settings => _text('settings');
  String get notifications => _text('notifications');
  String get savedPosts => _text('saved_posts');
  String get communityBoard => _text('community_board');
  String get mapView => _text('map_view');
  String get editProfile => _text('edit_profile');
  String get adminPanel => _text('admin_panel');
  String get language => _text('language');
  String get theme => _text('theme');
  String get systemTheme => _text('system_theme');
  String get lightTheme => _text('light_theme');
  String get darkTheme => _text('dark_theme');
  String get login => _text('login');
  String get signUp => _text('sign_up');
  String get displayName => _text('display_name');
  String get email => _text('email');
  String get password => _text('password');
  String get welcomeBack => _text('welcome_back');
  String get signIn => _text('sign_in');
  String get createAccount => _text('create_account');
  String get alreadyHaveAccount => _text('already_have_account');
  String get backToLogin => _text('back_to_login');
  String get skip => _text('skip');
  String get next => _text('next');
  String get startWithLostly => _text('start_with_lostly');
  String get matchAlerts => _text('match_alerts');
  String get messageAlerts => _text('message_alerts');
  String get locationHints => _text('location_hints');
  String get aboutLostly => _text('about_lostly');
  String get lostItemsFeed => _text('lost_items_feed');
  String get foundItemsFeed => _text('found_items_feed');
  String get reportLostItem => _text('report_lost_item');
  String get reportFoundItem => _text('report_found_item');
  String get openQrScanner => _text('open_qr_scanner');
  String get savedPostsEmptyTitle => _text('saved_posts_empty_title');
  String get savedPostsEmptySubtitle => _text('saved_posts_empty_subtitle');
  String get logout => _text('logout');
  String get lostSomething => _text('lost_something');
  String get foundSomething => _text('found_something');
  String get communities => _text('communities');
  String get myPosts => _text('my_posts');
  String get sayHello => _text('say_hello');
  String get sendFirstMessage => _text('send_first_message');
  String get noChatsYet => _text('no_chats_yet');
  String get back => _text('back');
  String get appearance => _text('appearance');
  String get appLanguage => _text('app_language');

  String greeting(String name) {
    switch (locale.languageCode) {
      case 'ru':
        return 'Привет, $name';
      case 'kk':
        return 'Сәлем, $name';
      default:
        return 'Привет, $name';
    }
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales.any(
      (supported) => supported.languageCode == locale.languageCode,
    );
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) {
    return false;
  }
}

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
