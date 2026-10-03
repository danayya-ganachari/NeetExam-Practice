import 'package:flutter/material.dart';
import '../data/exam_data.dart';

class QuestionUploadScreen extends StatefulWidget {
  const QuestionUploadScreen({super.key});

  @override
  State<QuestionUploadScreen> createState() =>
      _QuestionUploadScreenState();
}

class _QuestionUploadScreenState
    extends State<QuestionUploadScreen> {
  final questionController = TextEditingController();

  final optionControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );

  String? selectedExamId;

  int correctAnswer = 0;

  @override
  void dispose() {
    questionController.dispose();

    for (final controller in optionControllers) {
      controller.dispose();
    }

    super.dispose();
  }

  Exam? get selectedExam {
    if (selectedExamId == null) {
      return null;
    }

    return ExamData.findExamById(selectedExamId!);
  }

  void addQuestion() {
    final exam = selectedExam;

    if (exam == null) {
      showMessage(
        'Please select an exam first.',
      );
      return;
    }

    final question =
        questionController.text.trim();

    final options = optionControllers
        .map(
          (controller) =>
              controller.text.trim(),
        )
        .toList();

    if (question.isEmpty) {
      showMessage(
        'Please enter the question.',
      );
      return;
    }

    if (options.any(
      (option) => option.isEmpty,
    )) {
      showMessage(
        'Please enter all four options.',
      );
      return;
    }

    setState(() {
      exam.questions.add(
        Question(
          question: question,
          options: options,
          correctAnswer: correctAnswer,
        ),
      );

      questionController.clear();

      for (final controller in optionControllers) {
        controller.clear();
      }

      correctAnswer = 0;
    });

    showMessage(
      'Question added to ${exam.title}.',
    );
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final exam = selectedExam;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Upload Questions',
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 800,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Add Question',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  'Select an exam and add questions to it.',
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 30),

                DropdownButtonFormField<String>(
                  initialValue: selectedExamId,
                  decoration: const InputDecoration(
                    labelText: 'Select Exam',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(
                      Icons.assignment,
                    ),
                  ),
                  items: ExamData.exams.map(
                    (exam) {
                      return DropdownMenuItem<String>(
                        value: exam.id,
                        child: Text(
                          exam.title,
                        ),
                      );
                    },
                  ).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedExamId = value;
                    });
                  },
                ),

                const SizedBox(height: 25),

                if (ExamData.exams.isEmpty)
                  Card(
                    child: Padding(
                      padding:
                          const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.warning_amber,
                            size: 50,
                          ),

                          const SizedBox(height: 10),

                          const Text(
                            'No exams available.',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 8),

                          const Text(
                            'Create an exam first from '
                            'Manage Exams.',
                            textAlign:
                                TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                else if (exam == null)
                  const Card(
                    child: Padding(
                      padding:
                          EdgeInsets.all(20),
                      child: Text(
                        'Select an exam above to start '
                        'adding questions.',
                        textAlign:
                            TextAlign.center,
                      ),
                    ),
                  )
                else ...[
                  Card(
                    child: Padding(
                      padding:
                          const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Selected Exam',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            exam.title,
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            'Questions already added: '
                            '${exam.questions.length}',
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  TextField(
                    controller:
                        questionController,
                    maxLines: 4,
                    decoration:
                        const InputDecoration(
                      labelText: 'Question',
                      hintText:
                          'Enter the question here',
                      border:
                          OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  for (int i = 0; i < 4; i++) ...[
                    TextField(
                      controller:
                          optionControllers[i],
                      decoration:
                          InputDecoration(
                        labelText:
                            'Option ${i + 1}',
                        hintText:
                            'Enter option ${i + 1}',
                        border:
                            const OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),
                  ],

                  const SizedBox(height: 10),

                  const Text(
                    'Select Correct Answer',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 5),

                  for (int i = 0; i < 4; i++)
                    RadioListTile<int>(
                      value: i,
                      groupValue:
                          correctAnswer,
                      title: Text(
                        'Option ${i + 1}',
                      ),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }

                        setState(() {
                          correctAnswer = value;
                        });
                      },
                    ),

                  const SizedBox(height: 15),

                  Card(
                    child: Padding(
                      padding:
                          const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.image,
                            size: 45,
                          ),

                          const SizedBox(height: 10),

                          const Text(
                            'Figure / Diagram',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 8),

                          const Text(
                            'Image upload and drawing '
                            'tools will be added next.',
                            textAlign:
                                TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  SizedBox(
                    height: 55,
                    child:
                        ElevatedButton.icon(
                      onPressed: addQuestion,
                      icon: const Icon(
                        Icons.add,
                      ),
                      label: const Text(
                        'Add Question',
                        style: TextStyle(
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  Text(
                    'Total Questions in '
                    '${exam.title}: '
                    '${exam.questions.length}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}