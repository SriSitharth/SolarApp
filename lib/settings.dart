import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart';
import 'package:timezone/data/latest.dart';


class settings extends StatefulWidget {
  @override
  State<settings> createState() => _settingsState();
}
class _settingsState extends State<settings> {

  FlutterLocalNotificationsPlugin notificationsPlugin = FlutterLocalNotificationsPlugin();
  TimeOfDay? morningTime;
  TimeOfDay? eveningTime;

  @override
  void initState() {
    super.initState();
    initializeNotifications();
    initializeTimeZones();
  }

  void initializeNotifications() async{
    const AndroidInitializationSettings androidInitializationSettings = AndroidInitializationSettings('app_icon');
    const InitializationSettings initializationSettings = InitializationSettings(
    android: androidInitializationSettings
   );
   await notificationsPlugin.initialize(initializationSettings);
  }

   Future<void> scheduleMorningNotification() async {
    if (morningTime != null) {
      final DateTime now = DateTime.now();
      final DateTime morning = DateTime(
        now.year,
        now.month,
        now.day,
        morningTime!.hour,
        morningTime!.minute,
      );

      if (morning.isBefore(now)) {
        morning.add(const Duration(days: 1));
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
      final DateTime evening = DateTime(
        now.year,
        now.month,
        now.day,
        eveningTime!.hour,
        eveningTime!.minute,
      );

      if (evening.isBefore(now)) {
        evening.add(const Duration(days: 1));
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
            ElevatedButton(
              onPressed: () async {
                morningTime = await _selectTime(context);
                if (morningTime != null) {
                  await scheduleMorningNotification();
                }
              },
              child: const Text("Select Morning Time"),
            ),
            ElevatedButton(
              onPressed: () async {
                eveningTime = await _selectTime(context);
                if (eveningTime != null) {
                  await scheduleEveningNotification();
                }
              },
              child: const Text("Select Evening Time"),
            ),
          ]),
        ));
  }
   Future<TimeOfDay?> _selectTime(BuildContext context) async {
    return await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
  }
}