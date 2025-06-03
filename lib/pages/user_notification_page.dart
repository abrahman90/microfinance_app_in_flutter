import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class UserNotificationPage extends StatefulWidget {
  const UserNotificationPage({Key? key}) : super(key: key);

  @override
  _UserNotificationPageState createState() => _UserNotificationPageState();
}

class _UserNotificationPageState extends State<UserNotificationPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore
            .collection('notification_settings')
            .doc(_auth.currentUser?.uid)
            .snapshots(),
        builder: (context, settingsSnapshot) {
          if (settingsSnapshot.hasError) {
            return Center(child: Text('Error: ${settingsSnapshot.error}'));
          }

          final settings = settingsSnapshot.data?.data() as Map<String, dynamic>? ?? {};
          final enabledTypes = <String>[];
          
          if (settings['loanUpdates'] == true) enabledTypes.add('loanUpdates');
          if (settings['paymentReminders'] == true) enabledTypes.add('paymentReminders');
          if (settings['promotions'] == true) enabledTypes.add('promotions');

          if (enabledTypes.isEmpty) {
            return const Center(
              child: Text('No notifications enabled. Please check your settings.'),
            );
          }

          return StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('notifications')
                .where('type', whereIn: enabledTypes)
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final notifications = snapshot.data?.docs ?? [];

              if (notifications.isEmpty) {
                return const Center(
                  child: Text('No notifications yet'),
                );
              }

              return ListView.builder(
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index].data() as Map<String, dynamic>;
                  final timestamp = notification['timestamp'] as Timestamp?;
                  final date = timestamp?.toDate() ?? DateTime.now();

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ListTile(
                      title: Text(
                        notification['title'] ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Text(notification['message'] ?? ''),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('MMM dd, yyyy HH:mm').format(date),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      leading: Icon(
                        _getNotificationIcon(notification['type']),
                        color: Theme.of(context).primaryColor,
                        size: 28,
                      ),
                      contentPadding: const EdgeInsets.all(16),
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

  IconData _getNotificationIcon(String? type) {
    switch (type) {
      case 'loanUpdates':
        return Icons.update;
      case 'paymentReminders':
        return Icons.payment;
      case 'promotions':
        return Icons.local_offer;
      default:
        return Icons.notifications;
    }
  }
} 