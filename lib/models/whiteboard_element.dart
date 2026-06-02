import 'package:flutter/material.dart';

enum WhiteboardTool { pen, eraser, text, line, rectangle, ellipse, triangle }

enum WhiteboardElementKind { stroke, text, line, rectangle, ellipse, triangle }

class WhiteboardElement {
  const WhiteboardElement._({
    required this.id,
    required this.kind,
    required this.color,
    required this.strokeWidth,
    this.points = const [],
    this.bounds = Rect.zero,
    this.text = '',
  });

  factory WhiteboardElement.stroke({
    required String id,
    required List<Offset> points,
    required Color color,
    required double strokeWidth,
  }) {
    return WhiteboardElement._(
      id: id,
      kind: WhiteboardElementKind.stroke,
      points: points,
      color: color,
      strokeWidth: strokeWidth,
    );
  }

  factory WhiteboardElement.text({
    required String id,
    required Offset position,
    required String text,
    required Color color,
  }) {
    return WhiteboardElement._(
      id: id,
      kind: WhiteboardElementKind.text,
      bounds: Rect.fromLTWH(position.dx, position.dy, 0, 0),
      text: text,
      color: color,
      strokeWidth: 1,
    );
  }

  factory WhiteboardElement.shape({
    required String id,
    required WhiteboardElementKind kind,
    required Rect bounds,
    required Color color,
    required double strokeWidth,
  }) {
    return WhiteboardElement._(
      id: id,
      kind: kind,
      bounds: bounds,
      color: color,
      strokeWidth: strokeWidth,
    );
  }

  final String id;
  final WhiteboardElementKind kind;
  final List<Offset> points;
  final Rect bounds;
  final String text;
  final Color color;
  final double strokeWidth;

  bool hitTest(Offset point, {double tolerance = 24}) {
    switch (kind) {
      case WhiteboardElementKind.stroke:
        return _strokeHitTest(point, tolerance);
      case WhiteboardElementKind.text:
        return _textBounds().inflate(tolerance).contains(point);
      case WhiteboardElementKind.line:
        return _lineHitTest(point, tolerance);
      case WhiteboardElementKind.rectangle:
      case WhiteboardElementKind.ellipse:
      case WhiteboardElementKind.triangle:
        return bounds.inflate(tolerance).contains(point);
    }
  }

  Rect _textBounds() {
    final width = (text.length * 11).clamp(60, 520).toDouble();
    return Rect.fromLTWH(bounds.left, bounds.top, width, 36);
  }

  bool _strokeHitTest(Offset point, double tolerance) {
    if (points.length == 1) {
      return (points.first - point).distance <= tolerance;
    }

    for (var index = 1; index < points.length; index += 1) {
      if (_distanceToSegment(point, points[index - 1], points[index]) <=
          tolerance) {
        return true;
      }
    }
    return false;
  }

  bool _lineHitTest(Offset point, double tolerance) {
    return _distanceToSegment(point, bounds.topLeft, bounds.bottomRight) <=
        tolerance;
  }

  double _distanceToSegment(Offset point, Offset start, Offset end) {
    final segment = end - start;
    final lengthSquared = segment.dx * segment.dx + segment.dy * segment.dy;
    if (lengthSquared == 0) {
      return (point - start).distance;
    }

    final projection =
        ((point.dx - start.dx) * segment.dx +
            (point.dy - start.dy) * segment.dy) /
        lengthSquared;
    final clampedProjection = projection.clamp(0.0, 1.0);
    final closest = Offset(
      start.dx + segment.dx * clampedProjection,
      start.dy + segment.dy * clampedProjection,
    );
    return (point - closest).distance;
  }
}

class WhiteboardState {
  const WhiteboardState({
    this.elements = const [],
    this.redoStack = const [],
    this.tool = WhiteboardTool.pen,
    this.color = Colors.black,
    this.strokeWidth = 4,
  });

  final List<WhiteboardElement> elements;
  final List<WhiteboardElement> redoStack;
  final WhiteboardTool tool;
  final Color color;
  final double strokeWidth;

  bool get canUndo => elements.isNotEmpty;
  bool get canRedo => redoStack.isNotEmpty;

  WhiteboardState copyWith({
    List<WhiteboardElement>? elements,
    List<WhiteboardElement>? redoStack,
    WhiteboardTool? tool,
    Color? color,
    double? strokeWidth,
  }) {
    return WhiteboardState(
      elements: elements ?? this.elements,
      redoStack: redoStack ?? this.redoStack,
      tool: tool ?? this.tool,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
    );
  }
}
