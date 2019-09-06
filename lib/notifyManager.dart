import 'package:english_words/english_words.dart' as prefix0;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:english_words/english_words.dart';
import 'package:flutter/services.dart';
import 'dart:developer' as dev;
import 'todo.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotifyManager {

  NotifyManager._internal(){
    var androidSetting = AndroidInitializationSettings('@mipmap/ic_launcher');
    var iosSetting = IOSInitializationSettings();
    var initializationSettings = InitializationSettings(androidSetting, iosSetting);

    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    _flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: (id) async {
          dev.log("notification answered.");
        });
  }

  static final NotifyManager _instance = NotifyManager._internal();
  factory NotifyManager() => _instance;
  FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;

  void deadlineSchedule(int id, String description, DateTime time) {
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'toy.viento.todo', 'Todo Deadline Channel', 'The Todo which you registered was reached at deadline',
      importance: Importance.Max,
      priority: Priority.High,
    );
    var iosPlatformChannelSpecifics = IOSNotificationDetails(
    );
    var platformChannelSpecifics = NotificationDetails(androidPlatformChannelSpecifics, iosPlatformChannelSpecifics);
    _schedule(id, 'Todo Deadline Notify', description, time, platformChannelSpecifics);
  }
  void _schedule(int id, String title, String description, DateTime time, NotificationDetails setting) async {
    await _flutterLocalNotificationsPlugin.schedule(
      id,
      title,
      description,
      time,
      setting,
      androidAllowWhileIdle: true,
    );
  }

  void cancelSchedule(int id) {
    _flutterLocalNotificationsPlugin.cancel(id);
  }

}