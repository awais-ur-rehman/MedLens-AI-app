import 'package:flutter/material.dart';

/// Home screen — landing page with "Start Session" button.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('MedLens AI — Home'),
      ),
    );
  }
}
