import 'package:flutter/material.dart';

import 'direction.dart';

class RetroDPad extends StatelessWidget {
  final void Function(Direction) onDirection;

  const RetroDPad({required this.onDirection, Key? key}) : super(key: key);

  Widget _buildButton(IconData icon, Direction dir) {
    return GestureDetector(
      onTap: () => onDirection(dir),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade800,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      height: 150,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 50,
            right: 50,
            height: 50,
            child: _buildButton(Icons.arrow_drop_up, Direction.up),
          ),
          Positioned(
            bottom: 0,
            left: 50,
            right: 50,
            height: 50,
            child: _buildButton(Icons.arrow_drop_down, Direction.down),
          ),
          Positioned(
            left: 0,
            top: 50,
            bottom: 50,
            width: 50,
            child: _buildButton(Icons.arrow_left, Direction.left),
          ),
          Positioned(
            right: 0,
            top: 50,
            bottom: 50,
            width: 50,
            child: _buildButton(Icons.arrow_right, Direction.right),
          ),
        ],
      ),
    );
  }
}
