import 'package:cloud_firestore/cloud_firestore.dart';

class Question {
  final String question;
  final List<String> options;
  final int correctAnswer;
  final String? imagePath;
  Question({
    required this.question,
    required this.options,
    required this.correctAnswer,
    this.imagePath,
  });
  Map<String, dynamic> toMap() {
    return {
      'question': question,
      'options': options,
      'correctAnswer': correctAnswer,
      'imagePath': imagePath,
    };
  }

  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      question: map['question'] as String? ?? '',
      options: List<String>.from(map['options'] ?? const <String>[]),
      correctAnswer: (map['correctAnswer'] as num?)?.toInt() ?? 0,
      imagePath: map['imagePath'] as String?,
    );
  }
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
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'startDateTime': Timestamp.fromDate(startDateTime),
      'durationMinutes': durationMinutes,
      'positiveMarks': positiveMarks,
      'negativeMarks': negativeMarks,
      'questions': questions.map((q) => q.toMap()).toList(),
    };
  }

  factory Exam.fromMap(String id, Map<String, dynamic> map) {
    final rawDate = map['startDateTime'];
    DateTime startDate;
    if (rawDate is Timestamp) {
      startDate = rawDate.toDate();
    } else if (rawDate is DateTime) {
      startDate = rawDate;
    } else if (rawDate is String) {
      startDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else {
      startDate = DateTime.now();
    }
    final rawQuestions = map['questions'] as List? ?? [];
    return Exam(
      id: id,
      title: map['title'] as String? ?? '',
      startDateTime: startDate,
      durationMinutes: (map['durationMinutes'] as num?)?.toInt() ?? 60,
      positiveMarks: (map['positiveMarks'] as num?)?.toDouble() ?? 4,
      negativeMarks: (map['negativeMarks'] as num?)?.toDouble() ?? 1,
      questions: rawQuestions.map((item) {
        return Question.fromMap(Map<String, dynamic>.from(item as Map));
      }).toList(),
    );
  }
}

class StudentResult {
  final String username;
  final String examId;
  final String examTitle;
  final int correct;
  final int wrong;
  final int unanswered;
  final double marks;
  final String studentId;
  StudentResult({
    required this.username,
    required this.examId,
    required this.examTitle,
    required this.correct,
    required this.wrong,
    required this.unanswered,
    required this.marks,
    this.studentId = '',
  });
  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'username': username,
      'examId': examId,
      'examTitle': examTitle,
      'correct': correct,
      'wrong': wrong,
      'unanswered': unanswered,
      'marks': marks,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory StudentResult.fromMap(Map<String, dynamic> map) {
    return StudentResult(
      studentId: map['studentId'] as String? ?? '',
      username: map['username'] as String? ?? '',
      examId: map['examId'] as String? ?? '',
      examTitle: map['examTitle'] as String? ?? '',
      correct: (map['correct'] as num?)?.toInt() ?? 0,
      wrong: (map['wrong'] as num?)?.toInt() ?? 0,
      unanswered: (map['unanswered'] as num?)?.toInt() ?? 0,
      marks: (map['marks'] as num?)?.toDouble() ?? 0,
    );
  }
}

class ExamData {
  static final List<Exam> exams = [];
  static final List<StudentResult> results = [];
  static Exam? findExamById(String id) {
    for (final exam in exams) {
      if (exam.id == id) {
        return exam;
      }
    }
    return null;
  }
}
