import 'package:flutter/material.dart';
import '../data/exam_data.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Results')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ExamData.results.isEmpty
                ? const Center(
                    child: Text(
                      'No results available yet.',
                      style: TextStyle(fontSize: 18),
                    ),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Student')),
                        DataColumn(label: Text('Correct')),
                        DataColumn(label: Text('Wrong')),
                        DataColumn(label: Text('Unanswered')),
                        DataColumn(label: Text('Marks')),
                      ],
                      rows: ExamData.results.map((result) {
                        return DataRow(
                          cells: [
                            DataCell(Text(result.username)),
                            DataCell(Text(result.correct.toString())),
                            DataCell(Text(result.wrong.toString())),
                            DataCell(Text(result.unanswered.toString())),
                            DataCell(Text(result.marks.toString())),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
