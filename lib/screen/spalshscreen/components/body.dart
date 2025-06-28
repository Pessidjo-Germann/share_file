import 'package:flutter/material.dart';
import 'package:share_file_iai/screen/inscription/InscriptionScreen.dart';
import 'package:share_file_iai/widget/bouton_continuer.dart';

import 'spalshcontent.dart';

class Body extends StatefulWidget {
  const Body({super.key});

  @override
  State<Body> createState() => _BodyState();
}

class _BodyState extends State<Body> {
  int currentIndex = 0;
  List<Map<String, String>> splashData = [
    {
      "img": "assets/images/9894285.jpg",
      "text":
          """Bienvenue dans votre application de partage"""
    },
    {
      "img": "assets/images/folder.png",
      "text": "Partagez vos dossiers en toute sécurité!"
    },
    {
      "img": "assets/images/file_document.png",
      "text":
          """Vos documents seront sauvegardés! """
    },
   
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(left: 15, right: 15),
        child: Center(
          child: Column(
            children: [
              Expanded(
                flex: 3,
                child: PageView.builder(
                    onPageChanged: (value) {
                      setState(() {
                        currentIndex = value;
                      });
                    },
                    itemCount: splashData.length,
                    itemBuilder: (((context, index) => SpalshContent(
                          img: splashData[index]['img']!,
                          text: splashData[index]['text']!,
                        )))),
              ),
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      splashData.length,
                      (index) => buildDot(index: index),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 10),
              BoutonContinuer(
                size: size,
                press: () {
                  Navigator.pushReplacementNamed(context, InscriptionScreen.routeName);
                },
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  AnimatedContainer buildDot({required int index}) {
    return AnimatedContainer(
      duration: const Duration(seconds: 1),
      margin: const EdgeInsets.all(4),
      height: 6,
      width: currentIndex == index ? 26 : 6,
      decoration: BoxDecoration(
        color: currentIndex == index
            ? const Color.fromARGB(255, 51, 51, 61)
            : const Color(0xFFD8D8D8),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}
