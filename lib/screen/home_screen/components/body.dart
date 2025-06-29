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
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF8F9FA),
              Color(0xFFE9ECEF),
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                // Header moderne avec avatar et actions
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                        ),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          textPresentation(
                            msg: 'Hello ${widget.name}!',
                            color: const Color(0xFF2D3436),
                            fontWeight: FontWeight.w600,
                            size: 24,
                          ),
                          textPresentation(
                            msg: 'Bon retour sur GEDAH',
                            color: const Color(0xFF636E72),
                            fontWeight: FontWeight.w400,
                            size: 14,
                          ),
                        ],
                      ),
                    ),
                    // Actions modernes
                    _buildActionButton(
                      icon: Icons.search,
                      color: const Color(0xFF0984e3),
                      onPressed: () {
                        Navigator.pushNamed(context, '/search-by-tags');
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      icon: Icons.label,
                      color: const Color(0xFFe17055),
                      onPressed: () {
                        Navigator.pushNamed(context, '/tags-management');
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      icon: Icons.notifications,
                      color: const Color(0xFF00b894),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Aucune notification')),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                // Section bienvenue modernisée
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      textPresentation(
                        msg: 'Bienvenue dans votre',
                        fontWeight: FontWeight.w300,
                        color: Colors.white,
                        size: 22,
                      ),
                      textPresentation(
                        msg: 'Espace de travail',
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(height: 10),
                      textPresentation(
                        msg: 'Gérez vos documents en toute simplicité',
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withOpacity(0.9),
                        size: 16,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                textPresentation(
                  msg: 'Créer un nouvel élément',
                  color: const Color(0xFF2D3436),
                  fontWeight: FontWeight.w600,
                  textAlign: TextAlign.start,
                  size: 20,
                ),
                const SizedBox(height: 20),
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
                const SizedBox(height: 30),
                textPresentation(
                  msg: 'Accès rapide',
                  fontWeight: FontWeight.w600,
                  size: 18,
                  color: const Color(0xFF2D3436),
                ),
                const SizedBox(height: 15),
                MyContainerWidget(),
                const SizedBox(height: 30),
                // Section partage modernisée
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: Center(
                          child: SvgPicture.asset(
                            'assets/icons/people_light_msa.svg',
                            width: 40,
                            height: 40,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      textPresentation(
                        msg: 'Aucun élément partagé',
                        fontWeight: FontWeight.w600,
                        size: 18,
                        color: const Color(0xFF2D3436),
                      ),
                      const SizedBox(height: 8),
                      textPresentation(
                        msg:
                            'Commencez à partager des fichiers avec votre équipe',
                        fontWeight: FontWeight.w400,
                        size: 14,
                        color: const Color(0xFF636E72),
                        textAlign: TextAlign.center,
                        maxLine: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 20),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
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
