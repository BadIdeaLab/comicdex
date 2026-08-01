import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'state/server_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final model = ServerModel();
  // Started before the first frame so the connection details (address, port,
  // PIN) are already on screen when the window appears.
  await model.initialize();
  runApp(BackupServerApp(model: model));
}

class BackupServerApp extends StatelessWidget {
  const BackupServerApp({super.key, required this.model});

  final ServerModel model;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Comicdex Backup Server',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4A6FA5)),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4A6FA5),
          brightness: Brightness.dark,
        ),
      ),
      home: HomeScreen(model: model),
    );
  }
}
