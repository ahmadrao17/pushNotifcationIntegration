import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:notification/Services/notification.dart';
import 'package:notification/firebase_options.dart';
import 'package:notification/homepage.dart';
import 'package:timezone/data/latest.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackground);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  tz.initializeTimeZones();
  // NotificationApi.init();

  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );
  // FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackground);
  // tz.initializeTimeZones();
  runApp(const MyApp());
  // await NotificationServices.init();
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackground(RemoteMessage message) async {
// print("back ground noti:::: ${message.notification!.title}");
  await Firebase.initializeApp();
}

// //await NotificationServices.init();
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}
