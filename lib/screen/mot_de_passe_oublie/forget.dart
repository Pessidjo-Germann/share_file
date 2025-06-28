import 'package:flutter/material.dart';

import 'components/body.dart';

class ForgetScreen extends StatelessWidget {
  const ForgetScreen({super.key});
  static String routeName = "/forget";

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Body(),
    );
  }
}
