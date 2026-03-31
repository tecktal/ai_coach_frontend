import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'data/providers/auth_provider.dart';
import 'data/providers/recording_provider.dart';
import 'data/providers/analysis_provider.dart';
import 'data/providers/chat_provider.dart';
import 'data/providers/theme_provider.dart';
import 'presentation/screens/splash_screen.dart';
import 'core/theme/app_theme.dart';
import 'presentation/widgets/country_customization.dart';

import 'data/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  ));
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => RecordingProvider()),
        ChangeNotifierProvider(create: (_) => AnalysisProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer2<ThemeProvider, AuthProvider>(
        builder: (context, themeProvider, authProvider, _) {
          final country = authProvider.user?.country;
          final isCustom = CountryCustomization.isCustomized(country);
          final customColor = isCustom ? CountryCustomization.getAccentColor(country) : null;

          return MaterialApp(
            title: 'AI Teaching Coach',
            theme: AppTheme.getLightTheme(customColor),
            darkTheme: AppTheme.getDarkTheme(customColor),
            themeMode: themeProvider.themeMode,
            home: const SplashScreen(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
