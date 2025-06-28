import 'package:flutter/material.dart';

class SpalshContent extends StatelessWidget {
  const SpalshContent({
    super.key,
    required this.img,
    required this.text,
  });
  final String img, text;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          //const SizedBox(height: 70),
          const Spacer(flex: 2),
          Center(
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(img, width: 200, height: 200))),
          const SizedBox(height: 70),
          const Text(
            "GEDAHAppIAI",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 30,
            ),
          ),
          Text(
            text,
            textAlign: TextAlign.center,
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
