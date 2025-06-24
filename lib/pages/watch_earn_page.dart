import 'package:flutter/material.dart';
import '../widgets/banner_ad_widget.dart';
import '../services/ad_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WatchEarnPage extends StatelessWidget {
  const WatchEarnPage({super.key});

  void _addPoints(int points, String type) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);

  // Update points
  await userDoc.update({'points': FieldValue.increment(points)});

  // Add to earnings history
  await userDoc.collection('earnings_history').add({
    'type': type, // e.g., 'Rewarded Ad', 'Interstitial Ad'
    'points': points,
    'timestamp': FieldValue.serverTimestamp(),
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Watch & Earn')),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: Icon(
                Icons.play_circle_fill,
                color: Colors.blue,
                size: 40,
              ),
              title: Text('Watch Rewarded Video'),
              subtitle: Text('Earn 10 points'),
              trailing: ElevatedButton(
                child: Text('Watch'),
                onPressed: () {
                  AdService.showRewardedAd(
                    context,
                    onRewarded: () {
                      _addPoints(10, "Rewarded Ad");
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Rewarded Ad watched! +10 pts')),
                      );
                    },
                  );
                },
              ),
            ),
          ),
          SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: Icon(Icons.ad_units, color: Colors.purple, size: 40),
              title: Text('Watch Interstitial Ad'),
              subtitle: Text('Earn 5 points'),
              trailing: ElevatedButton(
                child: Text('Watch'),
                onPressed: () {
                  AdService.showInterstitialAd(
                    context,
                    onAdClosed: () {
                      _addPoints(5, "Interstitial Ad");
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Interstitial Ad watched! +5 pts'),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BannerAdWidget(),
    );
  }
}
