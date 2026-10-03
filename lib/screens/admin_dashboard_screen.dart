import 'package:flutter/material.dart';

import 'question_upload_screen.dart';
import 'exam_management_screen.dart';
import 'student_management_screen.dart';
import 'results_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  final String username;

  const AdminDashboardScreen({
    super.key,
    required this.username,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).popUntil(
                (route) => route.isFirst,
              );
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 1100,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Welcome, $username',
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  'NEET Exam Administration',
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),

                const SizedBox(height: 35),

                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  shrinkWrap: true,
                  physics:
                      const NeverScrollableScrollPhysics(),
                  childAspectRatio: 2.2,
                  children: [
                    _AdminCard(
                      icon: Icons.edit_calendar,
                      title: 'Manage Exams',
                      description:
                          'Create and manage multiple examinations.',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                const ExamManagementScreen(),
                          ),
                        );
                      },
                    ),

                    _AdminCard(
                      icon: Icons.add_box,
                      title: 'Upload Questions',
                      description:
                          'Add questions to a selected exam.',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                const QuestionUploadScreen(),
                          ),
                        );
                      },
                    ),

                    _AdminCard(
                      icon: Icons.people,
                      title: 'Students',
                      description:
                          'Monitor students and their exam status.',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                const StudentManagementScreen(),
                          ),
                        );
                      },
                    ),

                    _AdminCard(
                      icon: Icons.bar_chart,
                      title: 'Results',
                      description:
                          'View student marks and results.',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                const ResultsScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 35),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Admin Workflow',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 15),

                        const Text(
                          '1. Create an exam',
                        ),

                        const Text(
                          '2. Select the exam',
                        ),

                        const Text(
                          '3. Add questions',
                        ),

                        const Text(
                          '4. Add figures or diagrams',
                        ),

                        const Text(
                          '5. Publish the exam',
                        ),
                      ],
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

class _AdminCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _AdminCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(
                icon,
                size: 50,
              ),

              const SizedBox(width: 20),

              Expanded(
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      description,
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}