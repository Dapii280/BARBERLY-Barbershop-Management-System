import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/api_client.dart';
import 'core/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/barber_provider.dart';
import 'providers/booking_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/service_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/user_provider.dart';
import 'repositories/auth_repository.dart';
import 'repositories/barber_repository.dart';
import 'repositories/booking_repository.dart';
import 'repositories/dashboard_repository.dart';
import 'repositories/service_repository.dart';
import 'repositories/transaction_repository.dart';
import 'repositories/user_repository.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/main_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ApiClient.instance.init();

  final localeProvider = LocaleProvider();
  await localeProvider.load();

  runApp(BarberlyApp(localeProvider: localeProvider));
}

class BarberlyApp extends StatelessWidget {
  const BarberlyApp({super.key, required this.localeProvider});

  final LocaleProvider localeProvider;

  @override
  Widget build(BuildContext context) {
    final authRepository = AuthRepository();
    final userRepository = UserRepository();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider),
        ChangeNotifierProvider(
          create: (_) {
            final auth = AuthProvider(authRepository, userRepository);
            // Logout otomatis saat server mengembalikan 401.
            ApiClient.instance.onUnauthorized = () => auth.logout();
            return auth;
          },
        ),
        ChangeNotifierProvider(create: (_) => ServiceProvider(ServiceRepository())),
        ChangeNotifierProvider(create: (_) => BarberProvider(BarberRepository())),
        ChangeNotifierProvider(create: (_) => BookingProvider(BookingRepository())),
        ChangeNotifierProvider(
          create: (_) => TransactionProvider(TransactionRepository()),
        ),
        ChangeNotifierProvider(create: (_) => DashboardProvider(DashboardRepository())),
        ChangeNotifierProvider(create: (_) => UserProvider(userRepository)),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, locale, _) {
          return MaterialApp(
            title: 'Barberly',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            locale: Locale(locale.languageCode),
            supportedLocales: const [Locale('id'), Locale('en')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const _AuthGate(),
          );
        },
      ),
    );
  }
}

/// Menentukan halaman awal berdasarkan status autentikasi pengguna.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.initialized) {
      return const SplashScreen();
    }

    if (auth.user == null) {
      return const LoginScreen();
    }

    return const MainShell();
  }
}
