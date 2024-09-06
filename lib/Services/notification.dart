import 'dart:ffi';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:notification/Services/acess_firebase_token.dart';
import 'package:notification/second_page.dart';
import 'package:timezone/timezone.dart' as tz;

// Class for managing notifications using Firebase and local notifications
class NotificationApi {
  static final notifications =
      FlutterLocalNotificationsPlugin(); // Instance for managing local notifications

  List<String> messages = []; // List to store message contents

  FirebaseMessaging messaging =
      FirebaseMessaging.instance; // Instance for handling Firebase Messaging

  Map<String, List<Message>> messageGroups =
      {}; // Maps sender IDs to lists of messages

  // Define a high importance notification channel for Android
  static const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel', // ID for the notification channel
    'High Importance Notifications', // Name of the notification channel
    description:
        'This channel is used for important notifications.', // Description of the channel
    importance: Importance.max, // Channel importance level
  );

  // Request notification permissions for iOS devices
  void requestNotificationPermission() async {
    NotificationSettings notificationSettings =
        await messaging.requestPermission();

    if (notificationSettings.authorizationStatus ==
        AuthorizationStatus.authorized) {
      print("Permission Authorized");
    } else if (notificationSettings.authorizationStatus ==
        AuthorizationStatus.denied) {
      print("Permission Denied");
    } else {
      print("Permission Not Determined");
    }
  }

  // Initialize Firebase and setup listeners for incoming and background notifications
  void firebaseInit(BuildContext context) {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print("Receiving message: ${message.data['SenderId']}");
      groupNotificationBySender(
          message: message); // Group notifications by sender
      groupNotificationOverAll(); // Update overall notification summary
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("Message tapped in background: ${message.notification!.body}");
      backGroundNotificationTap(
        notificationResponse: NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
        ),
        context: context,
        message: message,
        path: "Background",
      );
    });
  }

  // Retrieve the FCM token for the current device
  Future<String> getToken() async {
    String? token = await messaging.getToken();
    return token!; // Ensure token is not null
  }

  // Send a notification message to a specific receiver
  Future<void> sendMessageNotification({
    required String senderName,
    required String receiverFcm,
    required int senderId,
    required String message,
  }) async {
    var accessToken = await AccessTokenFirebase()
        .getAccessToken(); // Retrieve access token for FCM
    var data = {
      "message": {
        "token": receiverFcm,
        'notification': {
          'title': senderName,
          'body': message,
        },
        'data': {
          'type': 'message',
          'SenderId': senderId.toString(),
          'time': DateTime.now().toString()
        }
      }
    };

    final http.Response response = await http.post(
        Uri.parse(
            "https://fcm.googleapis.com/v1/projects/pushnotification-9410f/messages:send"),
        body: jsonEncode(data),
        headers: {
          "Content-Type": "application/json; charset=UTF-8",
          "Authorization": "Bearer $accessToken"
        });

    if (response.statusCode == 200) {
      debugPrint("Notification sent: ${response.body}");
    } else {
      debugPrint("Failed to send notification: ${response.body}");
    }
  }

  // Cancel a specific notification by ID
  Future<void> close(int id) async {
    notifications.cancel(id);
  }

  // Cancel all active notifications
  Future<void> closeAll() async {
    notifications.cancelAll();
  }

  // Update the overall summary notification for all groups
  Future<void> groupNotificationOverAll() async {
    String content =
        "${messageGroups.keys.length} chats"; // Summary content based on number of senders
    int totalMessages = messageGroups.values.fold(
        0,
        (prev, messages) =>
            prev + messages.length); // Count total number of messages

    await notifications.show(
      0, // Global summary ID
      content,
      "Total messages $totalMessages",
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          groupKey: "group_key",
          styleInformation: InboxStyleInformation([],
              contentTitle: content,
              summaryText: "$content and $totalMessages messages"),
          setAsGroupSummary: true,
        ),
      ),
    );
  }

  // Group notifications by sender
  Future<void> groupNotificationBySender({
    required RemoteMessage message,
  }) async {
    print("In group notification:");

    String senderId = message.data['SenderId'];
    String senderName = message.notification!.title!;
    String messageBody = message.notification!.body!;
    DateTime messageTime = DateTime.parse(message.data['time']);

    var person =
        Person(name: senderName); // Create a Person object for the sender
    var newMessages =
        Message(messageBody, messageTime, person); // Create a Message object

    if (!messageGroups.containsKey(senderId)) {
      messageGroups[senderId] = [];
    }

    messageGroups[senderId]!
        .add(newMessages); // Add the new message to the sender's group

    var messageStyle = MessagingStyleInformation(
      person,
      groupConversation: true,
      messages: messageGroups[senderId]!.map((msg) {
        return Message(msg.text, msg.timestamp, msg.person);
      }).toList(),
    );

    var androidDetails = AndroidNotificationDetails(
      channel.id,
      channel.name,
      importance: Importance.high,
      styleInformation: messageStyle,
      groupKey: "group_key",
      setAsGroupSummary: false,
    );

    var platformDetails = NotificationDetails(android: androidDetails);
    await notifications.show(
      senderId.hashCode, // Unique ID for each sender's group
      'New message from $senderName',
      messageBody,
      platformDetails,
    );
  }

  // Show a basic notification for a received message
  Future<void> showNotification({
    required RemoteMessage message,
  }) async {
    await notifications.show(
      message.hashCode,
      message.notification!.title,
      message.notification!.body,
      payload: message.data['time'],
      NotificationDetails(
        android: AndroidNotificationDetails(channel.id, channel.name,
            channelDescription: channel.description,
            importance: Importance.low,
            groupKey: "groupkey_${message.data['SenderId']}"),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  // Initialize notification settings and permissions
  static Future init(BuildContext? context) async {
    const android = AndroidInitializationSettings("flutter_logo");
    const ios = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );
    const settings = InitializationSettings(android: android, iOS: ios);

    await notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (e) {
        foreGroundNotificationTap(
            notificationResponse: e, context: context, path: "ForeGround");
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
    notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // Handle the case when the app is launched from a notification
  Future<void> setupInteractMessages(BuildContext context) async {
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    print("Receiving message when app is terminated:");
    if (initialMessage != null) {
      backGroundNotificationTap(
          notificationResponse: NotificationResponse(
            notificationResponseType:
                NotificationResponseType.selectedNotification,
          ),
          context: context,
          message: initialMessage,
          path: "Terminated");
    }
  }

  // Check if the app was launched by tapping a notification
  Future<void> isLaunchedByNoti(BuildContext context) async {
    final NotificationAppLaunchDetails? notificationAppLaunchDetails =
        await notifications.getNotificationAppLaunchDetails();
    if (notificationAppLaunchDetails!.didNotificationLaunchApp ?? false) {
      showDialog(
          context: (context),
          builder: (context) => Container(
                child: Text("yes"),
              ));
    }
    print(notificationAppLaunchDetails!.notificationResponse!.id.toString());
  }

  // Print IDs of all pending notifications
  Future<void> printPendingNotifications() async {
    final List<PendingNotificationRequest> pendingNotificationRequests =
        await notifications.pendingNotificationRequests();
    print(
        pendingNotificationRequests.map((toElement) => toElement.id).toList());
  }

  // Show a notification that repeats periodically
  Future<void> showPeriodicallyNotification(String title, String body) async {
    const NotificationDetails platformSpecific = NotificationDetails(
        android: AndroidNotificationDetails("channel_Id", "channel_Name",
            ticker: 'ticker'),
        iOS: DarwinNotificationDetails());
    await notifications.periodicallyShow(
      2,
      title,
      body,
      RepeatInterval.everyMinute,
      platformSpecific,
    );
  }

  // Show a notification at a specific scheduled time
  Future<void> showScheduledNotification(
      String title, String body, DateTime scheduledTime) async {
    const NotificationDetails platformSpecific = NotificationDetails(
      android: AndroidNotificationDetails(
        "channel_Id",
        "channel_Name",
        importance: Importance.max,
        priority: Priority.max,
        fullScreenIntent: true,
      ),
      iOS: DarwinNotificationDetails(),
    );
    await notifications.zonedSchedule(
      1,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      platformSpecific,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );
  }
}

// Handle tap on foreground notification
void notificationTapForeground(
  NotificationResponse notificationResponse,
) {
  foreGroundNotificationTap(notificationResponse: notificationResponse);
}

Future<void> foreGroundNotificationTap(
    {required NotificationResponse notificationResponse,
    BuildContext? context,
    RemoteMessage? message,
    String? path}) async {
  print("Notifcation tapped from FG::::");
  // final decodedResponse = json.decode(notificationResponse.payload!);
  if (context != null) {
    Navigator.push(
        context!,
        MaterialPageRoute(
            builder: (context) => SecondPage(
                  path: path,
                  payload: message != null
                      ? message.notification!.title
                      : notificationResponse.payload,
                )));
  }
  // final payLoad = json.decode(decodedResponse["payload"]);
}

// Handle tap on Background notification
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  backGroundNotificationTap(notificationResponse: notificationResponse);
}

Future<void> backGroundNotificationTap(
    {required NotificationResponse notificationResponse,
    BuildContext? context,
    RemoteMessage? message,
    String? path}) async {
  print("Notifcation tapped from BG::::");
  // final decodedResponse = json.decode(notificationResponse.payload!);
  if (context != null) {
    Navigator.push(
        context!,
        MaterialPageRoute(
            builder: (context) => SecondPage(
                  path: path,
                  payload: message!.notification!.title,
                )));
  }
  // final payLoad = json.decode(decodedResponse["payload"]);
}


// List<ActiveNotification> activeNotification = await notifications
//     .resolvePlatformSpecificImplementation<
//         AndroidFlutterLocalNotificationsPlugin>()!
//     .getActiveNotifications();
// print("total notifications :::::: ${activeNotification.length}");
// print("total chats :::::: ${messageGroups.length}");
// // close(message.hashCode);
// if (activeNotification.isNotEmpty) {
//   List<String> activeGroupKey = activeNotification
//       .map((notification) => notification.groupKey.toString())
//       .toSet()
//       .toList();
//   print("$activeGroupKey");
//   List<String?> linesNullable = activeNotification
//       .map((notification) => notification!.title)
//       .toList();
//   var lines = linesNullable.whereType<String>().toList();

//   var overallSummaryAndroidDetails = AndroidNotificationDetails(
//       channel.id, channel.name,
//       importance: Importance.max,
//       groupKey: "group_key",
//       setAsGroupSummary: true,
//       styleInformation: InboxStyleInformation(lines,
//           contentTitle: "New Messages",
//           summaryText: "${messageGroups.length} chats"));

//   var overallSummaryNotificationDetails = NotificationDetails(
//     android: overallSummaryAndroidDetails,
//   );

// List<ActiveNotification> activeNotification = await notifications
//     .resolvePlatformSpecificImplementation<
//         AndroidFlutterLocalNotificationsPlugin>()!
//     .getActiveNotifications();
// print("total notifications :::::: ${activeNotification.length}");
// // close(message.hashCode);
// if (activeNotification.length > 0) {
// List<String> activeGroupKey = activeNotification
//     .map((notification) => notification.groupKey.toString())
//     .toSet()
//     .toList();
//   print(activeGroupKey);
//   for (var key in activeGroupKey) {
//     var notificationInGroupKey = activeNotification
//         .where((notification) => notification.groupKey == key)
//         .toList();
//     Person sender = Person(
//         bot: false, key: key, name: notificationInGroupKey.first.title);
//     print("payload:::: ${notificationInGroupKey.first.payload}");
//     List<Message> messages = notificationInGroupKey
//         .map((value) => Message(value.body!, DateTime.now(), sender))
//         .toList();
//     // var lines = notificationInGroupKey
//     //     .map((notification) => notification.body.toString())
//     //     .toList();
//     // linesNullAble.add(notificationInGroupKey.last.body.toString());
//     // print("messages nullwale:::::: ${linesNullAble.toString()}");
// var lines = linesNullAble.whereType<String>().toList();
//     // print("lines::::: ${lines.length}");
//     print("person:::: ${sender.toString()}");
//     print("Messages:::::: ${messages.toString()}");
//     // print("messages:::::: ${lines.toString()}");
//     var summaryNotificationAndroidSpecifics =
//         AndroidNotificationDetails(channel.id, channel.name,
//             importance: Importance.max,
//             groupKey: key,
//             setAsGroupSummary: true,
//             styleInformation: MessagingStyleInformation(
//               sender,
//               groupConversation: true,
//               messages: messages,
//             )
//             // InboxStyleInformation(
//             //   htmlFormatLines: true,
//             //   lines,
//             //   contentTitle: notificationInGroupKey.first.title,
//             //   summaryText: lines.length > 1
//             //       ? "${lines.length} new Messages"
//             //       : "${lines.length} new Message",
//             // ),
//             );

//     var summaryPlatformChannelSpecifics = NotificationDetails(
//       android: summaryNotificationAndroidSpecifics,
//     );

//     // Show the notification summary
//     await notifications.show(
//       key.hashCode, // Notification ID for the summary
//       "messages",
//       "New Messages",
//       summaryPlatformChannelSpecifics,
//     );
//     // lines.clear();
//   }
// List<String?> linesNullAble = [message.notification!.title];
// List<String> lines = ["hey", "hiii", "nasf"];
// List<String> lines = linesNullAble.whereType<String>().toList();
// String lastTitle = lines.last;
// Grouped notification specifics, showing only the last notification
// activeNotification.clear();
// }

// List<String?> linesNullAble =
//     messages.map((toElement) => toElement.notification!.title).toList();
// List<String> lines = linesNullAble.whereType<String>().toList();
// var summaryNotificationAndroidSpecifics = AndroidNotificationDetails(
//     _chatNotificationChannel.channelId,
//     _chatNotificationChannel.channelName,
//     importance: Importance.high,
//     groupKey: _chatNotificationChannel.groupKey,
//     setAsGroupSummary: true,
//     styleInformation: InboxStyleInformation(lines,
//         contentTitle: "${lines.length} Messages"));

// var summaryPlatformChannelSpecifics = NotificationDetails(
//   android: summaryNotificationAndroidSpecifics,
// );

// await notifications.show(
//   messages.hashCode, // Notification ID for the summary
//   'Grouped Notifications',
//   'You have ${messages.length} new messages',
//   summaryPlatformChannelSpecifics,
// );

// Future<void> groupNotification() async {
//   const String groupKey = '23';
//   const String groupChannelId = 'grouped channel id';
//   const String groupChannelName = 'grouped channel name';
//   const String groupChannelDescription = 'grouped channel description';
//   const AndroidNotificationDetails firstNotificationAndroidSpecifics =
//       AndroidNotificationDetails(groupChannelId, groupChannelName,
//           channelDescription: groupChannelDescription,
//           importance: Importance.max,
//           priority: Priority.high,
//           groupKey: groupKey);
//   const NotificationDetails firstNotificationPlatformSpecifics =
//       NotificationDetails(android: firstNotificationAndroidSpecifics);
//   await notifications.show(1, 'Alex Faarborg', 'You will not believe...',
//       firstNotificationPlatformSpecifics);
//   const AndroidNotificationDetails secondNotificationAndroidSpecifics =
//       AndroidNotificationDetails(groupChannelId, groupChannelName,
//           channelDescription: groupChannelDescription,
//           importance: Importance.max,
//           priority: Priority.high,
//           groupKey: groupKey);
//   const NotificationDetails secondNotificationPlatformSpecifics =
//       NotificationDetails(android: secondNotificationAndroidSpecifics);
//   await notifications.show(
//       2,
//       'Jeff Chang',
//       'Please join us to celebrate the...',
//       secondNotificationPlatformSpecifics);

//   const List<String> lines = <String>[
//     'Alex Faarborg  Check this out',
//     'Jeff Chang    Launch Party'
//   ];
//   const InboxStyleInformation inboxStyleInformation = InboxStyleInformation(
//       lines,
//       contentTitle: '2 messages',
//       summaryText: 'raoahmad.com');
//   const AndroidNotificationDetails androidNotificationDetails =
//       AndroidNotificationDetails(groupChannelId, groupChannelName,
//           channelDescription: groupChannelDescription,
//           styleInformation: inboxStyleInformation,
//           groupKey: groupKey,
//           setAsGroupSummary: true);
//   const NotificationDetails notificationDetails =
//       NotificationDetails(android: androidNotificationDetails);
//   await notifications.show(
//       3, 'Attention', 'Two messages', notificationDetails);
// }
