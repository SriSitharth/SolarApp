import 'package:flutter/material.dart';
import 'package:inventory/homepage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future main() async {
   WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Power Inventory',
      theme: ThemeData(
        //colorScheme: ColorScheme.fromSeed(
        //    seedColor: const Color.fromARGB(255, 58, 108, 183)),
        //useMaterial3: true,
        cardColor: Colors.white,
        primarySwatch:  Colors.orange,
      ),
      home: const MyHomePage(),
      //To remove the debug banner
      debugShowCheckedModeBanner: false,
    );
  }
}