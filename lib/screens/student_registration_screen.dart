import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'student_home_screen.dart';

class StudentRegistrationScreen extends StatefulWidget {
  const StudentRegistrationScreen({super.key});

  @override
  State<StudentRegistrationScreen> createState() =>
      _StudentRegistrationScreenState();
}

class _StudentRegistrationScreenState
    extends State<StudentRegistrationScreen> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

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
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> register() async {
    final username =
        usernameController.text.trim().toLowerCase();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (!RegExp(r'^[a-z0-9_.-]{3,30}$').hasMatch(username)) {
      showMessage(
        'Username must be 3–30 characters: '
        'letters, numbers, dots, underscores or hyphens.',
      );
      return;
    }

    if (password.length < 6) {
      showMessage('Password must contain at least 6 characters.');
      return;
    }

    if (password != confirmPassword) {
      showMessage('Passwords do not match.');
      return;
    }

    setState(() => isLoading = true);

    User? createdUser;

    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: makeLoginId(username),
        password: password,
      );

      createdUser = credential.user;

      if (createdUser == null) {
        showMessage('Registration failed. Please try again.');
        return;
      }

      await FirebaseFirestore.instance
          .collection('students')
          .doc(createdUser.uid)
          .set({
        'username': username,
        'email': makeLoginId(username),
        'role': 'student',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) =>
              StudentHomeScreen(username: username),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        showMessage('That username is already taken.');
      } else if (e.code == 'weak-password') {
        showMessage('Please choose a stronger password.');
      } else {
        showMessage(e.message ?? 'Registration failed.');
      }
    } catch (_) {
      // If profile creation failed, don't leave the user
      // signed in without a student profile.
      if (createdUser != null) {
        await FirebaseAuth.instance.signOut();
      }

      showMessage(
        'Could not complete registration. Please try again.',
      );
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
      appBar: AppBar(
        title: const Text('Student Registration'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.person_add, size: 75),
                const SizedBox(height: 20),
                const Text(
                  'Create Student Account',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),
                TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Choose Username',
                    hintText: 'Example: student01',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: passwordController,
                  obscureText: hidePassword,
                  decoration: InputDecoration(
                    labelText: 'Create Password',
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
                const SizedBox(height: 20),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: hidePassword,
                  decoration: const InputDecoration(
                    labelText: 'Confirm Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  height: 55,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : register,
                    child: isLoading
                        ? const CircularProgressIndicator()
                        : const Text(
                            'Create Account',
                            style: TextStyle(fontSize: 18),
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