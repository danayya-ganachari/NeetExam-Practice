import 'package:flutter/material.dart';

import '../data/exam_data.dart';
import 'exam_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  final String username;

  const StudentHomeScreen({
    super.key,
    required this.username,
  });

  @override
  State<StudentHomeScreen> createState() =>
      _StudentHomeScreenState();
}

class _StudentHomeScreenState
    extends State<StudentHomeScreen> {
  bool examStarted(Exam exam) {
    final now = DateTime.now();

    return now.isAfter(exam.startDateTime) ||
        now.isAtSameMomentAs(
          exam.startDateTime,
        );
  }

  String formatDateTime(DateTime dateTime) {
    final date =
        '${dateTime.day.toString().padLeft(2, '0')}/'
        '${dateTime.month.toString().padLeft(2, '0')}/'
        '${dateTime.year}';

    final time =
        TimeOfDay.fromDateTime(dateTime);

    final hour = time.hourOfPeriod == 0
        ? 12
        : time.hourOfPeriod;

    final minute =
        time.minute.toString().padLeft(2, '0');

    final period =
        time.period == DayPeriod.am
            ? 'AM'
            : 'PM';

    return '$date at $hour:$minute $period';
  }

  void startExam(Exam exam) {
    if (!examStarted(exam)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Exam starts on '
            '${formatDateTime(exam.startDateTime)}.',
          ),
        ),
      );

      return;
    }

    if (exam.questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This exam does not have any questions yet.',
          ),
        ),
      );

      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ExamScreen(
          username: widget.username,
          exam: exam,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Student Dashboard',
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).popUntil(
                (route) => route.isFirst,
              );
            },
            icon: const Icon(
              Icons.logout,
            ),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 1000,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Welcome, ${widget.username}',
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  'Available Examinations',
                  style: TextStyle(
                    fontSize: 20,
                  ),
                ),

                const SizedBox(height: 30),

                if (ExamData.exams.isEmpty)
                  const Card(
                    child: Padding(
                      padding:
                          EdgeInsets.all(30),
                      child: Column(
                        children: [
                          Icon(
                            Icons.assignment_outlined,
                            size: 70,
                          ),
                          SizedBox(height: 15),
                          Text(
                            'No exams are available yet.',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                            textAlign:
                                TextAlign.center,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Please check again later.',
                            textAlign:
                                TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...ExamData.exams.map(
                    (exam) {
                      final started =
                          examStarted(exam);

                      return _ExamCard(
                        exam: exam,
                        started: started,
                        startExam: () {
                          startExam(exam);
                        },
                        formatDateTime:
                            formatDateTime,
                      );
                    },
                  ),

                const SizedBox(height: 30),

                Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.bar_chart,
                    ),
                    title: const Text(
                      'My Results',
                      style: TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    subtitle: const Text(
                      'Your completed examination results.',
                    ),
                    onTap: () {
                      showMyResults();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void showMyResults() {
    final results = ExamData.results
        .where(
          (result) =>
              result.username ==
              widget.username,
        )
        .toList();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'My Results',
          ),
          content: SizedBox(
            width: 500,
            child: results.isEmpty
                ? const Text(
                    'You have no completed exams yet.',
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: results.length,
                    itemBuilder:
                        (context, index) {
                      final result =
                          results[index];

                      return ListTile(
                        leading: const Icon(
                          Icons.check_circle,
                        ),
                        title: Text(
                          result.examTitle,
                        ),
                        subtitle: Text(
                          'Correct: '
                          '${result.correct} | '
                          'Wrong: '
                          '${result.wrong} | '
                          'Unanswered: '
                          '${result.unanswered}',
                        ),
                        trailing: Text(
                          '${result.marks} marks',
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Close',
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ExamCard extends StatelessWidget {
  final Exam exam;
  final bool started;
  final VoidCallback startExam;
  final String Function(DateTime)
      formatDateTime;

  const _ExamCard({
    required this.exam,
    required this.started,
    required this.startExam,
    required this.formatDateTime,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(
        bottom: 20,
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.assignment,
                  size: 45,
                ),

                const SizedBox(width: 15),

                Expanded(
                  child: Text(
                    exam.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Text(
              'Starts: '
              '${formatDateTime(exam.startDateTime)}',
            ),

            const SizedBox(height: 7),

            Text(
              'Duration: '
              '${exam.durationMinutes} minutes',
            ),

            const SizedBox(height: 7),

            Text(
              'Correct answer: '
              '+${exam.positiveMarks} marks',
            ),

            const SizedBox(height: 7),

            Text(
              'Wrong answer: '
              '-${exam.negativeMarks} marks',
            ),

            const SizedBox(height: 7),

            Text(
              'Questions: '
              '${exam.questions.length}',
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Icon(
                  started
                      ? Icons.play_circle
                      : Icons.schedule,
                  color: started
                      ? Colors.green
                      : Colors.orange,
                ),

                const SizedBox(width: 8),

                Text(
                  started
                      ? 'Exam is available'
                      : 'Exam has not started',
                  style: TextStyle(
                    fontWeight:
                        FontWeight.bold,
                    color: started
                        ? Colors.green
                        : Colors.orange,
                  ),
                ),

                const Spacer(),

                SizedBox(
                  width: 150,
                  height: 45,
                  child: ElevatedButton(
                    onPressed: started
                        ? startExam
                        : null,
                    child: Text(
                      started
                          ? 'Start Exam'
                          : 'Not Started',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}