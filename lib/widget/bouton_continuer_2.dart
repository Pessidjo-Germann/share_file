import 'package:flutter/material.dart';

class BottonContinuer2 extends StatelessWidget {
  const BottonContinuer2({
    super.key,
    required this.size,
    required this.press,
    required this.name,
    this.color = const Color(0xff3737a0),
  });
  final String name;
  final Size size;
  final Function() press;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: press,
      child: SizedBox(
        child: Container(
            width: size.width,
            height: size.height * 0.065,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                name,
                style: const TextStyle(
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
