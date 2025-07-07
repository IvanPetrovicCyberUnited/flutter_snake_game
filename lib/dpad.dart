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
          color: Colors.grey.shade700.withOpacity(0.9),
          shape: BoxShape.rectangle,
          border: Border.all(color: Colors.white70, width: 2),
        ),
        child: Center(
          child: Icon(icon, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 55,
            right: 55,
            height: 50,
            child: _buildButton(Icons.keyboard_arrow_up, Direction.up),
          ),
          Positioned(
            bottom: 0,
            left: 55,
            right: 55,
            height: 50,
            child: _buildButton(Icons.keyboard_arrow_down, Direction.down),
          ),
          Positioned(
            left: 0,
            top: 55,
            bottom: 55,
            width: 50,
            child: _buildButton(Icons.keyboard_arrow_left, Direction.left),
          ),
          Positioned(
            right: 0,
            top: 55,
            bottom: 55,
            width: 50,
            child: _buildButton(Icons.keyboard_arrow_right, Direction.right),
          ),
        ],
      ),
    );
  }
}
