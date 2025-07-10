import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:incubatex_application/screens/StudentDashboard.dart';
import 'package:incubatex_application/screens/StudentDetailPage.dart';
import 'package:incubatex_application/screens/admin_dashboard.dart';
import 'package:incubatex_application/screens/deputy_director_dashboard.dart';
import 'package:incubatex_application/screens/director_dashboard.dart';
import 'package:incubatex_application/screens/mentor_dashboard.dart';
import 'package:incubatex_application/screens/splash_screen.dart';

import 'screens/landing_page.dart';
import 'screens/login_page.dart';
import 'screens/registration_page.dart';
import 'screens/profile_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    // options: FirebaseOptions(
    //   apiKey: "AIzaSyDj_3tcuNjmsL8P4sxdTGVxv7E9yXl5ztQ",
    //   appId: "1:185594212202:web:d27adc23fb04dff064bf13",
    //   messagingSenderId: "185594212202",
    //   projectId: "incubatex-38e09")
    );
  runApp(const IncubateXApp());
}

class IncubateXApp extends StatelessWidget {
  const IncubateXApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IncubateX',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: const Color(0xFF121212),
        textTheme: const TextTheme(bodyMedium: TextStyle(color: Colors.white)),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/landing': (context) => const LandingPage(),
        '/admin_dashboard': (context) => const AdminDashboard(),
        '/login': (context) => const LoginPage(),
        '/student_dashboard': (context) => const StudentDashboard(),
        '/profile': (context) => const ProfilePage(),
        '/register': (context) => const RegistrationPage(),

        // 💡 Add this route for student detail navigation
        '/student_detail': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map;
          return StudentDetailPage(uid: args['uid'], data: args['data']);
        },
        '/director_dashboard': (context) => const DirectorDashboard(),
        '/deputy_director_dashboard': (context) => const DeputyDirectorDashboard(),
        '/mentor_dashboard': (context) => const MentorDashboard(),
      },
    );
  }
}
