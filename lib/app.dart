import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'core/router.dart';

class PlantherApp extends StatelessWidget {
  const PlantherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Planther',
      debugShowCheckedModeBanner: false,
      theme: plantherTheme,
      onGenerateRoute: AppRouter.generateRoute,
      initialRoute: AppRoutes.login,
    );
  }
}