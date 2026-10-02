import 'package:flutter/material.dart';
import 'notification_store.dart';
import 'news_detail_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = NotificationStore.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: const Color(0xFFFF5252),
        foregroundColor: Colors.white,
      ),
      body: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          final notifications = store.notifications;

          if (notifications.isEmpty) {
            return const Center(
              child: Text(
                'No notifications yet',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          return ListView.separated(
            itemCount: notifications.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = notifications[index];
              return ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFFEBEE),
                  child: Icon(Icons.warning_amber_rounded, color: Color(0xFFFF5252)),
                ),
                title: Text(
                  item.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  item.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text(
                  "${item.timestamp.hour}:${item.timestamp.minute.toString().padLeft(2, '0')}",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NewsDetailScreen(
                        title: item.title,
                        body: item.body,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}