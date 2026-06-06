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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const SupervisorApp());
}

class SupervisorApp extends StatelessWidget {
  const SupervisorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FleetController(),
      child: MaterialApp(
        title: 'Proximity Guard — Supervisor',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        
        home: const SplashScreen(),
      ),
    );
  }
}