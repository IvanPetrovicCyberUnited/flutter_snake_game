import 'package:flutter/material.dart';

class BlinkingText extends StatefulWidget {
  final String text;
  final TextStyle textStyle;

  const BlinkingText({
    required this.text,
    required this.textStyle,
    Key? key,
  }) : super(key: key);

  @override
  State<BlinkingText> createState() => _BlinkingTextState();
}

class _BlinkingTextState extends State<BlinkingText>
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
