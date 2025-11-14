import 'package:flutter/material.dart';

void main() {
  runApp(MyBasicApp());
}

class MyBasicApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Basic App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF3B5EDF),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        fontFamily: 'Roboto',
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text("Home Page"),
        ),
        body: Center(
          child: Text(
            "Welcome to the Basic App!",
            style: TextStyle(fontSize: 20),
          ),
        ),
      ),
    );
  }
}
