import 'package:flutter/material.dart';

class NotificationList extends StatelessWidget {
  final List<String> notifications;

  const NotificationList({Key? key, required this.notifications})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(notifications[index]),
        );
      },
    );
  }
}
