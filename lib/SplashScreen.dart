import 'dart:async';
import 'package:flutter/material.dart';
import 'HomeScreen.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller!, curve: Curves.easeIn);
    _controller!.forward();
    print('SplashScreen: Starting timer'); // Debug log
    Timer(const Duration(seconds: 5), () {
      print('SplashScreen: Attempting navigation to HomeScreen'); // Debug log
      if (mounted) {
        try {
          Navigator.pushReplacement(
            this.context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
          print('SplashScreen: Successfully navigated to HomeScreen'); // Debug log
        } catch (e) {
          print('SplashScreen: Navigation error: $e'); // Debug log
        }
      } else {
        print('SplashScreen: Widget not mounted, skipping navigation');
      }
    });
  }

  @override
  void dispose() {
    print('SplashScreen: Cleaning up'); // Debug log
    _controller!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FadeTransition(
          opacity: _animation!,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text(
                'Study Buddy',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFBB86FC),
                ),
              ),
              SizedBox(height: 20),
              CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6200EA))),
            ],
          ),
        ),
      ),
    );
  }
}