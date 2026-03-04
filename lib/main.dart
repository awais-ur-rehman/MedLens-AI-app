import 'package:flutter/material.dart';
import 'package:medlens_mobile/app.dart';
import 'package:medlens_mobile/services/local_storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise Hive for local session history.
  final storage = LocalStorageService();
  await storage.init();

  runApp(App(storageService: storage));
}
