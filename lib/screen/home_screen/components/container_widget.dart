import 'package:flutter/material.dart';
import 'package:share_file_iai/constante.dart';

class MyContainerWidget extends StatefulWidget {
  @override
  _MyContainerWidgetState createState() => _MyContainerWidgetState();
}

class _MyContainerWidgetState extends State<MyContainerWidget> {
  int selectedIndex =
      -1; // Stocker l'index du container sélectionné (-1 signifie aucun)

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (index) {
        return GestureDetector(
          onTap: () {
            setState(() {
              selectedIndex =
                  index; // Met à jour l'index du container sélectionné
            });
          },
          child: Container(
            height: 30,
            padding:
                const EdgeInsets.only(left: 10, right: 10, top: 5, bottom: 5),
            margin: const EdgeInsets.only(left: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: selectedIndex == index
                  ? Colors.black
                  : Colors.black
                      .withOpacity(0.2), // Change la couleur si sélectionné
            ),
            child: Row(
              children: [
                const Icon(Icons.alarm),
                const SizedBox(width: 3),
                textPresentation(
                  msg: ' ouverte',
                  fontWeight: FontWeight.w300,
                  color: selectedIndex == index
                      ? Colors.white
                      : Colors.black.withOpacity(
                          0.4), // Change la couleur du texte si sélectionné
                  size: 9,
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
