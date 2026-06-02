import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/app_user.dart';
import '../../models/whiteboard_element.dart';
import '../../navigation/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/whiteboard_provider.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/empty_state.dart';

class WhiteboardScreen extends ConsumerStatefulWidget {
  const WhiteboardScreen({super.key});

  @override
  ConsumerState<WhiteboardScreen> createState() => _WhiteboardScreenState();
}

class _WhiteboardScreenState extends ConsumerState<WhiteboardScreen> {
  List<Offset> _activeStroke = const [];
  Offset? _shapeStart;
  Offset? _shapeEnd;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return AppShell(
      title: 'Whiteboard',
      leading: IconButton(
        tooltip: 'Back to dashboard',
        onPressed: () => context.go(AppRoutes.dashboard),
        icon: const Icon(Icons.arrow_back),
      ),
      onBack: () async => context.go(AppRoutes.dashboard),
      child: user?.role == UserRole.admin
          ? _WhiteboardWorkspace(
              user: user!,
              activeStroke: _activeStroke,
              shapeStart: _shapeStart,
              shapeEnd: _shapeEnd,
              onPointerDown: _handlePointerDown,
              onPointerMove: _handlePointerMove,
              onPointerUp: _handlePointerUp,
              onCanvasTap: _handleCanvasTap,
            )
          : const EmptyState(
              icon: Icons.lock_outline,
              title: 'Tutors only',
              message: 'Whiteboard is available for tutor accounts.',
            ),
    );
  }

  void _handlePointerDown(AppUser user, Offset point) {
    final board = ref.read(whiteboardControllerProvider(user.key));
    final controller = ref.read(
      whiteboardControllerProvider(user.key).notifier,
    );

    switch (board.tool) {
      case WhiteboardTool.pen:
        setState(() {
          _activeStroke = [point];
          _shapeStart = null;
          _shapeEnd = null;
        });
      case WhiteboardTool.eraser:
        controller.removeElementsAt(point);
      case WhiteboardTool.line:
      case WhiteboardTool.rectangle:
      case WhiteboardTool.ellipse:
      case WhiteboardTool.triangle:
        setState(() {
          _activeStroke = const [];
          _shapeStart = point;
          _shapeEnd = point;
        });
      case WhiteboardTool.text:
        break;
    }
  }

  void _handlePointerMove(AppUser user, Offset point) {
    final board = ref.read(whiteboardControllerProvider(user.key));
    final controller = ref.read(
      whiteboardControllerProvider(user.key).notifier,
    );

    switch (board.tool) {
      case WhiteboardTool.pen:
        if (_activeStroke.isEmpty) {
          return;
        }
        setState(() {
          _activeStroke = [..._activeStroke, point];
        });
      case WhiteboardTool.eraser:
        controller.removeElementsAt(point);
      case WhiteboardTool.line:
      case WhiteboardTool.rectangle:
      case WhiteboardTool.ellipse:
      case WhiteboardTool.triangle:
        if (_shapeStart == null) {
          return;
        }
        setState(() {
          _shapeEnd = point;
        });
      case WhiteboardTool.text:
        break;
    }
  }

  void _handlePointerUp(AppUser user, Offset point) {
    final board = ref.read(whiteboardControllerProvider(user.key));
    final controller = ref.read(
      whiteboardControllerProvider(user.key).notifier,
    );

    switch (board.tool) {
      case WhiteboardTool.pen:
        if (_activeStroke.isEmpty) {
          return;
        }
        controller.addElement(
          WhiteboardElement.stroke(
            id: controller.nextElementId(),
            points: _activeStroke,
            color: board.color,
            strokeWidth: board.strokeWidth,
          ),
        );
        setState(() => _activeStroke = const []);
      case WhiteboardTool.line:
      case WhiteboardTool.rectangle:
      case WhiteboardTool.ellipse:
      case WhiteboardTool.triangle:
        final start = _shapeStart;
        final end = _shapeEnd ?? point;
        if (start == null || (start - end).distance < 4) {
          setState(() {
            _shapeStart = null;
            _shapeEnd = null;
          });
          return;
        }
        controller.addElement(
          WhiteboardElement.shape(
            id: controller.nextElementId(),
            kind: _shapeKindForTool(board.tool),
            bounds: Rect.fromPoints(start, end),
            color: board.color,
            strokeWidth: board.strokeWidth,
          ),
        );
        setState(() {
          _shapeStart = null;
          _shapeEnd = null;
        });
      case WhiteboardTool.eraser:
      case WhiteboardTool.text:
        break;
    }
  }

  Future<void> _handleCanvasTap(AppUser user, Offset point) async {
    final board = ref.read(whiteboardControllerProvider(user.key));
    if (board.tool != WhiteboardTool.text) {
      return;
    }

    final text = await showDialog<String>(
      context: context,
      builder: (context) => const _WhiteboardTextDialog(),
    );
    if (text == null || text.trim().isEmpty) {
      return;
    }

    final controller = ref.read(
      whiteboardControllerProvider(user.key).notifier,
    );
    controller.addElement(
      WhiteboardElement.text(
        id: controller.nextElementId(),
        position: point,
        text: text.trim(),
        color: board.color,
      ),
    );
  }

  WhiteboardElementKind _shapeKindForTool(WhiteboardTool tool) {
    return switch (tool) {
      WhiteboardTool.line => WhiteboardElementKind.line,
      WhiteboardTool.rectangle => WhiteboardElementKind.rectangle,
      WhiteboardTool.ellipse => WhiteboardElementKind.ellipse,
      WhiteboardTool.triangle => WhiteboardElementKind.triangle,
      WhiteboardTool.pen ||
      WhiteboardTool.eraser ||
      WhiteboardTool.text => WhiteboardElementKind.line,
    };
  }
}

class _WhiteboardWorkspace extends ConsumerWidget {
  const _WhiteboardWorkspace({
    required this.user,
    required this.activeStroke,
    required this.shapeStart,
    required this.shapeEnd,
    required this.onPointerDown,
    required this.onPointerMove,
    required this.onPointerUp,
    required this.onCanvasTap,
  });

  final AppUser user;
  final List<Offset> activeStroke;
  final Offset? shapeStart;
  final Offset? shapeEnd;
  final void Function(AppUser user, Offset point) onPointerDown;
  final void Function(AppUser user, Offset point) onPointerMove;
  final void Function(AppUser user, Offset point) onPointerUp;
  final Future<void> Function(AppUser user, Offset point) onCanvasTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final board = ref.watch(whiteboardControllerProvider(user.key));
    final controller = ref.read(
      whiteboardControllerProvider(user.key).notifier,
    );

    return Column(
      children: [
        _WhiteboardToolbar(
          board: board,
          onToolSelected: controller.setTool,
          onColorSelected: controller.setColor,
          onStrokeWidthChanged: controller.setStrokeWidth,
          onUndo: controller.undo,
          onRedo: controller.redo,
          onClear: () => _confirmClear(context, controller),
        ),
        const Divider(height: 1),
        Expanded(
          child: _WhiteboardCanvas(
            board: board,
            activeStroke: activeStroke,
            shapeStart: shapeStart,
            shapeEnd: shapeEnd,
            onPointerDown: (point) => onPointerDown(user, point),
            onPointerMove: (point) => onPointerMove(user, point),
            onPointerUp: (point) => onPointerUp(user, point),
            onCanvasTap: (point) => onCanvasTap(user, point),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmClear(
    BuildContext context,
    WhiteboardController controller,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear whiteboard'),
        content: const Text('Remove everything on this whiteboard?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      controller.clear();
    }
  }
}

class _WhiteboardToolbar extends StatelessWidget {
  const _WhiteboardToolbar({
    required this.board,
    required this.onToolSelected,
    required this.onColorSelected,
    required this.onStrokeWidthChanged,
    required this.onUndo,
    required this.onRedo,
    required this.onClear,
  });

  final WhiteboardState board;
  final ValueChanged<WhiteboardTool> onToolSelected;
  final ValueChanged<Color> onColorSelected;
  final ValueChanged<double> onStrokeWidthChanged;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            _ToolButton(
              tooltip: 'Pen',
              icon: Icons.edit,
              selected: board.tool == WhiteboardTool.pen,
              onPressed: () => onToolSelected(WhiteboardTool.pen),
            ),
            _ToolButton(
              tooltip: 'Eraser',
              icon: Icons.cleaning_services_outlined,
              selected: board.tool == WhiteboardTool.eraser,
              onPressed: () => onToolSelected(WhiteboardTool.eraser),
            ),
            _ToolButton(
              tooltip: 'Text',
              icon: Icons.text_fields,
              selected: board.tool == WhiteboardTool.text,
              onPressed: () => onToolSelected(WhiteboardTool.text),
            ),
            const SizedBox(width: 8),
            _ToolButton(
              tooltip: 'Line',
              icon: Icons.show_chart,
              selected: board.tool == WhiteboardTool.line,
              onPressed: () => onToolSelected(WhiteboardTool.line),
            ),
            _ToolButton(
              tooltip: 'Rectangle',
              icon: Icons.crop_square,
              selected: board.tool == WhiteboardTool.rectangle,
              onPressed: () => onToolSelected(WhiteboardTool.rectangle),
            ),
            _ToolButton(
              tooltip: 'Ellipse',
              icon: Icons.circle_outlined,
              selected: board.tool == WhiteboardTool.ellipse,
              onPressed: () => onToolSelected(WhiteboardTool.ellipse),
            ),
            _ToolButton(
              tooltip: 'Triangle',
              icon: Icons.change_history,
              selected: board.tool == WhiteboardTool.triangle,
              onPressed: () => onToolSelected(WhiteboardTool.triangle),
            ),
            const SizedBox(width: 12),
            for (final color in _whiteboardColors)
              _ColorSwatch(
                color: color,
                selected: board.color == color,
                onPressed: () => onColorSelected(color),
              ),
            const SizedBox(width: 12),
            SizedBox(
              width: 150,
              child: Slider(
                value: board.strokeWidth,
                min: 1,
                max: 24,
                divisions: 23,
                label: '${board.strokeWidth.round()}',
                onChanged: onStrokeWidthChanged,
              ),
            ),
            Text(
              '${board.strokeWidth.round()} px',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(width: 12),
            IconButton.filledTonal(
              tooltip: 'Undo',
              onPressed: board.canUndo ? onUndo : null,
              icon: const Icon(Icons.undo),
            ),
            const SizedBox(width: 6),
            IconButton.filledTonal(
              tooltip: 'Redo',
              onPressed: board.canRedo ? onRedo : null,
              icon: const Icon(Icons.redo),
            ),
            const SizedBox(width: 6),
            IconButton.filledTonal(
              tooltip: 'Clear whiteboard',
              onPressed: board.elements.isEmpty ? null : onClear,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.tooltip,
    required this.icon,
    required this.selected,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        style: selected
            ? IconButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              )
            : null,
        icon: Icon(icon),
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    required this.color,
    required this.selected,
    required this.onPressed,
  });

  final Color color;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Tooltip(
        message: 'Color',
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onPressed,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).dividerColor,
                width: selected ? 3 : 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WhiteboardCanvas extends StatelessWidget {
  const _WhiteboardCanvas({
    required this.board,
    required this.activeStroke,
    required this.shapeStart,
    required this.shapeEnd,
    required this.onPointerDown,
    required this.onPointerMove,
    required this.onPointerUp,
    required this.onCanvasTap,
  });

  final WhiteboardState board;
  final List<Offset> activeStroke;
  final Offset? shapeStart;
  final Offset? shapeEnd;
  final ValueChanged<Offset> onPointerDown;
  final ValueChanged<Offset> onPointerMove;
  final ValueChanged<Offset> onPointerUp;
  final Future<void> Function(Offset point) onCanvasTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (event) => onPointerDown(event.localPosition),
          onPointerMove: (event) => onPointerMove(event.localPosition),
          onPointerUp: (event) => onPointerUp(event.localPosition),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (details) => onCanvasTap(details.localPosition),
            child: DecoratedBox(
              decoration: const BoxDecoration(color: Colors.white),
              child: CustomPaint(
                size: Size(constraints.maxWidth, constraints.maxHeight),
                painter: _WhiteboardPainter(
                  board: board,
                  activeStroke: activeStroke,
                  shapeStart: shapeStart,
                  shapeEnd: shapeEnd,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _WhiteboardPainter extends CustomPainter {
  const _WhiteboardPainter({
    required this.board,
    required this.activeStroke,
    required this.shapeStart,
    required this.shapeEnd,
  });

  final WhiteboardState board;
  final List<Offset> activeStroke;
  final Offset? shapeStart;
  final Offset? shapeEnd;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);

    for (final element in board.elements) {
      _drawElement(canvas, element);
    }

    if (activeStroke.isNotEmpty) {
      _drawElement(
        canvas,
        WhiteboardElement.stroke(
          id: 'active',
          points: activeStroke,
          color: board.color,
          strokeWidth: board.strokeWidth,
        ),
      );
    }

    final start = shapeStart;
    final end = shapeEnd;
    if (start != null && end != null) {
      _drawElement(
        canvas,
        WhiteboardElement.shape(
          id: 'preview',
          kind: _previewKind,
          bounds: Rect.fromPoints(start, end),
          color: board.color,
          strokeWidth: board.strokeWidth,
        ),
      );
    }
  }

  WhiteboardElementKind get _previewKind {
    return switch (board.tool) {
      WhiteboardTool.line => WhiteboardElementKind.line,
      WhiteboardTool.rectangle => WhiteboardElementKind.rectangle,
      WhiteboardTool.ellipse => WhiteboardElementKind.ellipse,
      WhiteboardTool.triangle => WhiteboardElementKind.triangle,
      WhiteboardTool.pen ||
      WhiteboardTool.eraser ||
      WhiteboardTool.text => WhiteboardElementKind.line,
    };
  }

  void _drawElement(Canvas canvas, WhiteboardElement element) {
    final paint = Paint()
      ..color = element.color
      ..strokeWidth = element.strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    switch (element.kind) {
      case WhiteboardElementKind.stroke:
        _drawStroke(canvas, element.points, paint);
      case WhiteboardElementKind.text:
        _drawText(canvas, element);
      case WhiteboardElementKind.line:
        canvas.drawLine(
          element.bounds.topLeft,
          element.bounds.bottomRight,
          paint,
        );
      case WhiteboardElementKind.rectangle:
        canvas.drawRect(element.bounds, paint);
      case WhiteboardElementKind.ellipse:
        canvas.drawOval(element.bounds, paint);
      case WhiteboardElementKind.triangle:
        canvas.drawPath(_trianglePath(element.bounds), paint);
    }
  }

  void _drawStroke(Canvas canvas, List<Offset> points, Paint paint) {
    if (points.length == 1) {
      canvas.drawCircle(points.first, paint.strokeWidth / 2, paint);
      return;
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var index = 1; index < points.length; index += 1) {
      final previous = points[index - 1];
      final current = points[index];
      final midPoint = Offset(
        (previous.dx + current.dx) / 2,
        (previous.dy + current.dy) / 2,
      );
      path.quadraticBezierTo(
        previous.dx,
        previous.dy,
        midPoint.dx,
        midPoint.dy,
      );
    }
    path.lineTo(points.last.dx, points.last.dy);
    canvas.drawPath(path, paint);
  }

  void _drawText(Canvas canvas, WhiteboardElement element) {
    final painter = TextPainter(
      text: TextSpan(
        text: element.text,
        style: TextStyle(
          color: element.color,
          fontSize: 22,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 8,
    )..layout(maxWidth: 520);
    painter.paint(canvas, element.bounds.topLeft);
  }

  Path _trianglePath(Rect bounds) {
    return Path()
      ..moveTo(bounds.center.dx, bounds.top)
      ..lineTo(bounds.right, bounds.bottom)
      ..lineTo(bounds.left, bounds.bottom)
      ..close();
  }

  @override
  bool shouldRepaint(covariant _WhiteboardPainter oldDelegate) {
    return oldDelegate.board != board ||
        oldDelegate.activeStroke != activeStroke ||
        oldDelegate.shapeStart != shapeStart ||
        oldDelegate.shapeEnd != shapeEnd;
  }
}

class _WhiteboardTextDialog extends StatefulWidget {
  const _WhiteboardTextDialog();

  @override
  State<_WhiteboardTextDialog> createState() => _WhiteboardTextDialogState();
}

class _WhiteboardTextDialogState extends State<_WhiteboardTextDialog> {
  final _formKey = GlobalKey<FormState>();
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add text'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: TextFormField(
            controller: _textController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Text',
              prefixIcon: Icon(Icons.text_fields),
            ),
            minLines: 2,
            maxLines: 5,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Required';
              }
              return null;
            },
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.add),
          label: const Text('Add'),
        ),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    Navigator.of(context).pop(_textController.text.trim());
  }
}

const _whiteboardColors = [
  Colors.black,
  Color(0xFFE53935),
  Color(0xFF1E88E5),
  Color(0xFF43A047),
  Color(0xFFFDD835),
  Color(0xFF8E24AA),
];
