import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class DiagramEditorScreen extends StatefulWidget {
  const DiagramEditorScreen({super.key});
  @override
  State<DiagramEditorScreen> createState() => _DiagramEditorScreenState();
}

class _DiagramEditorScreenState extends State<DiagramEditorScreen> {
  final GlobalKey _canvasKey = GlobalKey();
  final List<DiagramStroke> _strokes = [];
  DiagramStroke? _currentStroke;
  bool _eraseMode = false;
  bool _isExporting = false;
  double _strokeWidth = 4;
  void clearDiagram() {
    setState(() {
      _strokes.clear();
      _currentStroke = null;
    });
  }

  void undoStroke() {
    setState(() {
      if (_currentStroke != null) {
        _currentStroke = null;
      } else if (_strokes.isNotEmpty) {
        _strokes.removeLast();
      }
    });
  }

  void startStroke(Offset point) {
    setState(() {
      _currentStroke = DiagramStroke(
        points: [point],
        width: _strokeWidth,
        erase: _eraseMode,
      );
      _strokes.add(_currentStroke!);
    });
  }

  void updateStroke(Offset point) {
    if (_currentStroke == null) return;
    setState(() {
      _currentStroke!.points.add(point);
    });
  }

  void endStroke() {
    _currentStroke = null;
  }

  Future<void> finishDiagram() async {
    if (_strokes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Draw a diagram before selecting Use Diagram.'),
        ),
      );
      return;
    }
    setState(() {
      _isExporting = true;
    });
    try {
      await WidgetsBinding.instance.endOfFrame;
      final boundary =
          _canvasKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('Could not capture the diagram canvas.');
      }
      final ui.Image image = await boundary.toImage(pixelRatio: 2);
      try {
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData == null) {
          throw Exception('Could not export the diagram.');
        }
        final Uint8List bytes = byteData.buffer.asUint8List();
        final imageData = 'data:image/png;base64,${base64Encode(bytes)}';
        if (!mounted) return;
        Navigator.of(context).pop<String>(imageData);
      } finally {
        image.dispose();
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not save diagram: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Draw Diagram'),
        actions: [
          IconButton(
            onPressed: _isExporting ? null : undoStroke,
            tooltip: 'Undo',
            icon: const Icon(Icons.undo),
          ),
          IconButton(
            onPressed: _isExporting ? null : clearDiagram,
            tooltip: 'Clear',
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  const Text(
                    'Tool:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ChoiceChip(
                    label: const Text('Pen'),
                    avatar: const Icon(Icons.edit, size: 18),
                    selected: !_eraseMode,
                    onSelected: _isExporting
                        ? null
                        : (_) {
                            setState(() {
                              _eraseMode = false;
                            });
                          },
                  ),
                  ChoiceChip(
                    label: const Text('Eraser'),
                    avatar: const Icon(Icons.cleaning_services, size: 18),
                    selected: _eraseMode,
                    onSelected: _isExporting
                        ? null
                        : (_) {
                            setState(() {
                              _eraseMode = true;
                            });
                          },
                  ),
                  const Text('Size:'),
                  SizedBox(
                    width: 130,
                    child: Slider(
                      min: 1,
                      max: 15,
                      value: _strokeWidth,
                      onChanged: _isExporting
                          ? null
                          : (value) {
                              setState(() {
                                _strokeWidth = value;
                              });
                            },
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: RepaintBoundary(
                key: _canvasKey,
                child: Container(
                  color: Colors.white,
                  width: double.infinity,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanStart: (details) {
                      startStroke(details.localPosition);
                    },
                    onPanUpdate: (details) {
                      updateStroke(details.localPosition);
                    },
                    onPanEnd: (_) {
                      endStroke();
                    },
                    child: CustomPaint(
                      painter: DiagramPainter(strokes: _strokes),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _isExporting
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isExporting ? null : finishDiagram,
                    icon: _isExporting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: Text(_isExporting ? 'Saving...' : 'Use Diagram'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DiagramStroke {
  final List<Offset> points;
  final double width;
  final bool erase;
  DiagramStroke({
    required this.points,
    required this.width,
    required this.erase,
  });
}

class DiagramPainter extends CustomPainter {
  final List<DiagramStroke> strokes;
  DiagramPainter({required this.strokes});
  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      final paint = Paint()
        ..color = stroke.erase ? Colors.white : Colors.black
        ..strokeWidth = stroke.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      if (stroke.points.length == 1) {
        canvas.drawPoints(ui.PointMode.points, stroke.points, paint);
        continue;
      }
      final path = Path()
        ..moveTo(stroke.points.first.dx, stroke.points.first.dy);
      for (final point in stroke.points.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant DiagramPainter oldDelegate) {
    return true;
  }
}
