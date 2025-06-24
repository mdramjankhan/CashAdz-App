import 'package:flutter/material.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'pages/profile_page.dart';
import 'pages/watch_earn_page.dart';
import 'pages/leaderboard_page.dart';

final Map<String, WidgetBuilder> appRoutes = {
  '/login': (_) => LoginPage(),
  '/home': (_) => HomePage(),
  '/profile': (_) => ProfilePage(),
  '/watch_earn': (_) => WatchEarnPage(),
  '/leaderboard': (_) => LeaderboardPage(),
};