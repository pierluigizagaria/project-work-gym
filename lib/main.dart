import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:univeristy/provider/category_provider.dart';
import 'package:univeristy/settings/auth.dart';

import 'package:univeristy/provider/user_provider.dart';
import 'provider/coach_provider.dart';
import 'provider/gym_provider.dart';
import 'settings/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const App());
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => CategoryProvider()),
        ChangeNotifierProvider(create: (context) => UserProvider()),
        ChangeNotifierProvider(create: (context) => GymProvider()),
        ChangeNotifierProvider(create: (context) => CoachProvider()),
      ],
      child: MaterialApp(
          theme: ThemeData().copyWith(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
                seedColor: const Color.fromARGB(255, 0, 143, 30)),
          ),
          home: const AuthScreen()),
    );
  }
}
