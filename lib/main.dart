import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const CyberSnakeApp());
}

class CyberSnakeApp extends StatelessWidget {
  const CyberSnakeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cyber Snake',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.tealAccent,
        colorScheme: const ColorScheme.dark(),
      ),
      home: const SnakeGamePage(),
    );
  }
}

class SnakeGamePage extends StatefulWidget {
  const SnakeGamePage({super.key});

  @override
  State<SnakeGamePage> createState() => _SnakeGamePageState();
}

class _SnakeGamePageState extends State<SnakeGamePage>
    with SingleTickerProviderStateMixin {
  final FocusNode _focusNode = FocusNode();
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
  double _accumulator = 0;

  static const int rows = 20;
  static const int cols = 20;
  static const double stepTime = 200;
  static const int maxLength = 100;

  final Random _rand = Random();
  List<Point<int>> snake = [const Point(10, 10)];
  Point<int> food = const Point(5, 5);
  Point<int>? frog;
  Color frogColor = Colors.green;
  int growBy = 0;
  Direction direction = Direction.right;
  bool gameOver = false;
  bool victory = false;
  DateTime _lastFrog = DateTime.now();

  @override
  void initState() {
    super.initState();
    _placeFood();
    _ticker = createTicker(_onTick)..start();
    _focusNode.requestFocus();
  }

  void _onTick(Duration elapsed) {
    final dt = elapsed - _lastElapsed;
    _lastElapsed = elapsed;
    _accumulator += dt.inMilliseconds;
    if (_accumulator >= stepTime) {
      _accumulator -= stepTime;
      _update();
    }
    setState(() {});
  }

  void _update() {
    if (gameOver || victory) return;
    _spawnFrog();
    final head = snake.first;
    var newHead = head;
    switch (direction) {
      case Direction.up:
        newHead = Point(head.x, head.y - 1);
        break;
      case Direction.down:
        newHead = Point(head.x, head.y + 1);
        break;
      case Direction.left:
        newHead = Point(head.x - 1, head.y);
        break;
      case Direction.right:
        newHead = Point(head.x + 1, head.y);
        break;
    }

    if (newHead.x < 0 ||
        newHead.y < 0 ||
        newHead.x >= cols ||
        newHead.y >= rows) {
      gameOver = true;
      return;
    }

    final index = snake.indexOf(newHead);
    if (index != -1) {
      snake = snake.sublist(0, index);
    }

    snake.insert(0, newHead);

    if (newHead == food) {
      growBy += 1;
      _placeFood();
    } else if (frog != null && newHead == frog) {
      growBy += 5;
      frog = null;
    }

    if (growBy > 0) {
      growBy -= 1;
    } else {
      if (snake.length > 1) {
        snake.removeLast();
      }
    }

    if (snake.length >= maxLength) {
      victory = true;
    }
  }

  void _spawnFrog() {
    if (frog != null) return;
    if (DateTime.now().difference(_lastFrog).inSeconds < 10) return;
    var pos = _randomFreeCell();
    frog = pos;
    frogColor = Colors.primaries[_rand.nextInt(Colors.primaries.length)];
    _lastFrog = DateTime.now();
  }

  void _placeFood() {
    food = _randomFreeCell();
  }

  Point<int> _randomFreeCell() {
    Point<int> p;
    do {
      p = Point(_rand.nextInt(cols), _rand.nextInt(rows));
    } while (snake.contains(p) || p == frog);
    return p;
  }

  void _changeDirection(Direction newDir) {
    if ((direction == Direction.up && newDir == Direction.down) ||
        (direction == Direction.down && newDir == Direction.up) ||
        (direction == Direction.left && newDir == Direction.right) ||
        (direction == Direction.right && newDir == Direction.left)) {
      return;
    }
    direction = newDir;
  }

  @override
  void dispose() {
    _ticker.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RawKeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKey: (event) {
          if (event is RawKeyDownEvent) {
            final key = event.logicalKey;

            switch (key.keyLabel.toLowerCase()) {
              case 'w':
                _changeDirection(Direction.up);
                break;
              case 's':
                _changeDirection(Direction.down);
                break;
              case 'a':
                _changeDirection(Direction.left);
                break;
              case 'd':
                _changeDirection(Direction.right);
                break;
            }

            if (key == LogicalKeyboardKey.arrowUp) {
              _changeDirection(Direction.up);
            } else if (key == LogicalKeyboardKey.arrowDown) {
              _changeDirection(Direction.down);
            } else if (key == LogicalKeyboardKey.arrowLeft) {
              _changeDirection(Direction.left);
            } else if (key == LogicalKeyboardKey.arrowRight) {
              _changeDirection(Direction.right);
            }
          }
        },
        child: GestureDetector(
          onPanUpdate: (details) {
            final delta = details.delta;
            if (delta.dx.abs() > delta.dy.abs()) {
              if (delta.dx > 0) {
                _changeDirection(Direction.right);
              } else {
                _changeDirection(Direction.left);
              }
            } else {
              if (delta.dy > 0) {
                _changeDirection(Direction.down);
              } else {
                _changeDirection(Direction.up);
              }
            }
          },
          child: SizedBox.expand(
            child: CustomPaint(
              painter: _SnakePainter(
                snake: snake,
                food: food,
                frog: frog,
                frogColor: frogColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SnakePainter extends CustomPainter {
  final List<Point<int>> snake;
  final Point<int> food;
  final Point<int>? frog;
  final Color frogColor;

  _SnakePainter({
    required this.snake,
    required this.food,
    required this.frog,
    required this.frogColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cellWidth = size.width / _SnakeGamePageState.cols;
    final cellHeight = size.height / _SnakeGamePageState.rows;
    final paint = Paint()..color = Colors.greenAccent;

    for (var point in snake) {
      final rect = Rect.fromLTWH(
        point.x * cellWidth,
        point.y * cellHeight,
        cellWidth,
        cellHeight,
      );
      canvas.drawRect(rect.deflate(1), paint);
    }

    final foodRect = Rect.fromLTWH(
      food.x * cellWidth,
      food.y * cellHeight,
      cellWidth,
      cellHeight,
    );
    canvas.drawRect(foodRect.deflate(1), Paint()..color = Colors.redAccent);

    if (frog != null) {
      final frogRect = Rect.fromLTWH(
        frog!.x * cellWidth,
        frog!.y * cellHeight,
        cellWidth,
        cellHeight,
      );
      canvas.drawRect(frogRect.deflate(1), Paint()..color = frogColor);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

enum Direction { up, down, left, right }
