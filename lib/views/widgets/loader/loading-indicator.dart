import 'package:flutter/material.dart';

import 'package:katya/global/dimensions.dart';

class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({
    super.key,
    this.size = 28,
    this.loading = false,
  });

  final double size;
  final bool loading;

  @override
  Widget build(BuildContext context) => Container(
        constraints: BoxConstraints(
          maxWidth: size,
          maxHeight: size,
        ),
        child: const CircularProgressIndicator(
          strokeWidth: Dimensions.strokeWidthDefault,
          backgroundColor: Colors.white,
          valueColor: AlwaysStoppedAnimation<Color>(
            Colors.grey,
          ),
        ),
      );
}
