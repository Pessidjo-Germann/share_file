import 'package:flutter/material.dart';

import 'components/body.dart';

class InscriptionScreen extends StatelessWidget {
  const InscriptionScreen({super.key});
  static String routeName = "/inscription";

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
    //  backgroundColor: Colors.blue,
      body: Body(),
    );
  }
}
