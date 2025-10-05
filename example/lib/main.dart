import 'package:biologreen_flutter_sdk/biologreen_flutter_sdk.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BioLogreen SDK Example',
      theme: ThemeData(primarySwatch: Colors.green),
      home: const ExampleScreen(),
    );
  }
}

class ExampleScreen extends StatefulWidget {
  const ExampleScreen({super.key});

  @override
  State<ExampleScreen> createState() => _ExampleScreenState();
}

class _ExampleScreenState extends State<ExampleScreen> {
  late BioLogreenClient _client;

  @override
  void initState() {
    super.initState();
    _client = BioLogreenClient(
      apiKey: 'your_test_api_key_here', // Replace with your key from your biologreen dashboard for the project you created
      baseUrl: 'https://your-backend.com/v1', // Optional
    );
    _initializeClient();
  }

  Future<void> _initializeClient() async {
    try {
      await _client.initialize();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Init failed: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _client.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    try {
      final response = await _client.signupWithFace(
        customFields: {'email': 'example@email.com'},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Signup success: User ID ${response.userId}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Signup failed: $e')),
        );
      }
    }
  }

  Future<void> _handleLogin() async {
    try {
      final response = await _client.loginWithFace();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login success: User ID ${response.userId}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('BioLogreen Example')),
      body: AnimatedBuilder(
        animation: _client.state,
        builder: (context, child) {
          if (_client.state.isInitializing || _client.cameraController == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_client.state.error != null) {
            return Center(child: Text('Error: ${_client.state.error}'));
          }
          return Stack(
            fit: StackFit.expand,
            children: [
              CameraPreview(_client.cameraController!),
              Positioned(
                bottom: 100,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    Text(
                      _client.state.isFaceDetected ? 'Face Detected' : 'No Face Detected',
                      style: const TextStyle(color: Colors.white, fontSize: 20, shadows: [Shadow(blurRadius: 2.0, color: Colors.black)]),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: _client.state.isLoading ? null : _handleSignup,
                          child: const Text('Signup'),
                        ),
                        ElevatedButton(
                          onPressed: _client.state.isLoading ? null : _handleLogin,
                          child: const Text('Login'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (_client.state.isLoading)
                const Center(child: CircularProgressIndicator()),
            ],
          );
        },
      ),
    );
  }
}