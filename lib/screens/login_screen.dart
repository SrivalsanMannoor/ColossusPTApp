import 'package:colossus_pt/screens/home_screen.dart';
import 'package:colossus_pt/theme.dart';
import 'package:flutter/material.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF000000),
                  Color(0xFF1A1A1A),
                ],
              ),
            ),
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  
                  // Logo
                  Hero(
                    tag: 'logo',
                    child: Image.asset(
                      'assets/logo.png',
                      height: 120,
                      errorBuilder: (context, error, stackTrace) {
                         return const Icon(Icons.fitness_center, size: 80, color: ColossusTheme.primaryColor);
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 48),
                  
                  const Text(
                    'Welcome to Colossus',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  const Text(
                    'Your personal training, elevated.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: ColossusTheme.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Apple Sign In Button
                  SignInWithAppleButton(
                    onPressed: () async {
                      // Mock navigation for now as we don't have backend setup
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const HomeScreen(),
                        ),
                      );
                    },
                    style: SignInWithAppleButtonStyle.white,
                    height: 50,
                  ),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
