import 'package:flutter/material.dart';

class CupertinoSheetContainer extends StatelessWidget {
  final Widget child;
  final double height;

  const CupertinoSheetContainer({
    super.key,
    required this.child,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(10),
        topRight: Radius.circular(10),
      ),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}