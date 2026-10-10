import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../data/exam_data.dart';
import 'exam_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  final String username;
  const StudentHomeScreen({super.key, required this.username});
  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  DateTime parseDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }

  bool examStarted(DateTime startDateTime) {
    return !DateTime.now().isBefore(startDateTime);
  }

  String formatDateTime(DateTime dateTime) {
    final date =
        '${dateTime.day.toString().padLeft(2, '0')}/'
        '${dateTime.month.toString().padLeft(2, '0')}/'
        '${dateTime.year}';
    final time = TimeOfDay.fromDateTime(dateTime);
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$date at $hour:$minute $period';
  }

  Future<void> startExam(String examId, Map<String, dynamic> data) async {
    final startDateTime = parseDateTime(data['startDateTime']);
    if (!examStarted(startDateTime)) {
      showMessage(
        'This exam has not started yet. '
        'Starts at ${formatDateTime(startDateTime)}.',
      );
      return;
    }
    final rawQuestions = data['questions'] as List? ?? [];
    if (rawQuestions.isEmpty) {
      showMessage('This exam has no questions yet.');
      return;
    }
    try {
      final questions = rawQuestions.map((item) {
        final questionData = Map<String, dynamic>.from(item as Map);
        return Question(
          question: questionData['question'] as String? ?? '',
          options: List<String>.from(
            questionData['options'] ?? const <String>[],
          ),
          correctAnswer: (questionData['correctAnswer'] as num?)?.toInt() ?? -1,
          imagePath: questionData['imagePath'] as String?,
        );
      }).toList();
      final exam = Exam(
        id: examId,
        title: data['title'] as String? ?? 'Untitled Exam',
        startDateTime: startDateTime,
        durationMinutes: (data['durationMinutes'] as num?)?.toInt() ?? 60,
        positiveMarks: (data['positiveMarks'] as num?)?.toDouble() ?? 4,
        negativeMarks: (data['negativeMarks'] as num?)?.toDouble() ?? 1,
        questions: questions,
      );
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) =>
              ExamScreen(username: widget.username, exam: exam),
        ),
      );
    } catch (error) {
      showMessage('Could not launch the exam: $error');
    }
  }

  void showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Welcome, ${widget.username}',
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Available Examinations',
                  style: TextStyle(fontSize: 20),
                ),
                const SizedBox(height: 30),
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('publishedExams')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Card(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'Unable to load exams. '
                            'Please check your connection '
                            'or contact the administrator.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return const Padding(
                        padding: EdgeInsets.all(30),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final documents = snapshot.data?.docs ?? [];
                    if (documents.isEmpty) {
                      return const Card(
                        child: Padding(
                          padding: EdgeInsets.all(30),
                          child: Column(
                            children: [
                              Icon(Icons.assignment_outlined, size: 70),
                              SizedBox(height: 15),
                              Text(
                                'No published exams are available yet.',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Please check again later.',
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return Column(
                      children: documents.map((document) {
                        final data = document.data();
                        final title =
                            data['title'] as String? ?? 'Untitled Exam';
                        final startDateTime = parseDateTime(
                          data['startDateTime'],
                        );
                        final duration =
                            (data['durationMinutes'] as num?)?.toInt() ?? 60;
                        final positiveMarks =
                            (data['positiveMarks'] as num?)?.toDouble() ?? 4;
                        final negativeMarks =
                            (data['negativeMarks'] as num?)?.toDouble() ?? 1;
                        final questions = data['questions'] as List? ?? [];
                        final started = examStarted(startDateTime);
                        return _ExamCard(
                          title: title,
                          startDateTime: startDateTime,
                          durationMinutes: duration,
                          positiveMarks: positiveMarks,
                          negativeMarks: negativeMarks,
                          questionCount: questions.length,
                          started: started,
                          formatDateTime: formatDateTime,
                          onStart: () => startExam(document.id, data),
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 30),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.bar_chart),
                    title: const Text(
                      'My Results',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text('Your completed examination results.'),
                    onTap: showMyResults,
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
        .where((result) => result.username == widget.username)
        .toList();
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('My Results'),
          content: SizedBox(
            width: 500,
            child: results.isEmpty
                ? const Text('You have no completed exams yet.')
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final result = results[index];
                      return ListTile(
                        leading: const Icon(Icons.check_circle),
                        title: Text(result.examTitle),
                        subtitle: Text(
                          'Correct: ${result.correct} | '
                          'Wrong: ${result.wrong} | '
                          'Unanswered: ${result.unanswered}',
                        ),
                        trailing: Text(
                          '${result.marks} marks',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}

class _ExamCard extends StatelessWidget {
  final String title;
  final DateTime startDateTime;
  final int durationMinutes;
  final double positiveMarks;
  final double negativeMarks;
  final int questionCount;
  final bool started;
  final String Function(DateTime) formatDateTime;
  final VoidCallback onStart;
  const _ExamCard({
    required this.title,
    required this.startDateTime,
    required this.durationMinutes,
    required this.positiveMarks,
    required this.negativeMarks,
    required this.questionCount,
    required this.started,
    required this.formatDateTime,
    required this.onStart,
  });
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.assignment, size: 45),
                const SizedBox(width: 15),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Starts: ${formatDateTime(startDateTime)}'),
            const SizedBox(height: 7),
            Text('Duration: $durationMinutes minutes'),
            const SizedBox(height: 7),
            Text('Correct answer: +$positiveMarks marks'),
            const SizedBox(height: 7),
            Text('Wrong answer: -$negativeMarks marks'),
            const SizedBox(height: 7),
            Text('Questions: $questionCount'),
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(
                  started ? Icons.play_circle : Icons.schedule,
                  color: started ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    started ? 'Exam is available' : 'Exam has not started',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: started ? Colors.green : Colors.orange,
                    ),
                  ),
                ),
                SizedBox(
                  width: 150,
                  height: 45,
                  child: ElevatedButton(
                    onPressed: started ? onStart : null,
                    child: Text(started ? 'Start Exam' : 'Not Started'),
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
