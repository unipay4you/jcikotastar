import 'package:flutter/material.dart';

class JCILogo extends StatelessWidget {
  final double size;
  final Color? backgroundColor;
  final EdgeInsets padding;

  const JCILogo({
    Key? key,
    this.size = 120,
    this.backgroundColor = Colors.white,
    this.padding = const EdgeInsets.all(8.0),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      child: Padding(
        padding: padding,
        child: ClipOval(
          child: Image.asset(
            'assets/media/logo/jcistar.jpg',
            fit: BoxFit.contain,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
      ),
    );
  }
} 