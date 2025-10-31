import 'package:flutter/material.dart';

/// Widget that displays the Tabi logo based on the current theme mode
class TabiLogo extends StatelessWidget {
  final double? width;
  final double? height;
  final BoxFit? fit;

  const TabiLogo({
    super.key,
    this.width,
    this.height,
    this.fit,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Image.asset(
      isDark 
          ? 'assets/icons/Tabi-dark-logo.png'
          : 'assets/icons/Tabi-light-logo.png',
      width: width,
      height: height,
      fit: fit ?? BoxFit.contain,
    );
  }
}

