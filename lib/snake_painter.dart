import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';

class SnakePainter extends CustomPainter {
  final List<Point<int>> snake;
  final Point<int> food;
  final Point<int>? frog;
  final Color frogColor;
  final int cols;
  final int rows;

  SnakePainter({
    required this.snake,
    required this.food,
    required this.frog,
    required this.frogColor,
    required this.cols,
    required this.rows,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cellWidth = size.width / cols;
    final cellHeight = size.height / rows;
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
