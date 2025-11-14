import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login_page.dart';
import 'screens/registration.dart';
import 'observer.dart';

void main() {
  runApp(MyBankApp());
}

class MyBankApp extends StatefulWidget {
  @override
  State<MyBankApp> createState() => _MyBankAppState();
}

class _MyBankAppState extends State<MyBankApp> {
  Widget _defaultScreen = RegistrationPage();

  @override
  void initState() {
    super.initState();
    _checkRegistration();
  }

  Future<void> _checkRegistration() async {
    final prefs = await SharedPreferences.getInstance();
    final registered = prefs.getBool("registered") ?? false;
    setState(() {
      _defaultScreen = registered ? LoginPage() : RegistrationPage();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dummy Bank App',
      navigatorObservers: [routeObserver],
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF3B5EDF),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        fontFamily: 'Roboto',
      ),
      home: _defaultScreen,
      routes: {
        '/login': (context) => LoginPage(),
        '/register': (context) => RegistrationPage(),
      },
    );
  }
}
