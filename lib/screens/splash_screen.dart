import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    final provider = context.read<AppProvider>();
    await provider.initialize();
    if (!mounted) return;

    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    if (provider.errorMessage != null) {
      // Navigate to login even if init failed — login screen shows the error
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    if (provider.authState.isAuthenticated) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A237E),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.security,
              size: 80,
              color: Colors.white.withValues(alpha: 0.9),
            ),
            const SizedBox(height: 24),
            const Text(
              'Secure Exam Browser',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 16),
            Text(
              'Initializing...',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
