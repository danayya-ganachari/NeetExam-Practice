class Question {
  final String question;
  final List<String> options;
  final int correctAnswer;

  // Optional image or diagram for the question.
  final String? imagePath;

  Question({
    required this.question,
    required this.options,
    required this.correctAnswer,
    this.imagePath,
  });
}

class Exam {
  final String id;
  String title;
  DateTime startDateTime;
  int durationMinutes;
  double positiveMarks;
  double negativeMarks;

  final List<Question> questions;

  Exam({
    required this.id,
    required this.title,
    required this.startDateTime,
    required this.durationMinutes,
    required this.positiveMarks,
    required this.negativeMarks,
    required this.questions,
  });
}

class StudentResult {
  final String username;
  final String examId;
  final String examTitle;

  final int correct;
  final int wrong;
  final int unanswered;

  final double marks;

  StudentResult({
    required this.username,
    required this.examId,
    required this.examTitle,
    required this.correct,
    required this.wrong,
    required this.unanswered,
    required this.marks,
  });
}

class ExamData {
  // All exams created by the admin.
  static final List<Exam> exams = [];

  // All student results.
  static final List<StudentResult> results = [];

  // Find an exam using its ID.
  static Exam? findExamById(String id) {
    for (final exam in exams) {
      if (exam.id == id) {
        return exam;
      }
    }

    return null;
  }
}