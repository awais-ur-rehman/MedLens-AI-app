import 'package:flutter/material.dart';
import 'package:medlens_mobile/app.dart';
import 'package:medlens_mobile/services/local_storage_service.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Request camera and microphone permissions up-front so iOS shows the
  // system dialogs and registers the app in Settings privacy toggles.
  await [Permission.camera, Permission.microphone].request();

  // Initialise Hive for local session history.
  final storage = LocalStorageService();
  await storage.init();

  runApp(App(storageService: storage));
}
