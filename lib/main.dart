// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:provider/provider.dart';
// import 'package:supervisor_proximity/splash_screen.dart';
// import 'controllers/fleet_controller.dart';
// import 'views/theme/app_theme.dart';
// import 'views/supervisor_shell.dart';

// void main() {
//   WidgetsFlutterBinding.ensureInitialized();
//   GoogleFonts.config.allowRuntimeFetching = false;
//   runApp(const SupervisorApp());
// }

// class SupervisorApp extends StatelessWidget {
//   const SupervisorApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return ChangeNotifierProvider(
//       create: (_) => FleetController(),
//       child: MaterialApp(
//         title: 'Proximity Guard — Supervisor',
//         debugShowCheckedModeBanner: false,
//         theme: AppTheme.lightTheme,
//         darkTheme: AppTheme.darkTheme,
//         themeMode: ThemeMode.system,
//         home: const SplashScreen(),
//       ),
//     );
//   }
// }






import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supervisor_proximity/splash_screen.dart';
import 'controllers/fleet_controller.dart';
import 'firebase_options.dart';
import 'views/theme/app_theme.dart';
import 'views/supervisor_shell.dart';
import 'controllers/theme_controller.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supervisor_proximity/services/auth_service.dart';
import 'controllers/locale_controller.dart';
import 'controllers/vehicle_types_controller.dart';
import 'controllers/project_sites_controller.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await AuthService.instance.init();
  runApp(const SupervisorApp());
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class SupervisorApp extends StatelessWidget {
  const SupervisorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FleetController()),
        ChangeNotifierProvider(create: (_) => ThemeController()),
        ChangeNotifierProvider(create: (_) => LocaleController()),
        ChangeNotifierProvider(create: (_) => VehicleTypesController()),
        ChangeNotifierProvider(create: (_) => ProjectSitesController()),
      ],
      child: Consumer<ThemeController>(
        builder: (context, themeController, child) {
          return MaterialApp(
            navigatorKey: navigatorKey,
            title: 'Proximity Guard — Supervisor',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeController.themeMode,
            locale: context.watch<LocaleController>().locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'),
              Locale('ar'),
              Locale('hi'),
            ],
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}