import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'student_home_screen.dart';
import 'student_registration_screen.dart';

class StudentLoginScreen extends StatefulWidget {
  const StudentLoginScreen({super.key});

  @override
  State<StudentLoginScreen> createState() =>
      _StudentLoginScreenState();
}

class _StudentLoginScreenState
    extends State<StudentLoginScreen> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  bool hidePassword = true;
  bool isLoading = false;

  String makeLoginId(String username) {
    return '${username.trim().toLowerCase()}'
        '@students.neetexamspractice.firebaseapp.com';
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    final username =
        usernameController.text.trim().toLowerCase();
    final password = passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      showMessage('Enter your username and password.');
      return;
    }

    setState(() => isLoading = true);

    try {
      final credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: makeLoginId(username),
        password: password,
      );

      final user = credential.user;

      if (user == null) {
        showMessage('Login failed. Please try again.');
        return;
      }

      final profile = await FirebaseFirestore.instance
          .collection('students')
          .doc(user.uid)
          .get();

      if (!profile.exists ||
          profile.data()?['role'] != 'student' ||
          profile.data()?['username'] != username) {
        await FirebaseAuth.instance.signOut();
        showMessage('Student profile not found.');
        return;
      }

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) =>
              StudentHomeScreen(username: username),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-credential' ||
          e.code == 'wrong-password' ||
          e.code == 'user-not-found' ||
          e.code == 'invalid-email') {
        showMessage('Invalid username or password.');
      } else {
        showMessage(e.message ?? 'Login failed.');
      }
    } catch (_) {
      showMessage('Could not log in. Please try again.');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Login')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.school, size: 80),
                const SizedBox(height: 20),
                const Text(
                  'Student Login',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 35),
                TextField(
                  controller: usernameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: passwordController,
                  obscureText: hidePassword,
                  onSubmitted: (_) {
                    if (!isLoading) login();
                  },
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          hidePassword = !hidePassword;
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
                    onPressed: isLoading ? null : login,
                    child: isLoading
                        ? const CircularProgressIndicator()
                        : const Text(
                            'Login',
                            style: TextStyle(fontSize: 18),
                          ),
                  ),
                ),
                const SizedBox(height: 15),
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  const StudentRegistrationScreen(),
                            ),
                          );
                        },
                  child: const Text(
                    'New student? Register here',
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