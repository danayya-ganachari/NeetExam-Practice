import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../data/exam_data.dart';
import '../diagram_editor_screen.dart';

class QuestionUploadScreen extends StatefulWidget {
  const QuestionUploadScreen({super.key});
  @override
  State<QuestionUploadScreen> createState() => _QuestionUploadScreenState();
}

class _QuestionUploadScreenState extends State<QuestionUploadScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final TextEditingController questionController = TextEditingController();
  final List<TextEditingController> optionControllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];
  String? selectedExamId;
  String? diagramData;
  int correctAnswer = 0;
  bool isLoading = true;
  bool isSaving = false;
  @override
  void initState() {
    super.initState();
    loadExams();
  }

  @override
  void dispose() {
    questionController.dispose();
    for (final controller in optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> loadExams() async {
    try {
      final snapshot = await firestore.collection('exams').get();
      final loadedExams = snapshot.docs.map((doc) {
        return Exam.fromMap(doc.id, doc.data());
      }).toList();
      if (!mounted) return;
      setState(() {
        ExamData.exams
          ..clear()
          ..addAll(loadedExams);
        if (loadedExams.isNotEmpty) {
          selectedExamId = loadedExams.any((exam) => exam.id == selectedExamId)
              ? selectedExamId
              : loadedExams.first.id;
        } else {
          selectedExamId = null;
        }
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
      showMessage('Could not load exams: $error');
    }
  }

  Exam? get selectedExam {
    final id = selectedExamId;
    if (id == null) return null;
    return ExamData.findExamById(id);
  }

Future<void> uploadImage() async { if (isSaving) return; try { final List<PlatformFile> files = await FilePicker.pickFiles( type: FileType.image, ); if (files.isEmpty) return; final file = files.first; final Uint8List bytes = await file.readAsBytes(); if (bytes.isEmpty) { showMessage('Could not read the selected image.'); return; } if (bytes.length > 300 * 1024) { showMessage( 'Image is too large. Please choose an image smaller than 300 KB.', ); return; } final extension = file.extension?.toLowerCase(); final mimeType = switch (extension) { 'jpg' || 'jpeg' => 'image/jpeg', 'webp' => 'image/webp', 'gif' => 'image/gif', _ => 'image/png', }; final encoded = base64Encode(bytes); setState(() { diagramData = 'data:$mimeType;base64,$encoded'; }); showMessage('Image selected successfully.'); } catch (error) { showMessage('Could not upload image: $error'); } }
  Future<void> drawDiagram() async {
    if (isSaving) return;
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (context) => const DiagramEditorScreen()),
    );
    if (!mounted || result == null) return;
    setState(() {
      diagramData = result;
    });
  }

  void removeImage() {
    setState(() {
      diagramData = null;
    });
  }

  Map<String, dynamic> createAdminExamData(
    Exam exam,
    List<Question> questions,
  ) {
    return {
      ...exam.toMap(),
      'questions': questions.map((question) {
        return question.toMap();
      }).toList(),
    };
  }

  Map<String, dynamic> createPublishedExamData(
  Exam exam,
  List<Question> questions,
) {
  return {
    'title': exam.title,
    'startDateTime':
        Timestamp.fromDate(exam.startDateTime),
    'durationMinutes': exam.durationMinutes,
    'positiveMarks': exam.positiveMarks,
    'negativeMarks': exam.negativeMarks,
    'questions': questions.map((question) {
      return {
        'question': question.question,
        'options': question.options,
        
        'correctAnswer': question.correctAnswer,
        'imagePath': question.imagePath,
      };
    }).toList(),
  };
}

  Future<void> addQuestion() async {
    if (isSaving) return;
    final exam = selectedExam;
    if (exam == null) {
      showMessage('Please create or select an exam first.');
      return;
    }
    final questionText = questionController.text.trim();
    final options = optionControllers
        .map((controller) => controller.text.trim())
        .toList();
    if (questionText.isEmpty) {
      showMessage('Please enter the question.');
      return;
    }
    if (options.any((option) => option.isEmpty)) {
      showMessage('Please fill in all four options.');
      return;
    }
    final newQuestion = Question(
      question: questionText,
      options: options,
      correctAnswer: correctAnswer,
      imagePath: diagramData,
    );
    final updatedQuestions = [...exam.questions, newQuestion];
    final adminData = createAdminExamData(exam, updatedQuestions);
    final publishedData = createPublishedExamData(exam, updatedQuestions);
    final adminBytes = utf8.encode(jsonEncode(adminData)).length;
    final publishedBytes = utf8.encode(jsonEncode(publishedData)).length;
    if (adminBytes > 850 * 1024 || publishedBytes > 850 * 1024) {
      showMessage(
        'The question paper is becoming too large. '
        'Use a smaller image or remove some images.',
      );
      return;
    }
    setState(() {
      isSaving = true;
    });
    try {
      final batch = firestore.batch();
      final adminRef = firestore.collection('exams').doc(exam.id);
      final publishedRef = firestore.collection('publishedExams').doc(exam.id);
      batch.set(adminRef, adminData);
      batch.set(publishedRef, publishedData);
      await batch.commit();
      exam.questions.add(newQuestion);
      if (!mounted) return;
      setState(() {
        questionController.clear();
        for (final controller in optionControllers) {
          controller.clear();
        }
        correctAnswer = 0;
        diagramData = null;
        isSaving = false;
      });
      showMessage('Question added and exam paper published.');
    } catch (error) {
      if (!mounted) return;
      setState(() {
        isSaving = false;
      });
      showMessage('Could not save question: $error');
    }
  }

  Widget buildDiagramPreview() {
    final data = diagramData;
    if (data == null || data.isEmpty) {
      return const SizedBox.shrink();
    }
    try {
      if (data.startsWith('data:image/')) {
        final commaIndex = data.indexOf(',');
        if (commaIndex < 0) {
          return const Text('Image preview unavailable.');
        }
        final encoded = data.substring(commaIndex + 1);
        final bytes = base64Decode(encoded);
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            bytes,
            height: 200,
            width: double.infinity,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Text('Could not display this image.');
            },
          ),
        );
      }
      if (data.startsWith('https://') || data.startsWith('http://')) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            data,
            height: 200,
            width: double.infinity,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Text('Could not load this image.');
            },
          ),
        );
      }
    } catch (_) {
      return const Text('Image preview unavailable.');
    }
    return const Text('An image is attached.');
  }

  Widget buildQuestionCard(Question question, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Question ${index + 1}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            const SizedBox(height: 10),
            Text(question.question),
            if (question.imagePath != null &&
                question.imagePath!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildSavedImage(question.imagePath!),
            ],
            const SizedBox(height: 10),
            ...List.generate(question.options.length, (i) {
              final isCorrect = i == question.correctAnswer;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      isCorrect ? Icons.check_circle : Icons.circle_outlined,
                      size: 19,
                      color: isCorrect ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${String.fromCharCode(65 + i)}. '
                        '${question.options[i]}',
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedImage(String data) {
    try {
      if (data.startsWith('data:image/')) {
        final commaIndex = data.indexOf(',');
        if (commaIndex < 0) {
          return const SizedBox.shrink();
        }
        return Image.memory(
          base64Decode(data.substring(commaIndex + 1)),
          height: 180,
          width: double.infinity,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Text('Image preview unavailable.');
          },
        );
      }
      if (data.startsWith('https://') || data.startsWith('http://')) {
        return Image.network(
          data,
          height: 180,
          width: double.infinity,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Text('Image preview unavailable.');
          },
        );
      }
    } catch (_) {
      return const Text('Image preview unavailable.');
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final exam = selectedExam;
    return Scaffold(
      appBar: AppBar(title: const Text('Question Paper Management')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    const Icon(Icons.quiz, size: 60),
                    const SizedBox(height: 12),
                    const Text(
                      'Upload Questions',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Add multiple-choice questions and '
                      'attach or draw diagrams.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    if (ExamData.exams.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            children: [
                              const Icon(Icons.info_outline, size: 35),
                              const SizedBox(height: 10),
                              const Text(
                                'No exams found. Create an exam '
                                'in Manage Exam first.',
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: loadExams,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Refresh Exams'),
                              ),
                            ],
                          ),
                        ),
                      )
                    else ...[
                      DropdownButtonFormField<String>(
                        initialValue: selectedExamId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Select Exam',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.assignment),
                        ),
                        items: ExamData.exams.map((exam) {
                          return DropdownMenuItem<String>(
                            value: exam.id,
                            child: Text(
                              exam.title,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: isSaving
                            ? null
                            : (value) {
                                setState(() {
                                  selectedExamId = value;
                                  diagramData = null;
                                });
                              },
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: questionController,
                        minLines: 2,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'Question',
                          hintText: 'Enter the question text here',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Options',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...List.generate(4, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: TextField(
                            controller: optionControllers[index],
                            decoration: InputDecoration(
                              labelText:
                                  'Option ${String.fromCharCode(65 + index)}',
                              hintText: 'Enter option text',
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 8),
                      const Text(
                        'Select the correct answer',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...List.generate(4, (index) {
                        return RadioListTile<int>(
                          value: index,
                          groupValue: correctAnswer,
                          title: Text(
                            'Option ${String.fromCharCode(65 + index)}',
                          ),
                          onChanged: isSaving
                              ? null
                              : (value) {
                                  if (value == null) return;
                                  setState(() {
                                    correctAnswer = value;
                                  });
                                },
                        );
                      }),
                      const SizedBox(height: 24),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Question Image / Diagram',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Upload an existing diagram or draw '
                                'one yourself.',
                              ),
                              const SizedBox(height: 16),
                              OutlinedButton.icon(
                                onPressed: isSaving ? null : uploadImage,
                                icon: const Icon(Icons.upload_file),
                                label: const Text('Upload Image'),
                              ),
                              const SizedBox(height: 10),
                              OutlinedButton.icon(
                                onPressed: isSaving ? null : drawDiagram,
                                icon: const Icon(Icons.draw),
                                label: const Text('Draw Diagram'),
                              ),
                              if (diagramData != null) ...[
                                const SizedBox(height: 16),
                                buildDiagramPreview(),
                                const SizedBox(height: 10),
                                TextButton.icon(
                                  onPressed: isSaving ? null : removeImage,
                                  icon: const Icon(Icons.delete_outline),
                                  label: const Text('Remove Image'),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: isSaving ? null : addQuestion,
                          icon: isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.save),
                          label: Text(
                            isSaving ? 'Saving Question...' : 'Save Question',
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      const Divider(),
                      const SizedBox(height: 12),
                      Text(
                        'Questions in ${exam?.title ?? "Selected Exam"}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (exam == null || exam.questions.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(18),
                            child: Text('No questions added to this exam yet.'),
                          ),
                        )
                      else
                        ...List.generate(
                          exam.questions.length,
                          (index) =>
                              buildQuestionCard(exam.questions[index], index),
                        ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
