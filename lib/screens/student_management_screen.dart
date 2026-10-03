import 'package:flutter/material.dart';
import '../data/exam_data.dart';

class StudentManagementScreen extends StatelessWidget {
  const StudentManagementScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Students')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ExamData.results.isEmpty
                ? const Center(
                    child: Text(
                      'No student exam attempts yet.',
                      style: TextStyle(fontSize: 18),
                    ),
                  )
                : ListView.builder(
                    itemCount: ExamData.results.length,
                    itemBuilder: (context, index) {
                      final result = ExamData.results[index];
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.person),
                          title: Text(result.username),
                          subtitle: Text('Exam attempt completed'),
                          trailing: Text('${result.marks} marks'),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}
