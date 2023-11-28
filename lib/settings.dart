import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart';
import 'package:timezone/data/latest.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ignore: camel_case_types
class settings extends StatefulWidget {
  const settings({Key? key}): super(key: key);

  @override
  State<settings> createState() => _settingsState();
}

// ignore: camel_case_types
class _settingsState extends State<settings> {
  FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  TimeOfDay? morningTime;
  TimeOfDay? eveningTime;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    initializeNotifications();
    initializeTimeZones();
    loadLastSelectedTimes();
  }

  void loadLastSelectedTimes() async {
    try {
      // Fetch last selected times from Firebase
      final DocumentSnapshot<Map<String, dynamic>> snapshot = await _firestore
          .collection('settings')
          .doc('lastSelectedTimes')
          .get();

      if (snapshot.exists) {
        final data = snapshot.data()!;
        setState(() {
          morningTime = TimeOfDay(
            hour: data['morningHour'],
            minute: data['morningMinute'],
          );
          eveningTime = TimeOfDay(
            hour: data['eveningHour'],
            minute: data['eveningMinute'],
          );
        });
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading last selected times : $e'),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  void saveLastSelectedTimes() async {
    try {
      // Save last selected times to Firebase
      await _firestore.collection('settings').doc('lastSelectedTimes').set({
        'morningHour': morningTime?.hour ?? 0,
        'morningMinute': morningTime?.minute ?? 0,
        'eveningHour': eveningTime?.hour ?? 0,
        'eveningMinute': eveningTime?.minute ?? 0,
      });
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving last selected times : $e'),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  void initializeNotifications() async {
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('app_icon');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: androidInitializationSettings);
    await notificationsPlugin.initialize(initializationSettings);
  }

  Future<void> scheduleMorningNotification() async {
    if (morningTime != null) {
      final DateTime now = DateTime.now();
       DateTime morning = DateTime(
        now.year,
        now.month,
        now.day,
        morningTime!.hour,
        morningTime!.minute,
      );

      if (morning.isBefore(now)) {
        morning = morning.add(const Duration(days: 1));
      }

      const AndroidNotificationDetails androidNotificationDetails =
          AndroidNotificationDetails(
        'channelId',
        'channelName',
        importance: Importance.high,
        priority: Priority.high,
      );

      const NotificationDetails notificationDetails =
          NotificationDetails(android: androidNotificationDetails);
      const String timeZoneName = 'Asia/Kolkata';
      late Location location = getLocation(timeZoneName);

      await notificationsPlugin.zonedSchedule(
        0,
        'Morning Notification',
        'Update the EB Readings',
        TZDateTime.from(morning, location),
        notificationDetails,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  Future<void> scheduleEveningNotification() async {
    if (eveningTime != null) {
      final DateTime now = DateTime.now();
       DateTime evening = DateTime(
        now.year,
        now.month,
        now.day,
        eveningTime!.hour,
        eveningTime!.minute,
      );

      if (evening.isBefore(now)) {
        evening = evening.add(const Duration(days: 1));
      }

      const AndroidNotificationDetails androidNotificationDetails =
          AndroidNotificationDetails(
        'channelId',
        'channelName',
        importance: Importance.high,
        priority: Priority.high,
      );
      const NotificationDetails notificationDetails =
          NotificationDetails(android: androidNotificationDetails);
      const String timeZoneName = 'Asia/Kolkata';
      late Location location = getLocation(timeZoneName);

      await notificationsPlugin.zonedSchedule(
        1,
        'Evening Notification',
        'Update the EB Readings',
        TZDateTime.from(evening, location),
        notificationDetails,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text("Settings")),
        body: Center(
          
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            // Add some space between buttons and displayed times
            const Text(
              'Version : 1.0',
              style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 50),
            // Display Morning Time
            Text(
              'Morning Notification : ${morningTime?.format(context) ?? "Not set"}',
              style: const TextStyle(fontSize: 18,fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                morningTime = await _selectTime(context, morningTime);
                if (morningTime != null) {
                  await scheduleMorningNotification();
                  saveLastSelectedTimes();
                }
              },
              child: const Text("Select Morning Time"),
            ),
            const SizedBox(height: 50),
            Text(
              'Evening Notification : ${eveningTime?.format(context) ?? "Not set"}',
              style: const TextStyle(fontSize: 18,fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                eveningTime = await _selectTime(context, eveningTime);
                if (eveningTime != null) {
                  await scheduleEveningNotification();
                  saveLastSelectedTimes();
                }
              },
              child: const Text("Select Evening Time"),
            ),
          ]),
        ));
  }

  Future<TimeOfDay?> _selectTime(
      BuildContext context, TimeOfDay? initialTime) async {
    return await showTimePicker(
      context: context,
      initialTime: initialTime ?? TimeOfDay.now(),
    );
  }
}