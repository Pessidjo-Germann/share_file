import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

const kprimaryColor = Color(0xff3737a0);
const kcolorCourse = Color.fromRGBO(110, 110, 214, 0.410);
const kcolorEpreuve = Color(0xFFE3C2E9);
const kcolorQuiz = Color(0xFFF5EAC8);
const kcolorConcour = Color(0xFF92E3A9);
const kbackGroungColor = Color.fromARGB(36, 163, 208, 228);
const kboxLevel = Color(0xFFE3C2E9);
const kColorBlack = Colors.black;
const toastDuration = Duration(seconds: 6);
const kyellowColor = Color.fromRGBO(255, 192, 0, 1);
Widget textPresentation({
  required String msg,
  double size = 30,
  Color color = kprimaryColor,
  TextAlign textAlign = TextAlign.center,
  TextOverflow overflow = TextOverflow.ellipsis,
  int? maxLine,
  double? minFontSize,
  required FontWeight fontWeight,
}) {
  return // LayoutBuilder(
      //builder: (context, constraints) {
      //  double maxFontSize = (constraints.maxWidth / 10).floorToDouble();

      // return
      AutoSizeText(
    msg,
    textAlign: textAlign,
    overflow: overflow,
    maxLines: maxLine ?? 1,
    minFontSize: minFontSize ?? 11,
    stepGranularity: 1,
    style: TextStyle(
      fontWeight: fontWeight,
      color: color,
      fontSize: size,
      fontFamily: 'ProximaNova',
    ),
    // maxFontSize: maxFontSize,
  );
  //  },
  //  );
}
