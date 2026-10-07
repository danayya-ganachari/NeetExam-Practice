import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'admin_dashboard_screen.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() =>
      _AdminLoginScreenState();
}

class _AdminLoginScreenState
    extends State<AdminLoginScreen> {
  final TextEditingController usernameController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  bool hidePassword = true;
  bool isLoading = false;

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // Website username → Firebase email
  String? getFirebaseEmail(String username) {
    switch (username.trim().toLowerCase()) {
      case 'ownerdanayya':
        return 'danayyasganachari@gmail.com';

      case 'admin':
        return 'bioedgefor360@gmail.com';

      default:
        return null;
    }
  }

  Future<void> login() async {
    final username =
        usernameController.text.trim().toLowerCase();

    final password =
        passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      showMessage(
        'Please enter username and password.',
      );
      return;
    }

    final firebaseEmail =
        getFirebaseEmail(username);

    if (firebaseEmail == null) {
      showMessage(
        'Invalid admin username or password.',
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final credential =
          await FirebaseAuth.instance
              .signInWithEmailAndPassword(
        email: firebaseEmail,
        password: password,
      );

      if (credential.user == null) {
        showMessage(
          'Login failed. Please try again.',
        );
        return;
      }

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) =>
              AdminDashboardScreen(
            username: username,
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String message;

      switch (e.code) {
        case 'invalid-credential':
        case 'user-not-found':
        case 'wrong-password':
          message =
              'Invalid admin username or password.';
          break;

        case 'user-disabled':
          message =
              'This admin account has been disabled.';
          break;

        case 'too-many-requests':
          message =
              'Too many login attempts. Try again later.';
          break;

        case 'network-request-failed':
          message =
              'Network error. Check your internet connection.';
          break;

        default:
          message =
              'Login failed. Please try again.';
      }

      showMessage(message);
    } catch (e) {
      showMessage(
        'Something went wrong. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Login'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 450,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.admin_panel_settings,
                  size: 80,
                ),

                const SizedBox(height: 20),

                const Text(
                  'Admin Login',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 35),

                TextField(
                  controller: usernameController,
                  textInputAction:
                      TextInputAction.next,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    hintText:
                        'Enter your admin username',
                    border: OutlineInputBorder(),
                    prefixIcon:
                        Icon(Icons.person),
                  ),
                ),

                const SizedBox(height: 20),

                TextField(
                  controller: passwordController,
                  obscureText: hidePassword,
                  autocorrect: false,
                  enableSuggestions: false,
                  textInputAction:
                      TextInputAction.done,
                  onSubmitted: (_) {
                    if (!isLoading) {
                      login();
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText:
                        'Enter your admin password',
                    border:
                        const OutlineInputBorder(),
                    prefixIcon:
                        const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          hidePassword =
                              !hidePassword;
                        });
                      },
                      icon: Icon(
                        hidePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                SizedBox(
                  height: 55,
                  child: ElevatedButton(
                    onPressed:
                        isLoading ? null : login,
                    child: isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 18,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}