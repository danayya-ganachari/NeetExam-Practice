import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class StudentRegistrationScreen extends StatefulWidget {
  const StudentRegistrationScreen({super.key});

  @override
  State<StudentRegistrationScreen> createState() =>
      _StudentRegistrationScreenState();
}

class _StudentRegistrationScreenState
    extends State<StudentRegistrationScreen> {
  final TextEditingController nameController =
      TextEditingController();

  final TextEditingController usernameController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool hidePassword = true;
  bool hideConfirmPassword = true;
  bool isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();

    super.dispose();
  }

  // Converts the student's username into an internal
  // Firebase email address.
  //
  // The student never sees or enters this email.
  String makeFirebaseEmail(String username) {
    return '${username.toLowerCase()}@students.neetexamspractice.local';
  }

  Future<void> createAccount() async {
    final name = nameController.text.trim();
    final username =
        usernameController.text.trim().toLowerCase();
    final password = passwordController.text;
    final confirmPassword =
        confirmPasswordController.text;

    if (name.isEmpty) {
      showMessage('Please enter your name.');
      return;
    }

    if (username.isEmpty) {
      showMessage('Please enter a username.');
      return;
    }

    if (!RegExp(r'^[a-z0-9_]{3,20}$')
        .hasMatch(username)) {
      showMessage(
        'Username must be 3-20 characters and use only '
        'letters, numbers, or underscore.',
      );
      return;
    }

    if (password.length < 6) {
      showMessage(
        'Password must contain at least 6 characters.',
      );
      return;
    }

    if (password != confirmPassword) {
      showMessage(
        'Passwords do not match.',
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final firebaseEmail =
          makeFirebaseEmail(username);

      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: firebaseEmail,
        password: password,
      );

      final user = credential.user;

      if (user == null) {
        showMessage(
          'Account creation failed.',
        );
        return;
      }

      await FirebaseFirestore.instance
          .collection('students')
          .doc(user.uid)
          .set({
        'username': username,
        'name': name,
        'role': 'student',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) {
        return;
      }

      showMessage(
        'Student account created successfully.',
      );

      await Future.delayed(
        const Duration(milliseconds: 700),
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      String message;

      switch (e.code) {
        case 'email-already-in-use':
          message =
              'That username is already taken.';
          break;

        case 'weak-password':
          message =
              'Password is too weak.';
          break;

        case 'network-request-failed':
          message =
              'Network error. Check your internet connection.';
          break;

        default:
          message =
              'Could not create account. Please try again.';
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

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

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
        title: const Text('Create Student Account'),
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
                  Icons.person_add,
                  size: 80,
                ),

                const SizedBox(height: 20),

                const Text(
                  'Create Student Account',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 10),

                const Text(
                  'Create your account using a username '
                  'and password.',
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 35),

                TextField(
                  controller: nameController,
                  textInputAction:
                      TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    hintText: 'Enter your name',
                    border: OutlineInputBorder(),
                    prefixIcon:
                        Icon(Icons.person),
                  ),
                ),

                const SizedBox(height: 20),

                TextField(
                  controller: usernameController,
                  textInputAction:
                      TextInputAction.next,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    hintText: 'Example: student01',
                    border: OutlineInputBorder(),
                    prefixIcon:
                        Icon(Icons.account_circle),
                  ),
                ),

                const SizedBox(height: 20),

                TextField(
                  controller: passwordController,
                  obscureText: hidePassword,
                  textInputAction:
                      TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText:
                        'At least 6 characters',
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

                const SizedBox(height: 20),

                TextField(
                  controller:
                      confirmPasswordController,
                  obscureText:
                      hideConfirmPassword,
                  textInputAction:
                      TextInputAction.done,
                  onSubmitted: (_) {
                    if (!isLoading) {
                      createAccount();
                    }
                  },
                  decoration: InputDecoration(
                    labelText:
                        'Confirm Password',
                    hintText:
                        'Enter password again',
                    border:
                        const OutlineInputBorder(),
                    prefixIcon:
                        const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          hideConfirmPassword =
                              !hideConfirmPassword;
                        });
                      },
                      icon: Icon(
                        hideConfirmPassword
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
                    onPressed: isLoading
                        ? null
                        : createAccount,
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
                            'Create Account',
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