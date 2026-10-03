import 'dart:async';

import 'package:flutter/material.dart';

import '../data/exam_data.dart';

class ExamScreen extends StatefulWidget {
  final String username;
  final Exam exam;

  const ExamScreen({
    super.key,
    required this.username,
    required this.exam,
  });

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> {
  int currentQuestion = 0;

  late List<int?> answers;

  late int remainingSeconds;

  Timer? timer;

  bool submitted = false;

  @override
  void initState() {
    super.initState();

    answers = List<int?>.filled(
      widget.exam.questions.length,
      null,
    );

    remainingSeconds =
        widget.exam.durationMinutes * 60;

    startTimer();
  }

  void startTimer() {
    timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        if (remainingSeconds <= 0) {
          timer.cancel();
          submitExam();
          return;
        }

        setState(() {
          remainingSeconds--;
        });
      },
    );
  }

  String formatTime(int seconds) {
    final hours = seconds ~/ 3600;

    final minutes =
        (seconds % 3600) ~/ 60;

    final remaining =
        seconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${remaining.toString().padLeft(2, '0')}';
    }

    return '${minutes.toString().padLeft(2, '0')}:'
        '${remaining.toString().padLeft(2, '0')}';
  }

  void submitExam() {
    if (submitted) {
      return;
    }

    submitted = true;

    timer?.cancel();

    int correct = 0;
    int wrong = 0;
    int unanswered = 0;

    for (int i = 0; i < answers.length; i++) {
      final selected = answers[i];

      if (selected == null) {
        unanswered++;
      } else if (
          selected ==
          widget.exam.questions[i].correctAnswer) {
        correct++;
      } else {
        wrong++;
      }
    }

    final marks =
        (correct * widget.exam.positiveMarks) -
        (wrong * widget.exam.negativeMarks);

    ExamData.results.add(
      StudentResult(
        username: widget.username,
        examId: widget.exam.id,
        examTitle: widget.exam.title,
        correct: correct,
        wrong: wrong,
        unanswered: unanswered,
        marks: marks,
      ),
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => ExamResultScreen(
          username: widget.username,
          exam: widget.exam,
          correct: correct,
          wrong: wrong,
          unanswered: unanswered,
          marks: marks,
        ),
      ),
    );
  }

  Future<bool> handleBack() async {
    if (submitted) {
      return true;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'You cannot exit the exam after starting it.',
        ),
      ),
    );

    return false;
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.exam.questions.isEmpty) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (
          didPop,
          result,
        ) {
          if (!didPop) {
            ScaffoldMessenger.of(context)
                .showSnackBar(
              const SnackBar(
                content: Text(
                  'This exam has no questions.',
                ),
              ),
            );
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(widget.exam.title),
            automaticallyImplyLeading: false,
          ),
          body: const Center(
            child: Text(
              'No questions available for this exam.',
              style: TextStyle(
                fontSize: 20,
              ),
            ),
          ),
        ),
      );
    }

    final question =
        widget.exam.questions[currentQuestion];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (
        didPop,
        result,
      ) {
        if (!didPop) {
          handleBack();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(widget.exam.title),
          actions: [
            Container(
              margin: const EdgeInsets.only(
                right: 20,
              ),
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(8),
                border: Border.all(
                  color: remainingSeconds <= 60
                      ? Colors.red
                      : Colors.grey,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.timer,
                    size: 20,
                    color: remainingSeconds <= 60
                        ? Colors.red
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    formatTime(
                      remainingSeconds,
                    ),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                      color:
                          remainingSeconds <= 60
                              ? Colors.red
                              : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 900,
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Question '
                    '${currentQuestion + 1} '
                    'of '
                    '${widget.exam.questions.length}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  Card(
                    child: Padding(
                      padding:
                          const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            question.question,
                            style:
                                const TextStyle(
                              fontSize: 22,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          if (question.imagePath !=
                              null) ...[
                            const SizedBox(
                              height: 20,
                            ),
                            _QuestionImage(
                              imagePath:
                                  question.imagePath!,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Expanded(
                    child: ListView.builder(
                      itemCount:
                          question.options.length,
                      itemBuilder:
                          (context, index) {
                        return Card(
                          child:
                              RadioListTile<int>(
                            value: index,
                            groupValue:
                                answers[
                                    currentQuestion],
                            title: Text(
                              question
                                  .options[index],
                              style:
                                  const TextStyle(
                                fontSize: 17,
                              ),
                            ),
                            onChanged:
                                (value) {
                              if (value ==
                                  null) {
                                return;
                              }

                              setState(() {
                                answers[
                                        currentQuestion] =
                                    value;
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 15),

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .spaceBetween,
                    children: [
                      ElevatedButton.icon(
                        onPressed:
                            currentQuestion ==
                                    0
                                ? null
                                : () {
                                    setState(() {
                                      currentQuestion--;
                                    });
                                  },
                        icon: const Icon(
                          Icons.arrow_back,
                        ),
                        label: const Text(
                          'Previous',
                        ),
                      ),

                      if (currentQuestion <
                          widget.exam.questions
                                  .length -
                              1)
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              currentQuestion++;
                            });
                          },
                          icon: const Icon(
                            Icons.arrow_forward,
                          ),
                          label: const Text(
                            'Next',
                          ),
                        )
                      else
                        ElevatedButton.icon(
                          onPressed:
                              showSubmitConfirmation,
                          icon: const Icon(
                            Icons.check,
                          ),
                          label: const Text(
                            'Submit Exam',
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void showSubmitConfirmation() {
    final unanswered = answers
        .where((answer) => answer == null)
        .length;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Submit Exam?',
          ),
          content: Text(
            unanswered > 0
                ? 'You have $unanswered unanswered '
                  'question(s). Are you sure you '
                  'want to submit?'
                : 'Are you sure you want to submit '
                  'the exam?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Continue Exam',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                submitExam();
              },
              child: const Text(
                'Submit',
              ),
            ),
          ],
        );
      },
    );
  }
}

class _QuestionImage extends StatelessWidget {
  final String imagePath;

  const _QuestionImage({
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxHeight: 400,
          maxWidth: 700,
        ),
        child: Image.network(
          imagePath,
          fit: BoxFit.contain,
          errorBuilder: (
            context,
            error,
            stackTrace,
          ) {
            return const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Unable to load question figure.',
              ),
            );
          },
        ),
      ),
    );
  }
}

class ExamResultScreen extends StatelessWidget {
  final String username;
  final Exam exam;

  final int correct;
  final int wrong;
  final int unanswered;

  final double marks;

  const ExamResultScreen({
    super.key,
    required this.username,
    required this.exam,
    required this.correct,
    required this.wrong,
    required this.unanswered,
    required this.marks,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Exam Result',
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 700,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(
                  Icons.emoji_events,
                  size: 80,
                ),

                const SizedBox(height: 20),

                const Text(
                  'Exam Completed',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  exam.title,
                  style: const TextStyle(
                    fontSize: 20,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 30),

                // --------------------------------
                // AD AREA
                // --------------------------------
                const ResultAdPlaceholder(),

                const SizedBox(height: 25),

                Card(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        _ResultRow(
                          label: 'Student',
                          value: username,
                        ),
                        _ResultRow(
                          label: 'Correct',
                          value:
                              correct.toString(),
                        ),
                        _ResultRow(
                          label: 'Wrong',
                          value:
                              wrong.toString(),
                        ),
                        _ResultRow(
                          label: 'Unanswered',
                          value:
                              unanswered.toString(),
                        ),
                        const Divider(),
                        _ResultRow(
                          label: 'Final Marks',
                          value:
                              marks.toString(),
                          bold: true,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                SizedBox(
                  width: 220,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context)
                          .popUntil(
                        (route) => route.isFirst,
                      );
                    },
                    child: const Text(
                      'Finish',
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

// Temporary ad area.
// Later this exact widget will be replaced
// with the real Google AdSense integration.
class ResultAdPlaceholder extends StatelessWidget {
  const ResultAdPlaceholder({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(
        minHeight: 120,
      ),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey.shade400,
        ),
        borderRadius:
            BorderRadius.circular(10),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons.ads_click,
              size: 35,
            ),
            SizedBox(height: 8),
            Text(
              'Advertisement',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const _ResultRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 10,
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 18,
              fontWeight: bold
                  ? FontWeight.bold
                  : null,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: bold
                  ? FontWeight.bold
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}