import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'exam_management_screen.dart';
import 'question_upload_screen.dart';
import 'student_management_screen.dart';
import 'results_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  final String username;

  const AdminDashboardScreen({
    super.key,
    required this.username,
  });

  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    if (!context.mounted) {
      return;
    }

    Navigator.of(context).popUntil(
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            onPressed: () => logout(context),
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile =
              constraints.maxWidth < 600;

          final horizontalPadding =
              isMobile ? 16.0 : 30.0;

          return SingleChildScrollView(
            padding: EdgeInsets.all(
              horizontalPadding,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(
                  maxWidth: 1100,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 25),

                    Text(
                      'Admin Dashboard',
                      style: TextStyle(
                        fontSize:
                            isMobile ? 26 : 32,
                        fontWeight:
                            FontWeight.bold,
                      ),
                      textAlign:
                          TextAlign.center,
                    ),

                    const SizedBox(height: 10),

                    Text(
                      'Welcome, $username',
                      style: TextStyle(
                        fontSize:
                            isMobile ? 16 : 18,
                      ),
                      textAlign:
                          TextAlign.center,
                    ),

                    const SizedBox(height: 35),

                    GridView.count(
                      crossAxisCount:
                          isMobile ? 1 : 2,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      shrinkWrap: true,
                      physics:
                          const NeverScrollableScrollPhysics(),
                      childAspectRatio:
                          isMobile ? 2.8 : 2.2,
                      children: [
                        _AdminCard(
                          icon:
                              Icons.edit_calendar,
                          title: 'Manage Exams',
                          subtitle:
                              'Create, edit and schedule exams',
                          onTap: () {
                            Navigator.of(context)
                                .push(
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        const ExamManagementScreen(),
                              ),
                            );
                          },
                        ),

                        _AdminCard(
                          icon:
                              Icons.upload_file,
                          title:
                              'Upload Questions',
                          subtitle:
                              'Add questions and options',
                          onTap: () {
                            Navigator.of(context)
                                .push(
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        const QuestionUploadScreen(),
                              ),
                            );
                          },
                        ),

                        _AdminCard(
                          icon: Icons.people,
                          title: 'Students',
                          subtitle:
                              'View student activity',
                          onTap: () {
                            Navigator.of(context)
                                .push(
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        const StudentManagementScreen(),
                              ),
                            );
                          },
                        ),

                        _AdminCard(
                          icon:
                              Icons.bar_chart,
                          title: 'Results',
                          subtitle:
                              'View exam results',
                          onTap: () {
                            Navigator.of(context)
                                .push(
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        const ResultsScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AdminCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AdminCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(12),
                  color: Theme.of(context)
                      .colorScheme
                      .primaryContainer,
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: Theme.of(context)
                      .colorScheme
                      .onPrimaryContainer,
                ),
              ),

              const SizedBox(width: 18),

              Expanded(
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              const Icon(
                Icons.arrow_forward_ios,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}