import 'package:flutter/material.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 18, 18, 18),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: SizedBox(
              height: MediaQuery.of(context).size.height - 40, // Full height minus SafeArea
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Top content
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 20),
                      RichText(
                        textAlign: TextAlign.center,
                        text: const TextSpan(
                          style:
                              TextStyle(fontSize: 42, fontWeight: FontWeight.bold),
                          children: [
                            TextSpan(
                              text: 'Incubate',
                              style: TextStyle(color: Colors.white),
                            ),
                            TextSpan(
                              text: 'X',
                              style: TextStyle(color: Colors.blueAccent),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Powered by LEAD College (Autonomous)\nExclusively for E-LEAD Students',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Color.fromARGB(255, 207, 203, 203)),
                      ),
                      const SizedBox(height: 40),
                      Image.asset(
                        'assets/leadbi.png',
                        height: 200,
                        width: 150,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.business,
                          size: 100,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 40),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/login');
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 15,
                          ),
                        ),
                        child: const Text('Login'),
                      ),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/register');
                        },
                        child: const Text(
                          'New here? Register',
                          style: TextStyle(color: Colors.blueAccent),
                        ),
                      ),
                    ],
                  ),

                  // Footer
                  const Padding(
                    padding: EdgeInsets.only(bottom: 40.0),
                    child: Text(
                      '© 2025 LEAD College (Autonomous)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
