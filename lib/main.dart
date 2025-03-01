import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'authentication/authentication.dart';

void main() async
{
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
      options: const FirebaseOptions(
          apiKey: "AIzaSyD5nE1PnZlE6THwe3qL0mGKrqtElSx_vK0",
          authDomain: "flutter-tric-go-with-adm-a01de.firebaseapp.com",
          databaseURL: "https://flutter-tric-go-with-adm-a01de-default-rtdb.asia-southeast1.firebasedatabase.app",
          projectId: "flutter-tric-go-with-adm-a01de",
          storageBucket: "flutter-tric-go-with-adm-a01de.appspot.com",
          messagingSenderId: "234714556164",
          appId: "1:234714556164:web:a87a8965664bcdaae05251",
          measurementId: "G-SSJV04YLF7"
      )
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tric-Go Web Panel',
      theme: ThemeData(
        primarySwatch: Colors.cyan,
    ),
      home: Authentication(),
    );
  }
}

