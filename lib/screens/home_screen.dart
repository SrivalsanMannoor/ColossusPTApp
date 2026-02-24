import 'dart:convert';
import 'package:colossus_pt/providers/workout_provider.dart';
import 'package:colossus_pt/screens/saved_workout_detail_screen.dart';
import 'package:colossus_pt/screens/workout_home_screen.dart';
import 'package:colossus_pt/theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
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
        return _buildHomeTab();
      case 1:
        return const WorkoutHomeScreen();
      default:
        return const Center(child: Text('Coming Soon'));
    }
  }

  Widget _buildHomeTab() {
    final provider = context.watch<WorkoutProvider>();
    final savedWorkouts = provider.savedWorkouts;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Good Morning,',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: ColossusTheme.textSecondary,
                ),
          ),
          Text(
            'Ready for your workout?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 24),

          // Saved workouts section
          if (savedWorkouts.isNotEmpty) ...[
            Text(
              'My Workouts',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ...savedWorkouts.map((workout) => _buildSavedWorkoutCard(workout)),
            const SizedBox(height: 24),
          ],

          // Fallback if no saved workouts
          if (savedWorkouts.isEmpty) _buildEmptyStateCard(),

          const SizedBox(height: 24),
          Text(
            'Recent Types',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          // Horizontal scroll of workout types
          SizedBox(
            height: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildTypeCard('Strength', Icons.fitness_center),
                _buildTypeCard('Cardio', Icons.directions_run),
                _buildTypeCard('Mobility', Icons.accessibility_new),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedWorkoutCard(Map<String, dynamic> workout) {
    final name = workout['name'] ?? 'Custom Workout';
    final exercisesJson = workout['exercises_json'] ?? '[]';
    List exercises = [];
    try {
      exercises = jsonDecode(exercisesJson) as List;
    } catch (_) {}

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ColossusTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: ColossusTheme.primaryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'SAVED',
                  style: TextStyle(
                    color: ColossusTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const Icon(Icons.more_horiz, color: Colors.white54),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.fitness_center,
                  size: 16, color: ColossusTheme.textSecondary),
              const SizedBox(width: 4),
              Text('${exercises.length} exercises',
                  style: const TextStyle(color: ColossusTheme.textSecondary)),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        SavedWorkoutDetailScreen(workout: workout),
                  ),
                );
              },
              child: const Text('START WORKOUT'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ColossusTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.fitness_center,
              size: 40, color: ColossusTheme.primaryColor),
          const SizedBox(height: 16),
          const Text(
            'No Saved Workouts Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Build your own workout from the exercise library and it will appear here.',
            style: TextStyle(
              color: ColossusTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                setState(() => _selectedIndex = 1);
              },
              child: const Text('BUILD A WORKOUT'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeCard(String title, IconData icon) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: ColossusTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: ColossusTheme.primaryColor, size: 32),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
