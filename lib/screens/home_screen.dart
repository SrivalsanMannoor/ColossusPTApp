import 'package:colossus_pt/screens/workout_home_screen.dart';
import 'package:colossus_pt/theme.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'assets/logo.png',
          height: 30,
          errorBuilder: (context, error, stackTrace) {
            return const Text('Colossus PT',
                style: TextStyle(color: Colors.white));
          },
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        backgroundColor: ColossusTheme.surfaceColor,
        selectedItemColor: ColossusTheme.primaryColor,
        unselectedItemColor: ColossusTheme.textSecondary,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.fitness_center), label: 'Workout'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today), label: 'Schedule'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return const WorkoutHomeScreen();
      default:
        return const Center(child: Text('Coming Soon'));
    }
  }
}
