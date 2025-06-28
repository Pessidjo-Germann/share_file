import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class BoutonContinuer extends StatelessWidget {
  const BoutonContinuer({
    super.key,
    required this.size,
    required this.press,
  });

  final Size size;
  final GestureCancelCallback press;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: press,
      child: SizedBox(
        child: Container(
            width: size.width * 0.76,
            height: size.height * 0.065,
            decoration: BoxDecoration(
              color: const Color(0xff3737a0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                "Continuer",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )),
      ),
    );
  }
}
