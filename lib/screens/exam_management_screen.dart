import 'package:flutter/material.dart';

import '../data/exam_data.dart';

class ExamManagementScreen extends StatefulWidget {
  const ExamManagementScreen({super.key});

  @override
  State<ExamManagementScreen> createState() =>
      _ExamManagementScreenState();
}

class _ExamManagementScreenState
    extends State<ExamManagementScreen> {
  final titleController = TextEditingController();
  final durationController = TextEditingController();
  final positiveController = TextEditingController();
  final negativeController = TextEditingController();

  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  Exam? editingExam;

  @override
  void dispose() {
    titleController.dispose();
    durationController.dispose();
    positiveController.dispose();
    negativeController.dispose();

    super.dispose();
  }

  Future<void> selectDate() async {
    final now = DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );

    if (pickedDate == null) {
      return;
    }

    setState(() {
      selectedDate = pickedDate;
    });
  }

  Future<void> selectTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
    );

    if (pickedTime == null) {
      return;
    }

    setState(() {
      selectedTime = pickedTime;
    });
  }

  void createExam() {
    final title = titleController.text.trim();

    final duration =
        int.tryParse(durationController.text.trim());

    final positive =
        double.tryParse(positiveController.text.trim());

    final negative =
        double.tryParse(negativeController.text.trim());

    if (title.isEmpty) {
      showMessage(
        'Please enter an exam title.',
      );
      return;
    }

    if (duration == null || duration <= 0) {
      showMessage(
        'Please enter a valid exam duration.',
      );
      return;
    }

    if (positive == null || positive < 0) {
      showMessage(
        'Please enter valid positive marks.',
      );
      return;
    }

    if (negative == null || negative < 0) {
      showMessage(
        'Please enter valid negative marks.',
      );
      return;
    }

    if (selectedDate == null ||
        selectedTime == null) {
      showMessage(
        'Please select the exam start date and time.',
      );
      return;
    }

    final startDateTime = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );

    if (startDateTime.isBefore(DateTime.now())) {
      showMessage(
        'Exam start date and time must be in the future.',
      );
      return;
    }

    final exam = Exam(
      id: DateTime.now()
          .millisecondsSinceEpoch
          .toString(),
      title: title,
      startDateTime: startDateTime,
      durationMinutes: duration,
      positiveMarks: positive,
      negativeMarks: negative,
      questions: [],
    );

    setState(() {
      ExamData.exams.add(exam);
    });

    clearForm();

    showMessage(
      'Exam created successfully.',
    );
  }

  void startEditingExam(Exam exam) {
    setState(() {
      editingExam = exam;

      titleController.text = exam.title;

      durationController.text =
          exam.durationMinutes.toString();

      positiveController.text =
          exam.positiveMarks.toString();

      negativeController.text =
          exam.negativeMarks.toString();

      selectedDate = exam.startDateTime;

      selectedTime =
          TimeOfDay.fromDateTime(
        exam.startDateTime,
      );
    });

    Scrollable.ensureVisible(
      context,
      duration: const Duration(
        milliseconds: 300,
      ),
    );
  }

  void updateExam() {
    final exam = editingExam;

    if (exam == null) {
      return;
    }

    final title = titleController.text.trim();

    final duration =
        int.tryParse(durationController.text.trim());

    final positive =
        double.tryParse(positiveController.text.trim());

    final negative =
        double.tryParse(negativeController.text.trim());

    if (title.isEmpty) {
      showMessage(
        'Please enter an exam title.',
      );
      return;
    }

    if (duration == null || duration <= 0) {
      showMessage(
        'Please enter a valid exam duration.',
      );
      return;
    }

    if (positive == null || positive < 0) {
      showMessage(
        'Please enter valid positive marks.',
      );
      return;
    }

    if (negative == null || negative < 0) {
      showMessage(
        'Please enter valid negative marks.',
      );
      return;
    }

    if (selectedDate == null ||
        selectedTime == null) {
      showMessage(
        'Please select the exam start date and time.',
      );
      return;
    }

    final startDateTime = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );

    if (startDateTime.isBefore(DateTime.now())) {
      showMessage(
        'Exam start date and time must be in the future.',
      );
      return;
    }

    setState(() {
      exam.title = title;
      exam.durationMinutes = duration;
      exam.positiveMarks = positive;
      exam.negativeMarks = negative;
      exam.startDateTime = startDateTime;

      editingExam = null;
    });

    clearForm();

    showMessage(
      'Exam updated successfully.',
    );
  }

  void cancelEditing() {
    setState(() {
      editingExam = null;
    });

    clearForm();
  }

  void clearForm() {
    titleController.clear();
    durationController.clear();
    positiveController.clear();
    negativeController.clear();

    setState(() {
      selectedDate = null;
      selectedTime = null;
    });
  }

  void deleteExam(Exam exam) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Delete Exam?',
          ),
          content: Text(
            'Are you sure you want to delete '
            '"${exam.title}"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Cancel',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  ExamData.exams.remove(exam);

                  if (editingExam == exam) {
                    editingExam = null;
                    clearForm();
                  }
                });

                Navigator.of(context).pop();

                showMessage(
                  'Exam deleted successfully.',
                );
              },
              child: const Text(
                'Delete',
              ),
            ),
          ],
        );
      },
    );
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0
        ? 12
        : time.hourOfPeriod;

    final minute =
        time.minute.toString().padLeft(2, '0');

    final period =
        time.period == DayPeriod.am
            ? 'AM'
            : 'PM';

    return '$hour:$minute $period';
  }

  String formatDateTime(DateTime dateTime) {
    return '${formatDate(dateTime)} at '
        '${formatTime(
      TimeOfDay.fromDateTime(dateTime),
    )}';
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = editingExam != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Manage Exams',
        ),
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
                Icon(
                  isEditing
                      ? Icons.edit
                      : Icons.edit_calendar,
                  size: 70,
                ),

                const SizedBox(height: 15),

                Text(
                  isEditing
                      ? 'Edit Exam'
                      : 'Create New Exam',
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight:
                        FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 30),

                TextField(
                  controller: titleController,
                  decoration:
                      const InputDecoration(
                    labelText: 'Exam Title',
                    hintText:
                        'Example: NEET Biology Mock Test 1',
                    border:
                        OutlineInputBorder(),
                    prefixIcon: Icon(
                      Icons.assignment,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                TextField(
                  controller:
                      durationController,
                  keyboardType:
                      TextInputType.number,
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Exam Duration',
                    hintText:
                        'Enter duration in minutes',
                    suffixText: 'minutes',
                    border:
                        OutlineInputBorder(),
                    prefixIcon: Icon(
                      Icons.timer,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                TextField(
                  controller:
                      positiveController,
                  keyboardType:
                      const TextInputType
                          .numberWithOptions(
                    decimal: true,
                  ),
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Marks for Correct Answer',
                    hintText: 'Example: 4',
                    border:
                        OutlineInputBorder(),
                    prefixIcon: Icon(
                      Icons.add_circle,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                TextField(
                  controller:
                      negativeController,
                  keyboardType:
                      const TextInputType
                          .numberWithOptions(
                    decimal: true,
                  ),
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Negative Marks',
                    hintText: 'Example: 1',
                    border:
                        OutlineInputBorder(),
                    prefixIcon: Icon(
                      Icons.remove_circle,
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                const Text(
                  'Exam Schedule',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 15),

                OutlinedButton.icon(
                  onPressed: selectDate,
                  icon: const Icon(
                    Icons.calendar_month,
                  ),
                  label: Text(
                    selectedDate == null
                        ? 'Select Exam Date'
                        : 'Date: '
                          '${formatDate(
                            selectedDate!,
                          )}',
                  ),
                  style:
                      OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.all(
                      18,
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                OutlinedButton.icon(
                  onPressed: selectTime,
                  icon: const Icon(
                    Icons.access_time,
                  ),
                  label: Text(
                    selectedTime == null
                        ? 'Select Exam Start Time'
                        : 'Time: '
                          '${formatTime(
                            selectedTime!,
                          )}',
                  ),
                  style:
                      OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.all(
                      18,
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 55,
                        child:
                            ElevatedButton.icon(
                          onPressed: isEditing
                              ? updateExam
                              : createExam,
                          icon: Icon(
                            isEditing
                                ? Icons.save
                                : Icons.add,
                          ),
                          label: Text(
                            isEditing
                                ? 'Update Exam'
                                : 'Create Exam',
                            style:
                                const TextStyle(
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                    ),

                    if (isEditing) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 55,
                          child:
                              OutlinedButton(
                            onPressed:
                                cancelEditing,
                            child:
                                const Text(
                              'Cancel',
                              style:
                                  TextStyle(
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 45),

                const Divider(),

                const SizedBox(height: 20),

                const Text(
                  'Created Exams',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                if (ExamData.exams.isEmpty)
                  const Card(
                    child: Padding(
                      padding:
                          EdgeInsets.all(25),
                      child: Text(
                        'No exams created yet.',
                        textAlign:
                            TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                        ),
                      ),
                    ),
                  )
                else
                  ...ExamData.exams.map(
                    (exam) {
                      return Card(
                        margin:
                            const EdgeInsets.only(
                          bottom: 15,
                        ),
                        child: Padding(
                          padding:
                              const EdgeInsets.all(
                            20,
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              Text(
                                exam.title,
                                style:
                                    const TextStyle(
                                  fontSize: 21,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),

                              const SizedBox(
                                height: 12,
                              ),

                              Text(
                                'Start: '
                                '${formatDateTime(
                                  exam.startDateTime,
                                )}',
                              ),

                              const SizedBox(
                                height: 5,
                              ),

                              Text(
                                'Duration: '
                                '${exam.durationMinutes} '
                                'minutes',
                              ),

                              const SizedBox(
                                height: 5,
                              ),

                              Text(
                                'Correct: '
                                '+${exam.positiveMarks} '
                                'marks',
                              ),

                              const SizedBox(
                                height: 5,
                              ),

                              Text(
                                'Wrong: '
                                '-${exam.negativeMarks} '
                                'marks',
                              ),

                              const SizedBox(
                                height: 5,
                              ),

                              Text(
                                'Questions: '
                                '${exam.questions.length}',
                              ),

                              const SizedBox(
                                height: 15,
                              ),

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment
                                        .end,
                                children: [
                                  OutlinedButton
                                      .icon(
                                    onPressed: () {
                                      startEditingExam(
                                        exam,
                                      );
                                    },
                                    icon:
                                        const Icon(
                                      Icons.edit,
                                    ),
                                    label:
                                        const Text(
                                      'Edit',
                                    ),
                                  ),

                                  const SizedBox(
                                    width: 10,
                                  ),

                                  OutlinedButton
                                      .icon(
                                    onPressed: () {
                                      deleteExam(
                                        exam,
                                      );
                                    },
                                    icon:
                                        const Icon(
                                      Icons.delete,
                                    ),
                                    label:
                                        const Text(
                                      'Delete',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}