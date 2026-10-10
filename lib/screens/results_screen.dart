import 'package:flutter/material.dart';
import '../data/exam_data.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final results = ExamData.results;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exam Results'),
      ),
      body: results.isEmpty
          ? const Center(
              child: Text('No exam results available yet.'),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Student')),
                  DataColumn(label: Text('Exam')),
                  DataColumn(label: Text('Correct')),
                  DataColumn(label: Text('Wrong')),
                  DataColumn(label: Text('Unanswered')),
                  DataColumn(label: Text('Marks')),
                ],
                rows: results.map((result) {
                  return DataRow(
                    cells: [
                      DataCell(Text(result.username)),
                      DataCell(Text(result.examTitle)),
                      DataCell(Text('${result.correct}')),
                      DataCell(Text('${result.wrong}')),
                      DataCell(Text('${result.unanswered}')),
                      DataCell(Text('${result.marks}')),
                    ],
                  );
                }).toList(),
              ),
            ),
    );
  }
}