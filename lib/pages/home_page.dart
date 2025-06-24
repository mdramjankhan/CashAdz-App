import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/earnings_appbar.dart';
import '../widgets/banner_ad_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  final List<Map<String, dynamic>> carouselAds = [
    {
      'image': 'assets/images/ad_1.jpg',
      'title': 'Watch Rewarded Ad',
      'desc': 'Earn 10 points instantly!',
      'action': '/watch_earn',
    },
    {
      'image': 'assets/images/ad_2.jpg',
      'title': 'Try Interstitial Ad',
      'desc': 'Earn 5 points for every view!',
      'action': '/watch_earn',
    },
    {
      'image': 'assets/images/ad_3.jpg',
      'title': 'Check Leaderboard',
      'desc': 'See who\'s earning the most!',
      'action': '/leaderboard',
    },
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(Duration(seconds: 5), (Timer timer) {
      if (_pageController.hasClients) {
        int nextPage = (_currentPage + 1) % carouselAds.length;
        _pageController.animateToPage(
          nextPage,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        setState(() {
          _currentPage = nextPage;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

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

        final rawData = snapshot.data!.data();
        if (rawData == null) {
          return Scaffold(
            body: Center(
              child: Text('User data not found. Please try again later.'),
            ),
          );
        }
        final data = rawData as Map<String, dynamic>;
        final points = data['points'] ?? 0;
        final userName = data['name'] ?? '';

        return Scaffold(
          appBar: EarningsAppBar(points: points, userName: userName),
          body: ListView(
            padding: EdgeInsets.all(16),
            children: [
              // --- PageView Carousel ---
              SizedBox(
                height: 170,
                child: Stack(
                  children: [
                    PageView.builder(
                      controller: _pageController,
                      itemCount: carouselAds.length,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        final ad = carouselAds[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, ad['action']);
                          },
                          child: Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.asset(
                                    ad['image'],
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: 170,
                                  ),
                                ),
                                Container(
                                  height: 170,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    color: Colors.black.withOpacity(0.3),
                                  ),
                                ),
                                Positioned(
                                  left: 16,
                                  bottom: 24,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        ad['title'],
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        ad['desc'],
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    // Dots indicator
                    Positioned(
                      bottom: 8,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(carouselAds.length, (index) {
                          return AnimatedContainer(
                            duration: Duration(milliseconds: 300),
                            margin: EdgeInsets.symmetric(horizontal: 4),
                            width: _currentPage == index ? 12 : 8,
                            height: _currentPage == index ? 12 : 8,
                            decoration: BoxDecoration(
                              color: _currentPage == index
                                  ? Colors.blueAccent
                                  : Colors.grey,
                              shape: BoxShape.circle,
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),

              // --- End PageView Carousel ---
              SizedBox(height: 16),
              Card(
                elevation: 2,
                child: ListTile(
                  leading: Icon(
                    Icons.play_circle_fill,
                    size: 40,
                    color: Colors.blue,
                  ),
                  title: Text('Watch Rewarded Video'),
                  subtitle: Text('Earn 10 points per video'),
                  trailing: Icon(Icons.arrow_forward_ios),
                  onTap: () => Navigator.pushNamed(context, '/watch_earn'),
                ),
              ),
              SizedBox(height: 16),
              Card(
                elevation: 2,
                child: ListTile(
                  leading: Icon(
                    Icons.leaderboard,
                    size: 40,
                    color: Colors.green,
                  ),
                  title: Text('Leaderboard'),
                  subtitle: Text('See top earners'),
                  trailing: Icon(Icons.arrow_forward_ios),
                  onTap: () => Navigator.pushNamed(context, '/leaderboard'),
                ),
              ),
              SizedBox(height: 16),
              Card(
                elevation: 2,
                child: ListTile(
                  leading: Icon(
                    Icons.account_circle,
                    size: 40,
                    color: Colors.orange,
                  ),
                  title: Text('Profile'),
                  subtitle: Text('View your earnings & redeem'),
                  trailing: Icon(Icons.arrow_forward_ios),
                  onTap: () => Navigator.pushNamed(context, '/profile'),
                ),
              ),
            ],
          ),
          bottomNavigationBar: BannerAdWidget(),
        );
      },
    );
  }
}
