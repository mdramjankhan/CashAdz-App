import 'package:flutter/material.dart';

class EarningsAppBar extends StatelessWidget implements PreferredSizeWidget {
  final int points;
  final String? userName;

  const EarningsAppBar({super.key, required this.points, this.userName});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text('CashAdz'),
      actions: [
        if (userName != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Center(child: Text('Hi, $userName')),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Chip(
            label: Text('$points pts'),
            avatar: Icon(Icons.monetization_on, color: Colors.amber),
            backgroundColor: Colors.blue[50],
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}