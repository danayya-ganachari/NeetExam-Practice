import 'package:flutter/material.dart';

class DiagramEditorScreen extends StatefulWidget {
  const DiagramEditorScreen({
    super.key,
  });

  @override
  State<DiagramEditorScreen> createState() =>
      _DiagramEditorScreenState();
}

class _DiagramEditorScreenState
    extends State<DiagramEditorScreen> {
  final List<Offset?> points = [];

  bool eraseMode = false;

  double strokeWidth = 4;

  void clearDiagram() {
    setState(() {
      points.clear();
    });
  }

  void finishDiagram() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Draw Diagram',
        ),
        actions: [
          IconButton(
            onPressed: clearDiagram,
            tooltip: 'Clear',
            icon: const Icon(
              Icons.delete_outline,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Text(
                  'Drawing Tool',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(width: 20),

                IconButton(
                  onPressed: () {
                    setState(() {
                      eraseMode = false;
                    });
                  },
                  tooltip: 'Pen',
                  icon: Icon(
                    Icons.edit,
                    color: eraseMode
                        ? Colors.grey
                        : Colors.blue,
                  ),
                ),

                IconButton(
                  onPressed: () {
                    setState(() {
                      eraseMode = true;
                    });
                  },
                  tooltip: 'Eraser',
                  icon: Icon(
                    Icons.cleaning_services,
                    color: eraseMode
                        ? Colors.red
                        : Colors.grey,
                  ),
                ),

                const SizedBox(width: 20),

                const Text(
                  'Size:',
                ),

                Expanded(
                  child: Slider(
                    min: 1,
                    max: 15,
                    value: strokeWidth,
                    onChanged: (value) {
                      setState(() {
                        strokeWidth = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          const Divider(
            height: 1,
          ),

          Expanded(
            child: Container(
              color: Colors.white,
              child: GestureDetector(
                onPanStart: (details) {
                  setState(() {
                    points.add(
                      details.localPosition,
                    );
                  });
                },
                onPanUpdate: (details) {
                  setState(() {
                    points.add(
                      details.localPosition,
                    );
                  });
                },
                onPanEnd: (details) {
                  setState(() {
                    points.add(null);
                  });
                },
                child: CustomPaint(
                  painter: DiagramPainter(
                    points: points,
                    strokeWidth: strokeWidth,
                    eraseMode: eraseMode,
                  ),
                  size: Size.infinite,
                ),
              ),
            ),
          ),

          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'Cancel',
                  ),
                ),

                const SizedBox(width: 15),

                ElevatedButton.icon(
                  onPressed: finishDiagram,
                  icon: const Icon(
                    Icons.check,
                  ),
                  label: const Text(
                    'Use Diagram',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DiagramPainter extends CustomPainter {
  final List<Offset?> points;
  final double strokeWidth;
  final bool eraseMode;

  DiagramPainter({
    required this.points,
    required this.strokeWidth,
    required this.eraseMode,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final paint = Paint()
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (eraseMode) {
      paint.color = Colors.white;
    } else {
      paint.color = Colors.black;
    }

    for (int i = 0; i < points.length - 1; i++) {
      final currentPoint = points[i];
      final nextPoint = points[i + 1];

      if (currentPoint == null ||
          nextPoint == null) {
        continue;
      }

      canvas.drawLine(
        currentPoint,
        nextPoint,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant DiagramPainter oldDelegate,
  ) {
    return oldDelegate.points != points ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.eraseMode != eraseMode;
  }
}