import 'package:flutter/material.dart';

class TypingIndicator extends StatefulWidget {
  final Color bubbleColor;
  final Color dotColor;

  const TypingIndicator({
    super.key,
    this.bubbleColor = const Color(0xFFEDEDED),
    this.dotColor = const Color(0xFF9E9E9E),
  });

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _appearanceController;
  late Animation<double> _indicatorSpaceAnimation;

  late List<AnimationController> _dotControllers;
  late List<Animation<double>> _dotAnimations;

  final List<Interval> _dotIntervals = const [
    Interval(0.0, 0.7),
    Interval(0.2, 0.9),
    Interval(0.4, 1.0),
  ];

  @override
  void initState() {
    super.initState();

    _appearanceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _indicatorSpaceAnimation = CurvedAnimation(
      parent: _appearanceController,
      curve: const Interval(0.0, 1.0, curve: Curves.easeOut),
    ).drive(Tween<double>(begin: 0.0, end: 1.0));

    _dotControllers = List.generate(
      3,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1000),
      )..repeat(),
    );

    _dotAnimations = List.generate(
      3,
      (index) => CurvedAnimation(
        parent: _dotControllers[index],
        curve: _dotIntervals[index],
      ).drive(Tween<double>(begin: 0.0, end: 1.0)),
    );

    _appearanceController.forward();
  }

  @override
  void dispose() {
    _appearanceController.dispose();
    for (final controller in _dotControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: _indicatorSpaceAnimation,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: widget.bubbleColor,
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (index) => _buildDot(index))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.0),
      child: AnimatedBuilder(
        animation: _dotAnimations[index],
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, -3.0 * _dotAnimations[index].value),
            child: Container(
              width: 6.0,
              height: 6.0,
              decoration: BoxDecoration(
                color: widget.dotColor,
                shape: BoxShape.circle,
              ),
            ),
          );
        },
      ),
    );
  }
}
