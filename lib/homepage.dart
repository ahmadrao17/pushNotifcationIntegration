import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:notification/Services/notification.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  NotificationApi notificationServices = NotificationApi();
  TextEditingController textEditingController = TextEditingController();
  GlobalKey key = GlobalKey();
  @override
  void initState() {
    NotificationApi.init(context);
    notificationServices.firebaseInit(context);
    notificationServices.getToken().then((value) => print(value));
    notificationServices.setupInteractMessages(context);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Form(
          key: key,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextFormField(
                  controller: textEditingController,
                  decoration: InputDecoration(
                    hintText: 'Enter Message',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(40.0),
                        borderSide: BorderSide(width: .02)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(40.0),
                      borderSide:
                          BorderSide(color: Colors.transparent, width: 0),
                    ),

                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(40.0),
                      borderSide: BorderSide(
                        color: Colors
                            .purple, // Set the color for focused border when typing
                        width: .7,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(40.0),
                      borderSide: BorderSide(
                        color: Colors
                            .red, // Set the color for focused border when typing
                        width: .7,
                      ),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(40.0),
                      borderSide: BorderSide(
                        color: Colors
                            .red, // Set the color for focused border when typing
                        width: .7,
                      ),
                    ),
                    // ... other properties

                    contentPadding:
                        EdgeInsets.symmetric(vertical: 18.0, horizontal: 10.0),
                    fillColor: Colors.grey.shade100,
                    filled: true,
                    errorMaxLines: 3,
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                ElevatedButton(
                  onPressed: () {
                    if (textEditingController.text != "") {
                      var message = textEditingController.text;
                      notificationServices.getToken().then((value) =>
                          notificationServices.sendMessageNotification(
                              senderName: "Ahmad",
                              senderId: 1,
                              receiverFcm: value,
                              message: message));
                    }
                    textEditingController.text = "";
                  },
                  child: Text("Send Message As Ahmad"),
                ),
                SizedBox(
                  height: 20,
                ),
                ElevatedButton(
                  onPressed: () {
                    if (textEditingController.text != "") {
                      var message = textEditingController.text;
                      notificationServices.getToken().then((value) =>
                          notificationServices.sendMessageNotification(
                              senderName: "Ali",
                              senderId: 2,
                              receiverFcm: value,
                              message: message));
                    }
                    textEditingController.text = "";
                  },
                  child: Text("Send Message as Ali"),
                ),
                SizedBox(
                  height: 20,
                ),
                ElevatedButton(
                  onPressed: () {
                    if (textEditingController.text != "") {
                      var message = textEditingController.text;
                      notificationServices.getToken().then((value) =>
                          notificationServices.sendMessageNotification(
                              senderName: "Mudassar",
                              senderId: 3,
                              receiverFcm: value,
                              message: message));
                    }
                    textEditingController.text = "";
                  },
                  child: Text("Send Message as Mudassar"),
                ),
                SizedBox(
                  height: 20,
                ),
                ElevatedButton(
                    onPressed: () {
                      DateTime scheduleDate =
                          DateTime.now().add(const Duration(seconds: 5));
                      notificationServices.showScheduledNotification(
                          "Scheduled Notification",
                          "This is a Scheduled Notification",
                          scheduleDate);
                    },
                    child: Text("Schedule Notification")),
                SizedBox(
                  height: 20,
                ),
                ElevatedButton(
                    onPressed: () {
                      DateTime scheduleDate =
                          DateTime.now().add(const Duration(seconds: 5));
                      notificationServices.showPeriodicallyNotification(
                          "Periodic Notification",
                          "This is a Periodic Notification");
                    },
                    child: Text("Periodic Notification")),
                SizedBox(
                  height: 20,
                ),
                ElevatedButton(
                  onPressed: () {
                    notificationServices.printPendingNotifications();
                  },
                  child: Text("Pending Notification"),
                ),
                SizedBox(
                  height: 20,
                ),
                TextButton(
                  onPressed: () {
                    notificationServices.closeAll();
                  },
                  child: Text("Close All Notification"),
                ),
                SizedBox(
                  height: 20,
                ),
                TextButton(
                  onPressed: () {
                    notificationServices.isLaunchedByNoti(context);
                  },
                  child: Text("Check Notification"),
                ),
              ],
            ),
          ),
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
