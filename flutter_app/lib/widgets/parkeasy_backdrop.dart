import 'package:flutter/material.dart';

import '../theme/parkeasy_theme.dart';

class ParkEasyBackdrop extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  const ParkEasyBackdrop({
    super.key,
    required this.child,
    this.maxWidth = 640,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: ParkEasyTheme.pageGradient),
      child: Stack(
        children: [
          Positioned(
            top: -85,
            right: -60,
            child: _blob(
              size: 210,
              color: const Color(0xFF99F6E4).withValues(alpha: 0.34),
            ),
          ),
          Positioned(
            top: 90,
            left: -80,
            child: _blob(
              size: 170,
              color: const Color(0xFFFED7AA).withValues(alpha: 0.32),
            ),
          ),
          Positioned(
            bottom: -90,
            left: 40,
            child: _blob(
              size: 190,
              color: const Color(0xFFBAE6FD).withValues(alpha: 0.25),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double contentWidth =
                    constraints.maxWidth > maxWidth ? maxWidth : constraints.maxWidth;
                return Center(
                  child: SizedBox(
                    width: contentWidth,
                    height: constraints.maxHeight,
                    child: Padding(
                      padding: padding,
                      child: child,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _blob({required double size, required Color color}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}
