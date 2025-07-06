import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';

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
  final AudioPlayer _audioPlayer = AudioPlayer();
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
  int currentScore = 0;
  Direction direction = Direction.right;
  bool gameOver = false;
  bool victory = false;
  bool paused = false;
  bool _directionChangedThisTick = false;
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
      if (!paused) {
        _update();
        _directionChangedThisTick = false;
      }
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
      _audioPlayer.play(AssetSource('beep_high.wav'));
      gameOver = true;
      return;
    }

    if (snake.contains(newHead)) {
      _audioPlayer.play(AssetSource('sounds/beep_low.wav'));
      final collisionIndex = snake.indexOf(newHead);
      snake.insert(0, newHead);
      final bittenOff = snake.length - (collisionIndex + 1);
      snake = snake.sublist(0, collisionIndex + 1);
      currentScore = max(0, currentScore - bittenOff);
      return;
    }

    snake.insert(0, newHead);

    if (newHead == food) {
      growBy += 1;
      currentScore += 1;
      _audioPlayer.play(AssetSource('sounds/beep.wav'));
      _placeFood();
    } else if (frog != null && newHead == frog) {
      growBy += 5;
      currentScore += 5;
      _audioPlayer.play(AssetSource('sounds/beep.wav'));
      frog = null;
    }

    if (growBy > 0) {
      growBy -= 1;
    } else {
      snake.removeLast();
    }

    if (currentScore >= maxLength) {
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
    if (_directionChangedThisTick) return;

    if ((direction == Direction.up && newDir == Direction.down) ||
        (direction == Direction.down && newDir == Direction.up) ||
        (direction == Direction.left && newDir == Direction.right) ||
        (direction == Direction.right && newDir == Direction.left)) {
      return;
    }

    direction = newDir;
    _directionChangedThisTick = true;
  }

  @override
  void dispose() {
    _ticker.dispose();
    _focusNode.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          RawKeyboardListener(
            focusNode: _focusNode,
            autofocus: true,
            onKey: (event) {
              if (event is RawKeyDownEvent) {
                final key = event.logicalKey;

                if (key == LogicalKeyboardKey.enter) {
                  setState(() {
                    paused = !paused;
                  });
                  return;
                }

                if (!paused) {
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
              }
            },
            child: GestureDetector(
              onPanUpdate: (details) {
                if (paused) return;
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
          Positioned(
            top: 16,
            left: 16,
            child: Text(
              'Score: $currentScore',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (paused)
            const Center(
              child: Text(
                'PAUSED',
                style: TextStyle(
                  color: Colors.yellow,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          if (gameOver)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    'GAME OVER',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Refresh the page to play again',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          if (victory)
            const _BlinkingText(
              text: 'YOU WIN!',
              textStyle: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.indigoAccent,
              ),
            ),
        ],
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

class _BlinkingText extends StatefulWidget {
  final String text;
  final TextStyle textStyle;

  const _BlinkingText({
    required this.text,
    required this.textStyle,
    Key? key,
  }) : super(key: key);

  @override
  State<_BlinkingText> createState() => _BlinkingTextState();
}

class _BlinkingTextState extends State<_BlinkingText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Center(
        child: Text(widget.text, style: widget.textStyle),
      ),
    );
  }
}
