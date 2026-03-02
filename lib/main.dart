import 'package:colossus_pt/providers/workout_provider.dart';
import 'package:colossus_pt/screens/home_screen.dart';
import 'package:colossus_pt/theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final provider = WorkoutProvider();
  await provider.initDatabase();
  runApp(ColossusApp(provider: provider));
}

class ColossusApp extends StatelessWidget {
  final WorkoutProvider provider;
  const ColossusApp({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: provider,
      child: MaterialApp(
        title: 'Colossus PT',
        theme: ColossusTheme.darkTheme,
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
