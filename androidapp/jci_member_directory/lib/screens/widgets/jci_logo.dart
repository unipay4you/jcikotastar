import 'package:flutter/material.dart';

class JCILogo extends StatelessWidget {
  final double size;
  final Color backgroundColor;
  final EdgeInsets padding;

  const JCILogo({
    Key? key,
    required this.size,
    required this.backgroundColor,
    required this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Image.asset(
        'assets/images/jci_logo.png',
        fit: BoxFit.contain,
      ),
    );
  }
}
