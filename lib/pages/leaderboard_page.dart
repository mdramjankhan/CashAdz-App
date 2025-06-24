import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/banner_ad_widget.dart';

class LeaderboardPage extends StatelessWidget {
  const LeaderboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Leaderboard')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .orderBy('points', descending: true)
            .limit(20)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return Center(child: Text('No users found.'));
          }
          return ListView.separated(
            padding: EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => Divider(),
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final name = data['name'] ?? 'User';
              final points = data['points'] ?? 0;
              return ListTile(
                leading: CircleAvatar(child: Text('${i + 1}')),
                title: Text(name),
                trailing: Text(
                  '$points pts',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: BannerAdWidget(),
    );
  }
}
