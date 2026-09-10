import 'package:flutter/material.dart';

import '../constants/app_constants.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({this.showName = true, this.compact = false, super.key});

  final bool showName;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final double size = compact ? 34 : 42;
    return Semantics(
      label: AppConstants.appName,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(size * .32),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                const Icon(Icons.forum_rounded, color: Colors.white),
                Positioned(
                  right: size * .13,
                  bottom: size * .1,
                  child: Container(
                    width: size * .24,
                    height: size * .24,
                    decoration: const BoxDecoration(color: Color(0xFFFFC95C), shape: BoxShape.circle),
                  ),
                ),
              ],
            ),
          ),
          if (showName) ...<Widget>[
            const SizedBox(width: 10),
            Text(
              AppConstants.appName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
          ],
        ],
      ),
    );
  }
}
