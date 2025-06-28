import 'package:flutter/material.dart';

import 'components/body.dart';

class SpalshScreen extends StatelessWidget {
  const SpalshScreen({super.key});
  static String routeName = '/spalsh';

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: Body(),
    );
  }
}
