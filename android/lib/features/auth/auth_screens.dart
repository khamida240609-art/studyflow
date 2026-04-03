import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/utils/build_context_x.dart';
import '../../core/utils/form_validators.dart';
import '../../providers/app_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.heroGradient),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
                child: const Icon(
                  Icons.travel_explore_rounded,
                  color: Colors.white,
                  size: 42,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                AppConstants.appName,
                style: Theme.of(
                  context,
                ).textTheme.displayMedium?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 10),
              Text(
                AppConstants.tagline,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 28),
              const CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _pageIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await ref.read(onboardingProvider.notifier).complete();
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final slides = _localizedSlides(context);
    final isLast = _pageIndex == slides.length - 1;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.heroGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(onPressed: _finish, child: Text(l10n.skip)),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: slides.length,
                    onPageChanged: (value) =>
                        setState(() => _pageIndex = value),
                    itemBuilder: (context, index) {
                      final slide = slides[index];
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(36),
                            ),
                            child: Icon(
                              slide.icon,
                              size: 54,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 36),
                          Text(
                            slide.title,
                            style: Theme.of(context).textTheme.displayMedium
                                ?.copyWith(color: Colors.white),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            slide.subtitle,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.84),
                                ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                Row(
                  children: List.generate(
                    slides.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 240),
                      margin: const EdgeInsets.only(right: 8),
                      width: index == _pageIndex ? 28 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: index == _pageIndex
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                AppButton(
                  label: isLast ? l10n.startWithLostly : l10n.next,
                  onPressed: () async {
                    if (isLast) {
                      await _finish();
                    } else {
                      await _pageController.nextPage(
                        duration: const Duration(milliseconds: 320),
                        curve: Curves.easeOutCubic,
                      );
                    }
                  },
                ),
                const SizedBox(height: 12),
                AppButton(
                  label: l10n.alreadyHaveAccount,
                  onPressed: () async {
                    await ref.read(onboardingProvider.notifier).complete();
                    if (mounted) {
                      context.go('/login');
                    }
                  },
                  isSecondary: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    try {
      await ref
          .read(authControllerProvider.notifier)
          .signIn(
            email: _emailController.text,
            password: _passwordController.text,
          );
      if (mounted) {
        context.go('/home');
      }
    } catch (error) {
      if (mounted) {
        context.showErrorSnackBar(_friendlyAuthError(context, error));
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      final didSignIn = await ref
          .read(authControllerProvider.notifier)
          .signInWithGoogle();
      if (!mounted) {
        return;
      }
      if (!didSignIn) {
        context.showAppSnackBar(
          _localizedAuthText(context, 'google_cancelled'),
        );
        return;
      }
      context.go('/home');
    } catch (error) {
      if (mounted) {
        context.showErrorSnackBar(_friendlyAuthError(context, error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final l10n = context.l10n;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 220,
                decoration: BoxDecoration(
                  gradient: AppTheme.heroGradient,
                  borderRadius: BorderRadius.circular(36),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      l10n.welcomeBack,
                      style: Theme.of(
                        context,
                      ).textTheme.displayMedium?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _localizedAuthText(context, 'login_hero_subtitle'),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.84),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text(
                l10n.signIn,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                _localizedAuthText(context, 'login_screen_subtitle'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    AppTextField(
                      controller: _emailController,
                      label: l10n.email,
                      hint: 'you@example.com',
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.alternate_email_rounded,
                      validator: (value) => _emailValidator(context, value),
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      controller: _passwordController,
                      label: l10n.password,
                      obscureText: true,
                      prefixIcon: Icons.lock_outline_rounded,
                      validator: (value) => _passwordValidator(context, value),
                    ),
                    const SizedBox(height: 20),
                    AppButton(
                      label: l10n.login,
                      onPressed: _submit,
                      isLoading: authState.isLoading,
                    ),
                    const SizedBox(height: 14),
                    _GoogleSignInButton(
                      label: _localizedAuthText(context, 'google_button'),
                      onPressed: authState.isLoading ? null : _signInWithGoogle,
                      isLoading: authState.isLoading,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => context.go('/signup'),
                  child: Text(l10n.createAccount),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    try {
      await ref
          .read(authControllerProvider.notifier)
          .signUp(
            displayName: _nameController.text,
            email: _emailController.text,
            password: _passwordController.text,
          );
      if (mounted) {
        context.go('/home');
      }
    } catch (error) {
      if (mounted) {
        context.showErrorSnackBar(_friendlyAuthError(context, error));
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      final didSignIn = await ref
          .read(authControllerProvider.notifier)
          .signInWithGoogle();
      if (!mounted) {
        return;
      }
      if (!didSignIn) {
        context.showAppSnackBar(
          _localizedAuthText(context, 'google_cancelled'),
        );
        return;
      }
      context.go('/home');
    } catch (error) {
      if (mounted) {
        context.showErrorSnackBar(_friendlyAuthError(context, error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final l10n = context.l10n;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextButton.icon(
                onPressed: () => context.go('/login'),
                icon: const Icon(Icons.arrow_back_rounded),
                label: Text(l10n.backToLogin),
              ),
              const SizedBox(height: 12),
              Container(
                height: 180,
                decoration: BoxDecoration(
                  gradient: AppTheme.foundGradient,
                  borderRadius: BorderRadius.circular(36),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      _localizedAuthText(context, 'signup_hero_title'),
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _localizedAuthText(context, 'signup_hero_subtitle'),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    AppTextField(
                      controller: _nameController,
                      label: l10n.displayName,
                      hint: 'Alex Rivera',
                      prefixIcon: Icons.person_outline_rounded,
                      validator: (value) =>
                          _requiredValidator(context, value, l10n.displayName),
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      controller: _emailController,
                      label: l10n.email,
                      hint: 'you@example.com',
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.alternate_email_rounded,
                      validator: (value) => _emailValidator(context, value),
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      controller: _passwordController,
                      label: l10n.password,
                      obscureText: true,
                      prefixIcon: Icons.lock_outline_rounded,
                      validator: (value) => _passwordValidator(context, value),
                    ),
                    const SizedBox(height: 20),
                    AppButton(
                      label: l10n.createAccount,
                      onPressed: _submit,
                      isLoading: authState.isLoading,
                    ),
                    const SizedBox(height: 14),
                    _GoogleSignInButton(
                      label: _localizedAuthText(context, 'google_button'),
                      onPressed: authState.isLoading ? null : _signInWithGoogle,
                      isLoading: authState.isLoading,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => context.go('/login'),
                  child: Text('${l10n.alreadyHaveAccount}? ${l10n.login}'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;
}

class _GoogleSignInButton extends StatelessWidget {
  const _GoogleSignInButton({
    required this.label,
    required this.onPressed,
    required this.isLoading,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          backgroundColor: theme.colorScheme.surface,
          side: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colorScheme.primary,
                ),
              )
            else
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.08),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  'G',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.teal,
                  ),
                ),
              ),
            const SizedBox(width: 12),
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

List<_OnboardingSlide> _localizedSlides(BuildContext context) {
  switch (Localizations.localeOf(context).languageCode) {
    case 'ru':
      return const [
        _OnboardingSlide(
          title: 'Находите важное без хаоса',
          subtitle:
              'Lostly превращает разрозненные доски объявлений в одно стильное пространство в реальном времени.',
          icon: Icons.search_rounded,
        ),
        _OnboardingSlide(
          title: 'Публикуйте, находите совпадения и пишите за минуты',
          subtitle:
              'Создавайте посты о потерянных и найденных вещах, получайте умные подсказки и быстро выходите на связь.',
          icon: Icons.forum_rounded,
        ),
        _OnboardingSlide(
          title: 'Безопасное подтверждение и возврат',
          subtitle:
              'QR, проверка владельца и понятные статусы делают возврат спокойнее и надёжнее.',
          icon: Icons.verified_user_rounded,
        ),
      ];
    case 'kk':
      return const [
        _OnboardingSlide(
          title: 'Маңызды затыңызды бейберекетсіз табыңыз',
          subtitle:
              'Lostly жоғалған заттар хабарландыруларын бір әдемі, нақты уақыттағы кеңістікке біріктіреді.',
          icon: Icons.search_rounded,
        ),
        _OnboardingSlide(
          title: 'Жариялаңыз, сәйкестікті табыңыз, бірден жазыңыз',
          subtitle:
              'Жоғалған не табылған затты жариялап, смарт ұсыныстар алып, керек адаммен тез байланыса аласыз.',
          icon: Icons.forum_rounded,
        ),
        _OnboardingSlide(
          title: 'Сенімді растау және қауіпсіз қайтару',
          subtitle:
              'QR, меншік иесін тексеру және анық статустар затты иесіне сенімді түрде қайтаруға көмектеседі.',
          icon: Icons.verified_user_rounded,
        ),
      ];
    default:
      return const [
        _OnboardingSlide(
          title: 'Find what matters without the chaos',
          subtitle:
              'Lostly turns scattered lost-and-found boards into one polished real-time space.',
          icon: Icons.search_rounded,
        ),
        _OnboardingSlide(
          title: 'Post, match and message in minutes',
          subtitle:
              'Create lost or found posts, discover smart suggestions, then talk directly to the right person.',
          icon: Icons.forum_rounded,
        ),
        _OnboardingSlide(
          title: 'Claim with trust, return with confidence',
          subtitle:
              'Use QR identity, ownership checks and clean status tracking for safer returns.',
          icon: Icons.verified_user_rounded,
        ),
      ];
  }
}

String _localizedAuthText(BuildContext context, String key) {
  switch (Localizations.localeOf(context).languageCode) {
    case 'ru':
      switch (key) {
        case 'login_hero_subtitle':
          return 'Возвращайтесь к совпадениям, чатам и безопасным возвратам в реальном времени.';
        case 'login_screen_subtitle':
          return 'Войдите через email, чтобы продолжить работу в Lostly.';
        case 'google_button':
          return 'Войти через Google';
        case 'google_cancelled':
          return 'Вход через Google отменён.';
        case 'signup_hero_title':
          return 'Создайте свой профиль';
        case 'signup_hero_subtitle':
          return 'Начните публиковать, сканировать QR-метки и получать уведомления о совпадениях.';
      }
      break;
    case 'kk':
      switch (key) {
        case 'login_hero_subtitle':
          return 'Сәйкестіктерге, чаттарға және қауіпсіз қайтару процестеріне қайта қосылыңыз.';
        case 'login_screen_subtitle':
          return 'Lostly сессияңызды жалғастыру үшін email арқылы кіріңіз.';
        case 'google_button':
          return 'Google арқылы кіру';
        case 'google_cancelled':
          return 'Google арқылы кіру тоқтатылды.';
        case 'signup_hero_title':
          return 'Профиліңізді жасаңыз';
        case 'signup_hero_subtitle':
          return 'Пост жариялап, QR белгілерін сканерлеп, сәйкестік хабарламаларын ала бастаңыз.';
      }
      break;
  }

  switch (key) {
    case 'login_hero_subtitle':
      return 'Jump into live matches, chats and secure return flows.';
    case 'login_screen_subtitle':
      return 'Use your email to continue your Lostly session.';
    case 'google_button':
      return 'Continue with Google';
    case 'google_cancelled':
      return 'Google sign-in was cancelled.';
    case 'signup_hero_title':
      return 'Create your profile';
    case 'signup_hero_subtitle':
      return 'Start posting, scanning QR tags and receiving match alerts.';
    default:
      return '';
  }
}

String? _requiredValidator(BuildContext context, String? value, String label) {
  if (value != null && value.trim().isNotEmpty) {
    return null;
  }

  switch (Localizations.localeOf(context).languageCode) {
    case 'ru':
      return 'Поле "$label" обязательно';
    case 'kk':
      return '"$label" өрісі міндетті';
    default:
      return FormValidators.required(value, label);
  }
}

String? _emailValidator(BuildContext context, String? value) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) {
    switch (Localizations.localeOf(context).languageCode) {
      case 'ru':
        return 'Email обязателен';
      case 'kk':
        return 'Email міндетті';
    }
  }

  final base = FormValidators.email(value);
  if (base == null) {
    return null;
  }

  switch (Localizations.localeOf(context).languageCode) {
    case 'ru':
      return 'Введите корректный email';
    case 'kk':
      return 'Дұрыс email енгізіңіз';
    default:
      return base;
  }
}

String _friendlyAuthError(BuildContext context, Object error) {
  if (error is Exception) {
    final raw = error.toString();
    if (raw.contains('missing-google-id-token')) {
      switch (Localizations.localeOf(context).languageCode) {
        case 'ru':
          return 'Не удалось получить данные Google. Повторите попытку.';
        case 'kk':
          return 'Google деректерін алу мүмкін болмады. Қайта көріңіз.';
        default:
          return 'Could not get Google account data. Please try again.';
      }
    }
    if (raw.contains('missing-server-client-id')) {
      switch (Localizations.localeOf(context).languageCode) {
        case 'ru':
          return 'Не настроен serverClientId для Android Google Sign-In. Добавьте Web client ID из Firebase/Google Cloud.';
        case 'kk':
          return 'Android Google Sign-In үшін serverClientId бапталмаған. Firebase/Google Cloud ішіндегі Web client ID мәнін қосыңыз.';
        default:
          return 'Android Google Sign-In is missing serverClientId. Add the Web client ID from Firebase/Google Cloud.';
      }
    }
    if (raw.contains('providerconfigurationerror') ||
        raw.contains('no provider dependencies found') ||
        raw.contains('getcredentialasync')) {
      switch (Localizations.localeOf(context).languageCode) {
        case 'ru':
          return 'Android Google Sign-In настроен не полностью. Обновите google-services.json после создания Web OAuth client и заново соберите приложение.';
        case 'kk':
          return 'Android Google Sign-In толық бапталмаған. Web OAuth client жасағаннан кейін google-services.json файлын жаңартып, қолданбаны қайта жинаңыз.';
        default:
          return 'Android Google Sign-In is not fully configured. Refresh google-services.json after creating the Web OAuth client and rebuild the app.';
      }
    }
    if (raw.contains('account-exists-with-different-credential')) {
      switch (Localizations.localeOf(context).languageCode) {
        case 'ru':
          return 'Этот email уже зарегистрирован другим способом входа.';
        case 'kk':
          return 'Бұл email басқа кіру тәсілімен тіркелген.';
        default:
          return 'This email is already registered with a different sign-in method.';
      }
    }
    if (raw.contains('invalid-credential')) {
      switch (Localizations.localeOf(context).languageCode) {
        case 'ru':
          return 'Учётные данные недействительны. Повторите попытку.';
        case 'kk':
          return 'Кіру деректері жарамсыз. Қайта көріңіз.';
        default:
          return 'The credentials are invalid. Please try again.';
      }
    }
  }

  return '$error';
}

String? _passwordValidator(BuildContext context, String? value) {
  if (value == null || value.isEmpty) {
    switch (Localizations.localeOf(context).languageCode) {
      case 'ru':
        return 'Пароль обязателен';
      case 'kk':
        return 'Құпиясөз міндетті';
    }
  }

  if ((value?.length ?? 0) < 6) {
    switch (Localizations.localeOf(context).languageCode) {
      case 'ru':
        return 'Используйте минимум 6 символов';
      case 'kk':
        return 'Кемінде 6 таңба қолданыңыз';
    }
  }

  return FormValidators.password(value);
}
