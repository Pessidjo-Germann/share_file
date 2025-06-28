import 'package:flutter/material.dart';
import 'package:share_file_iai/constante.dart';
import 'package:share_file_iai/screen/home_screen/components/create_folder.dart';
import 'package:svg_flutter/svg.dart';

import 'box_document.dart';
import 'container_widget.dart';

class Body extends StatefulWidget {
  final String name;
  const Body({super.key, required this.name});

  @override
  State<Body> createState() => _BodyState();
}

class _BodyState extends State<Body> {
  @override
  Widget build(BuildContext context) {
    int pageIndex = 0;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const SizedBox(height: 20),
                  textPresentation(
                      msg: 'Hello ',
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                      size: 24),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.notifications), // Icône de notification
                    onPressed: () {
                      // Action à réaliser lorsque l'utilisateur clique sur l'icône
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Aucune notification')),
                      );
                      // Ou naviguer vers une page de notifications
                      // Navigator.push(context, MaterialPageRoute(builder: (context) => NotificationsPage()));
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              textPresentation(
                  maxLine: 2,
                  textAlign: TextAlign.start,
                  msg: 'Bienvenue dans votre \nEspace de travail.',
                  fontWeight: FontWeight.w200,
                  color: Colors.black,
                  size: 25),
              const SizedBox(height: 10),
              textPresentation(
                  msg: 'Créer un nouvel elément',
                  color: Colors.black,
                  fontWeight: FontWeight.normal,
                  textAlign: TextAlign.start,
                  size: 17),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                      child: BoxDocument(
                    file: 'assets/images/file.png',
                    message2: 'file',
                    message: 'Fichier',
                    press: () {},
                  )),
                  Expanded(
                      child: BoxDocument(
                    file: 'assets/images/folder.png',
                    message2: 'document',
                    message: 'Documents',
                    press: () {
                      _showCreateFolderModal(context);
                    },
                  )),
                ],
              ),
              const SizedBox(height: 20),
              textPresentation(
                  msg: 'Accès rapide',
                  fontWeight: FontWeight.bold,
                  size: 16,
                  color: kColorBlack),
              MyContainerWidget(),
              const SizedBox(height: 30),
              Container(
                width: double.infinity,

                color: Colors.white70, // Couleur par défaut
                child: Column(
                  children: [
                    SvgPicture.asset('assets/icons/people_light_msa.svg'),
                    const SizedBox(height: 30),
                    textPresentation(
                        msg: 'Aucun element partage',
                        fontWeight: FontWeight.bold,
                        size: 16,
                        color: kColorBlack),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateFolderModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled:
          true, // Pour permettre à la modal de prendre plus d'espace
      builder: (BuildContext context) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets, // Gérer le clavier
          child: CreateFolderForm(),
        );
      },
    );
  }
}
