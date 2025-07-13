import 'package:flutter/material.dart';

import 'direction.dart';

class RetroDPad extends StatelessWidget {
  final void Function(Direction) onDirection;
  final double size;

  const RetroDPad({required this.onDirection, this.size = 180, Key? key})
      : super(key: key);

  Widget _buildButton(IconData icon, Direction dir,
      {double? width, double? height}) {
    return GestureDetector(
      onTap: () => onDirection(dir),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey.shade700.withOpacity(0.9),
          shape: BoxShape.rectangle,
          border: Border.all(color: Colors.white70, width: 2),
        ),
        child: Center(
          child: Icon(icon, color: Colors.white, size: 36),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double btnSize = size * 0.36;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // Up
          Positioned(
            top: 0,
            left: (size - btnSize) / 2,
            width: btnSize,
            height: btnSize,
            child: _buildButton(Icons.keyboard_arrow_up, Direction.up,
                width: btnSize, height: btnSize),
          ),
          // Down
          Positioned(
            bottom: 0,
            left: (size - btnSize) / 2,
            width: btnSize,
            height: btnSize,
            child: _buildButton(Icons.keyboard_arrow_down, Direction.down,
                width: btnSize, height: btnSize),
          ),
          // Left
          Positioned(
            left: 0,
            top: (size - btnSize) / 2,
            width: btnSize,
            height: btnSize,
            child: _buildButton(Icons.keyboard_arrow_left, Direction.left,
                width: btnSize, height: btnSize),
          ),
          // Right
          Positioned(
            right: 0,
            top: (size - btnSize) / 2,
            width: btnSize,
            height: btnSize,
            child: _buildButton(Icons.keyboard_arrow_right, Direction.right,
                width: btnSize, height: btnSize),
          ),
        ],
      ),
    );
  }
}
