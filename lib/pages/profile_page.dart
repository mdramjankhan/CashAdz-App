import 'package:cash_adz/pages/admin_panel_page.dart';
import 'package:cash_adz/pages/redeem_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/banner_ad_widget.dart';
import '../services/auth_service.dart';
import 'package:intl/intl.dart'; // For date formatting

class ProfilePage extends StatelessWidget {
  final AuthService _authService = AuthService();

  ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return SizedBox();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final data = snapshot.data!.data() as Map<String, dynamic>;
        final points = data['points'] ?? 0;
        final userName = data['name'] ?? '';
        final email = data['email'] ?? '';
        final photoUrl = data['photoUrl'];

        return Scaffold(
          appBar: AppBar(
            title: Text('Profile'),
            actions: [
              IconButton(
                icon: Icon(Icons.logout),
                onPressed: () async {
                  await _authService.signOut();
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),
            ],
          ),
          body: ListView(
            padding: EdgeInsets.all(16),
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: photoUrl != null
                    ? NetworkImage(photoUrl)
                    : null,
                child: photoUrl == null ? Icon(Icons.person, size: 50) : null,
              ),
              SizedBox(height: 16),
              Center(
                child: Text(
                  userName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Center(
                child: Text(email, style: TextStyle(color: Colors.grey)),
              ),
              if (data['isAdmin'] == true)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.admin_panel_settings),
                    label: Text('Admin Panel'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AdminPanelPage(),
                        ),
                      );
                    },
                  ),
                ),
              SizedBox(height: 24),
              Card(
                child: ListTile(
                  leading: Icon(Icons.monetization_on, color: Colors.amber),
                  title: Text('Points Earned'),
                  trailing: Text(
                    '$points pts',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton.icon(
                icon: Icon(Icons.redeem),
                label: Text('Redeem Points'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => RedeemPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 48),
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Earnings History',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SizedBox(height: 8),
              // Real earnings history with friendly empty state
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .collection('earnings_history')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, historySnapshot) {
                  if (historySnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (historySnapshot.hasError) {
                    return Center(child: Text('Something went wrong!'));
                  }
                  if (!historySnapshot.hasData) {
                    return Center(child: Text('No data found.'));
                  }
                  final docs = historySnapshot.data!.docs;
                  if (docs.isEmpty) {
                    return Column(
                      children: [
                        SizedBox(height: 24),
                        Icon(
                          Icons.emoji_emotions,
                          size: 48,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'No history yet!',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Watch ads to start earning points.',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        SizedBox(height: 16),
                        ElevatedButton.icon(
                          icon: Icon(Icons.play_circle_fill),
                          label: Text('Watch & Earn Now'),
                          onPressed: () {
                            Navigator.pushNamed(context, '/watch_earn');
                          },
                        ),
                      ],
                    );
                  }
                  return Column(
                    children: docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final type = data['type'] ?? 'Ad';
                      final pts = data['points'] ?? 0;
                      final timestamp = data['timestamp'] as Timestamp?;
                      final dateStr = timestamp != null
                          ? DateFormat(
                              'yyyy-MM-dd – kk:mm',
                            ).format(timestamp.toDate())
                          : '';
                      return ListTile(
                        leading: Icon(
                          type == 'Rewarded Ad'
                              ? Icons.play_circle_fill
                              : Icons.ad_units,
                          color: type == 'Rewarded Ad'
                              ? Colors.blue
                              : Colors.purple,
                        ),
                        title: Text(type),
                        subtitle: Text('$pts pts'),
                        trailing: Text(dateStr),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
          bottomNavigationBar: BannerAdWidget(),
        );
      },
    );
  }
}
