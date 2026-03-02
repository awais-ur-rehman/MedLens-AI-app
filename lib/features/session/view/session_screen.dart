import 'package:flutter/material.dart';

/// Session screen — main live session with camera + audio + overlays.
class SessionScreen extends StatelessWidget {
  const SessionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('MedLens AI — Live Session'),
      ),
    );
  }
}
