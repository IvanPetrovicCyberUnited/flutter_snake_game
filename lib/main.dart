// ignore: avoid_web_libraries_in_flutter
// Only import dart:html for web
// ignore: uri_does_not_exist
import 'dart:html' as html;
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart' show RawKeyDownEvent, LogicalKeyboardKey;

import 'blinking_text.dart';
import 'direction.dart';
import 'dpad.dart';
import 'snake_painter.dart';

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
  bool soundOn = true;
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

  // ✅ angepasst für Android + Web
  bool get _isMobile =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

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
      if (soundOn) _audioPlayer.play(AssetSource('beep_high.wav'));
      gameOver = true;
      return;
    }

    if (snake.contains(newHead)) {
      if (soundOn) _audioPlayer.play(AssetSource('sounds/beep_low.wav'));
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
      if (soundOn) _audioPlayer.play(AssetSource('sounds/beep.wav'));
      _placeFood();
    } else if (frog != null && newHead == frog) {
      growBy += 5;
      currentScore += 5;
      if (soundOn) _audioPlayer.play(AssetSource('sounds/beep.wav'));
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
    // --- MENU LAYOUT REFACTOR ---
    // D-pad size (should match dpad.dart default for mobile)
    final double dpadSize = _isMobile ? 180 : 0;
    return Scaffold(
      body: Column(
        children: [
          // Game Area
          Expanded(
            child: Container(
              color: Colors.black,
              child: Stack(
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
                    child: _isMobile
                        ? SizedBox.expand(
                            child: CustomPaint(
                              painter: SnakePainter(
                                snake: snake,
                                food: food,
                                frog: frog,
                                frogColor: frogColor,
                                cols: cols,
                                rows: rows,
                              ),
                            ),
                          )
                        : GestureDetector(
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
                                painter: SnakePainter(
                                  snake: snake,
                                  food: food,
                                  frog: frog,
                                  frogColor: frogColor,
                                  cols: cols,
                                  rows: rows,
                                ),
                              ),
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
                    const BlinkingText(
                      text: 'YOU WIN!',
                      textStyle: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigoAccent,
                      ),
                    ),
                  // Controls info (desktop)
                  if (!_isMobile)
                    Positioned(
                      right: 16,
                      bottom: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: const [
                          Text(
                            'Controls:',
                            style: TextStyle(
                              color: Colors.tealAccent,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Use arrow keys to move',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Press Enter to pause the game',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  // Footer
                  Positioned(
                    left: 16,
                    bottom: 8,
                    child: const Text(
                      'Made with Flutter',
                      style: TextStyle(color: Colors.white24, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Menu Row (moved to bottom)
          Container(
            color: Colors.grey[900],
            constraints: BoxConstraints(minHeight: dpadSize),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left: Pause & Play Again
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isMobile)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: ElevatedButton.icon(
                          icon: Icon(paused ? Icons.play_arrow : Icons.pause),
                          label: Text(paused ? 'Resume' : 'Pause'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.yellow,
                            foregroundColor: Colors.black,
                            textStyle:
                                const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          onPressed: () {
                            setState(() {
                              paused = !paused;
                            });
                          },
                        ),
                      ),
                    if (gameOver)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text('Play Again'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.tealAccent,
                            foregroundColor: Colors.black,
                            textStyle:
                                const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          onPressed: () {
                            if (kIsWeb) {
                              html.window.location.reload();
                            } else {
                              // For mobile/desktop, just restart the app state
                            }
                          },
                        ),
                      ),
                  ],
                ),
                // Center: Title, Score, Sound
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Cyber Snake',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Colors.tealAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Score: $currentScore',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: Icon(
                              soundOn ? Icons.volume_up : Icons.volume_off,
                              color: Colors.tealAccent,
                            ),
                            tooltip: soundOn ? 'Mute' : 'Unmute',
                            onPressed: () {
                              setState(() {
                                soundOn = !soundOn;
                              });
                            },
                          ),
                          Text(
                            soundOn ? 'Sound On' : 'Muted',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                      if (victory)
                        const Padding(
                          padding: EdgeInsets.only(top: 8.0),
                          child: Text(
                            'You Win!\nRefresh to play again.',
                            style: TextStyle(
                                color: Colors.indigoAccent, fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      if (paused && !gameOver && !victory)
                        const Padding(
                          padding: EdgeInsets.only(top: 8.0),
                          child: Text(
                            'Paused',
                            style:
                                TextStyle(color: Colors.yellow, fontSize: 16),
                          ),
                        ),
                    ],
                  ),
                ),
                // Right: D-pad
                if (_isMobile)
                  SizedBox(
                    width: dpadSize,
                    height: dpadSize,
                    child: RetroDPad(
                      onDirection: (dir) {
                        setState(() {
                          _changeDirection(dir);
                        });
                      },
                      size: dpadSize,
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
