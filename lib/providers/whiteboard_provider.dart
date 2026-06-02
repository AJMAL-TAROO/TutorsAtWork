import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/whiteboard_element.dart';

final whiteboardControllerProvider =
    NotifierProvider.family<WhiteboardController, WhiteboardState, String>(
      WhiteboardController.new,
    );

class WhiteboardController extends Notifier<WhiteboardState> {
  WhiteboardController(this.tutorKey);

  final String tutorKey;
  var _nextId = 0;

  @override
  WhiteboardState build() {
    return const WhiteboardState();
  }

  void setTool(WhiteboardTool tool) {
    state = state.copyWith(tool: tool);
  }

  void setColor(Color color) {
    state = state.copyWith(color: color);
  }

  void setStrokeWidth(double strokeWidth) {
    state = state.copyWith(strokeWidth: strokeWidth);
  }

  void addElement(WhiteboardElement element) {
    state = state.copyWith(
      elements: [...state.elements, element],
      redoStack: const [],
    );
  }

  void removeElementsAt(Offset point) {
    final remaining = state.elements
        .where((element) => !element.hitTest(point))
        .toList();
    if (remaining.length == state.elements.length) {
      return;
    }
    state = state.copyWith(elements: remaining, redoStack: const []);
  }

  void undo() {
    if (state.elements.isEmpty) {
      return;
    }
    final elements = [...state.elements];
    final removed = elements.removeLast();
    state = state.copyWith(
      elements: elements,
      redoStack: [removed, ...state.redoStack],
    );
  }

  void redo() {
    if (state.redoStack.isEmpty) {
      return;
    }
    final redoStack = [...state.redoStack];
    final restored = redoStack.removeAt(0);
    state = state.copyWith(
      elements: [...state.elements, restored],
      redoStack: redoStack,
    );
  }

  void clear() {
    state = state.copyWith(elements: const [], redoStack: const []);
  }

  String nextElementId() {
    _nextId += 1;
    return '${tutorKey}_whiteboard_$_nextId';
  }
}
