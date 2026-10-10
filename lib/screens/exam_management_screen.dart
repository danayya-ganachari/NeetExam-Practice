import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../data/exam_data.dart';

class ExamManagementScreen extends StatefulWidget {
  const ExamManagementScreen({super.key});
  @override
  State<ExamManagementScreen> createState() => _ExamManagementScreenState();
}

class _ExamManagementScreenState extends State<ExamManagementScreen> {
  final titleController = TextEditingController();
  final durationController = TextEditingController();
  final positiveController = TextEditingController();
  final negativeController = TextEditingController();
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  Exam? editingExam;
  bool isLoading = true;
  bool isSaving = false;
  CollectionReference<Map<String, dynamic>> get examsCollection =>
      FirebaseFirestore.instance.collection('exams');
  CollectionReference<Map<String, dynamic>> get publishedCollection =>
      FirebaseFirestore.instance.collection('publishedExams');
  @override
  void initState() {
    super.initState();
    loadExams();
  }

  @override
  void dispose() {
    titleController.dispose();
    durationController.dispose();
    positiveController.dispose();
    negativeController.dispose();
    super.dispose();
  }

  Map<String, dynamic> createPublishedExamData(Exam exam) {
  return {
    'title': exam.title,
    'startDateTime':
        Timestamp.fromDate(exam.startDateTime),
    'durationMinutes': exam.durationMinutes,
    'positiveMarks': exam.positiveMarks,
    'negativeMarks': exam.negativeMarks,
    'questions': exam.questions.map((question) {
      return {
        'question': question.question,
        'options': question.options,
        'correctAnswer': question.correctAnswer,
        'imagePath': question.imagePath,
      };
    }).toList(),
  };
}

  Future<void> loadExams() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }
    try {
      final snapshot = await examsCollection.get();
      final loadedExams = snapshot.docs.map((document) {
        return Exam.fromMap(document.id, document.data());
      }).toList();
      if (!mounted) return;
      setState(() {
        ExamData.exams
          ..clear()
          ..addAll(loadedExams);
        isLoading = false;
      });
    } on FirebaseException catch (error) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
      showMessage('Could not load exams: ${error.message ?? error.code}');
    } catch (error) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
      showMessage('Could not load exams: $error');
    }
  }

  Future<void> selectDate() async {
    final now = DateTime.now();
    final initialDate = selectedDate != null && selectedDate!.isAfter(now)
        ? selectedDate!
        : now;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );
    if (pickedDate == null || !mounted) return;
    setState(() {
      selectedDate = pickedDate;
    });
  }

  Future<void> selectTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
    );
    if (pickedTime == null || !mounted) return;
    setState(() {
      selectedTime = pickedTime;
    });
  }

  DateTime? getSelectedDateTime() {
    if (selectedDate == null || selectedTime == null) {
      return null;
    }
    return DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );
  }

  String? validateForm() {
    if (titleController.text.trim().isEmpty) {
      return 'Please enter an exam title.';
    }
    final duration = int.tryParse(durationController.text.trim());
    if (duration == null || duration <= 0) {
      return 'Please enter a valid exam duration.';
    }
    final positive = double.tryParse(positiveController.text.trim());
    if (positive == null || !positive.isFinite || positive < 0) {
      return 'Please enter valid positive marks.';
    }
    final negative = double.tryParse(negativeController.text.trim());
    if (negative == null || !negative.isFinite || negative < 0) {
      return 'Please enter valid negative marks.';
    }
    final startDateTime = getSelectedDateTime();
    if (startDateTime == null) {
      return 'Please select the exam start date and time.';
    }
    if (!startDateTime.isAfter(DateTime.now())) {
      return 'Exam start date and time must be in the future.';
    }
    return null;
  }

  Exam buildExam(String id, List<Question> questions) {
    return Exam(
      id: id,
      title: titleController.text.trim(),
      startDateTime: getSelectedDateTime()!,
      durationMinutes: int.parse(durationController.text.trim()),
      positiveMarks: double.parse(positiveController.text.trim()),
      negativeMarks: double.parse(negativeController.text.trim()),
      questions: questions,
    );
  }

  Future<void> createExam() async {
    final validationError = validateForm();
    if (validationError != null) {
      showMessage(validationError);
      return;
    }
    final document = examsCollection.doc();
    final exam = buildExam(document.id, []);
    setState(() {
      isSaving = true;
    });
    try {
      final batch = FirebaseFirestore.instance.batch();
      final updatedExam = buildExam(exam.id, exam.questions);
      batch.set(document, exam.toMap());
      batch.set(
        publishedCollection.doc(exam.id),
        createPublishedExamData(exam),
      );
      debugPrint(
  'PUBLISH DEBUG: ${updatedExam.questions.map(
    (q) => {
      'question': q.question,
      'correctAnswer': q.correctAnswer,
    },
  ).toList()}',
);
      await batch.commit();
      if (!mounted) return;
      setState(() {
        ExamData.exams.add(exam);
      });
      clearForm();
      showMessage('Exam created and published successfully.');
    } on FirebaseException catch (error) {
      if (mounted) {
        showMessage('Could not create exam: ${error.message ?? error.code}');
      }
    } catch (error) {
      if (mounted) {
        showMessage('Could not create exam: $error');
      }
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  void startEditingExam(Exam exam) {
    setState(() {
      editingExam = exam;
      titleController.text = exam.title;
      durationController.text = exam.durationMinutes.toString();
      positiveController.text = exam.positiveMarks.toString();
      negativeController.text = exam.negativeMarks.toString();
      selectedDate = exam.startDateTime;
      selectedTime = TimeOfDay.fromDateTime(exam.startDateTime);
    });
  }

  Future<void> updateExam() async {
    final exam = editingExam;
    if (exam == null) return;
    final validationError = validateForm();
    if (validationError != null) {
      showMessage(validationError);
      return;
    }
    
    final updatedExam = buildExam(exam.id, exam.questions);
    setState(() {
      isSaving = true;
    });
    try {
      final batch = FirebaseFirestore.instance.batch();
      batch.set(examsCollection.doc(updatedExam.id), updatedExam.toMap());
      batch.set(
        publishedCollection.doc(updatedExam.id),
        createPublishedExamData(updatedExam),
      );
      await batch.commit();
      if (!mounted) return;
      final index = ExamData.exams.indexWhere(
        (item) => item.id == updatedExam.id,
      );
      setState(() {
        if (index != -1) {
          ExamData.exams[index] = updatedExam;
        }
        editingExam = null;
      });
      clearForm();
      showMessage('Exam updated and published successfully.');
    } on FirebaseException catch (error) {
      if (mounted) {
        showMessage('Could not update exam: ${error.message ?? error.code}');
      }
    } catch (error) {
      if (mounted) {
        showMessage('Could not update exam: $error');
      }
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
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

  Future<void> deleteExam(Exam exam) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Exam?'),
          content: Text('Are you sure you want to delete "${exam.title}"?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      isSaving = true;
    });
    try {
      final batch = FirebaseFirestore.instance.batch();
      batch.delete(examsCollection.doc(exam.id));
      batch.delete(publishedCollection.doc(exam.id));
      await batch.commit();
      if (!mounted) return;
      setState(() {
        ExamData.exams.removeWhere((item) => item.id == exam.id);
        if (editingExam?.id == exam.id) {
          editingExam = null;
        }
      });
      if (editingExam == null) {
        clearForm();
      }
      showMessage('Exam deleted successfully.');
    } on FirebaseException catch (error) {
      if (mounted) {
        showMessage('Could not delete exam: ${error.message ?? error.code}');
      }
    } catch (error) {
      if (mounted) {
        showMessage('Could not delete exam: $error');
      }
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  void showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  String formatDateTime(DateTime dateTime) {
    return '${formatDate(dateTime)} at '
        '${formatTime(TimeOfDay.fromDateTime(dateTime))}';
  }

  Widget buildExamCard(Exam exam) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              exam.title,
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text('Start: ${formatDateTime(exam.startDateTime)}'),
            const SizedBox(height: 5),
            Text('Duration: ${exam.durationMinutes} minutes'),
            const SizedBox(height: 5),
            Text('Correct: +${exam.positiveMarks} marks'),
            const SizedBox(height: 5),
            Text('Wrong: -${exam.negativeMarks} marks'),
            const SizedBox(height: 5),
            Text('Questions: ${exam.questions.length}'),
            const SizedBox(height: 15),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 10,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: isSaving ? null : () => startEditingExam(exam),
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                ),
                OutlinedButton.icon(
                  onPressed: isSaving ? null : () => deleteExam(exam),
                  icon: const Icon(Icons.delete),
                  label: const Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = editingExam != null;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Exams'),
        actions: [
          IconButton(
            tooltip: 'Reload exams',
            onPressed: isLoading || isSaving ? null : loadExams,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        isEditing ? Icons.edit : Icons.edit_calendar,
                        size: 70,
                      ),
                      const SizedBox(height: 15),
                      Text(
                        isEditing ? 'Edit Exam' : 'Create New Exam',
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30),
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Exam Title',
                          hintText: 'Example: NEET Biology Mock Test 1',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.assignment),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: durationController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Exam Duration',
                          hintText: 'Enter duration in minutes',
                          suffixText: 'minutes',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.timer),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: positiveController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Marks for Correct Answer',
                          hintText: 'Example: 4',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.add_circle),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: negativeController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Negative Marks',
                          hintText: 'Example: 1',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.remove_circle),
                        ),
                      ),
                      const SizedBox(height: 30),
                      const Text(
                        'Exam Schedule',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 15),
                      OutlinedButton.icon(
                        onPressed: isSaving ? null : selectDate,
                        icon: const Icon(Icons.calendar_month),
                        label: Text(
                          selectedDate == null
                              ? 'Select Exam Date'
                              : 'Date: ${formatDate(selectedDate!)}',
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(18),
                        ),
                      ),
                      const SizedBox(height: 15),
                      OutlinedButton.icon(
                        onPressed: isSaving ? null : selectTime,
                        icon: const Icon(Icons.access_time),
                        label: Text(
                          selectedTime == null
                              ? 'Select Exam Start Time'
                              : 'Time: ${formatTime(selectedTime!)}',
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(18),
                        ),
                      ),
                      const SizedBox(height: 25),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 55,
                              child: ElevatedButton.icon(
                                onPressed: isSaving
                                    ? null
                                    : isEditing
                                    ? updateExam
                                    : createExam,
                                icon: isSaving
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Icon(isEditing ? Icons.save : Icons.add),
                                label: Text(
                                  isSaving
                                      ? 'Saving...'
                                      : isEditing
                                      ? 'Update Exam'
                                      : 'Create Exam',
                                  style: const TextStyle(fontSize: 18),
                                ),
                              ),
                            ),
                          ),
                          if (isEditing) ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: SizedBox(
                                height: 55,
                                child: OutlinedButton(
                                  onPressed: isSaving ? null : cancelEditing,
                                  child: const Text(
                                    'Cancel',
                                    style: TextStyle(fontSize: 18),
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
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (ExamData.exams.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(25),
                            child: Text(
                              'No exams created yet.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 18),
                            ),
                          ),
                        )
                      else
                        ...ExamData.exams.map(buildExamCard),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
