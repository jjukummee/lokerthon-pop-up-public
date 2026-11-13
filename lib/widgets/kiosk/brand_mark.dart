import 'package:flutter/material.dart';

import '../../l10n/lang.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final width = compact ? 132.0 : 208.0;
    final height = compact ? 58.0 : 91.0;

    return SizedBox(
      width: width,
      height: height,
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            tr('행궁다과', 'Haenggung Dagwa', 'ヘングン茶菓'),
            style: TextStyle(
              fontSize: compact ? 30 : 44,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
