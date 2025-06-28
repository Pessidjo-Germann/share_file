import 'package:flutter/material.dart';
import 'package:share_file_iai/constante.dart';

class BoxDocument extends StatefulWidget {
  const BoxDocument(
      {super.key,
      required this.message,
      required this.message2,
      required this.file,
      required this.press});
  final String message, message2, file;
  final Function() press;

  @override
  _BoxDocumentState createState() => _BoxDocumentState();
}

class _BoxDocumentState extends State<BoxDocument> {
  Color containerColor = Colors.white70; // Couleur par défaut

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() {
          containerColor =
              const Color.fromARGB(255, 251, 201, 187); // Couleur au survol
        });
      },
      onExit: (_) {
        setState(() {
          containerColor = Colors.white70; // Revenir à la couleur par défaut
        });
      },
      child: InkWell(
        onTap: widget.press,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.all(6),
              height: 200,
              color: containerColor, // Couleur dynamique
              child: Image.asset(widget.file, width: 150, height: 150),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  textPresentation(
                      msg: widget.message,
                      fontWeight: FontWeight.bold,
                      size: 15,
                      color: kColorBlack,
                      textAlign: TextAlign.start),
                  textPresentation(
                      msg: widget.message2,
                      fontWeight: FontWeight.w200,
                      size: 13,
                      color: kColorBlack,
                      textAlign: TextAlign.start),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
