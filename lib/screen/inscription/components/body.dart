import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:share_file_iai/constante.dart';
import 'package:share_file_iai/screen/connexion/connexion_screnn.dart';
import 'package:share_file_iai/screen/inscription/components/confirm_password.dart';
import 'package:share_file_iai/screen/inscription/components/psd_input.dart';
import 'package:share_file_iai/widget/bouton_continuer_2.dart';
import 'package:share_file_iai/widget/toast_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'email_input.dart';

class Body extends StatefulWidget {
  const Body({super.key});

  @override
  State<Body> createState() => _BodyState();
}

class _BodyState extends State<Body> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController psdController = TextEditingController();
  final TextEditingController newPsdController = TextEditingController();

  final globalKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    Future<void> _createAccount() async {
      setState(() {
        _isLoading = true; // Démarrer l'animation de chargement
      });

      try {
        UserCredential userCredential =
            await _auth.createUserWithEmailAndPassword(
          email: emailController.text,
          password: psdController.text,
        );
        await FirebaseFirestore.instance.collection('users').add({
          'name': newPsdController.text,
          'id': userCredential.user!.uid,
          'createdAt':
              FieldValue.serverTimestamp(), // Timestamp pour trier les dossiers
        });
        // Compte créé avec succès
        // Une fois connecté, on met isConnect à true
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isConnect', true);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Inscription réussite')));

        // Redirection vers l'écran principal
        Navigator.pushReplacementNamed(context, '/home');
      } on FirebaseAuthException catch (e) {
        if (e.code == 'weak-password') {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Le mot de passe est trop faible.')));
        } else if (e.code == 'email-already-in-use') {
          //  print('Un compte existe déjà pour cet email.');
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Un compte existe déjà pour cet email.')));
        }
      } catch (e) {
        ToastService.errorMessage(e.toString(), context);
      } finally {
        setState(() {
          _isLoading = false; // Arrêter l'animation de chargement
        });
      }
    }

    final size = MediaQuery.of(context).size;

    return SingleChildScrollView(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 28, right: 28),
          child: Center(
            child: Form(
              key: globalKey,
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Image.asset("assets/images/icon_logo.jpg"),
                  const SizedBox(height: 90),
                  const Text(
                    "Register Account",
                    textScaleFactor: 2.3,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    "Entrez vos informations",
                    style: TextStyle(
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 60),
                  Form(
                      //key: globalKey,
                      child: Column(
                    children: [
                      EmailInput(
                        label: "Entrer votre email",
                        controller: emailController,
                      ),
                      const SizedBox(height: 20),
                      PassWordInput(
                        label: 'Entrer votre mot de passe',
                        controller: psdController,
                      ),
                      const SizedBox(height: 20),
                      ConfirmInput(
                        controller: newPsdController,
                        label: 'Entrer votre nom',
                      ),
                      const SizedBox(height: 10),
                    ],
                  )),
                  const Row(
                    children: [
                      Spacer(),
                    ],
                  ),
                  const SizedBox(height: 100),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : BottonContinuer2(
                          size: size,
                          press: () {
                            if (globalKey.currentState!.validate()) {
                              _createAccount();
                            }
                          },
                          name: 'S\'inscrire',
                        ),
                  const SizedBox(height: 18),
                  RowAction(
                    label: "Déjà un compte ?",
                    label2: "Connectez-vous ",
                    press: () {
                      Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const ConnexionScreen()));
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RowAction extends StatelessWidget {
  const RowAction({
    super.key,
    required this.label,
    required this.label2,
    required this.press,
  });
  final String label, label2;
  final GestureCancelCallback press;
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 17,
          ),
        ),
        const SizedBox(width: 7),
        GestureDetector(
          onTap: press,
          child: Text(
            label2,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: kprimaryColor,
            ),
          ),
        ),
      ],
    );
  }
}
