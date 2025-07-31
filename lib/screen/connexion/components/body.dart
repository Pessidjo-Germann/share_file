import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:share_file_iai/screen/inscription/InscriptionScreen.dart';
import 'package:share_file_iai/screen/inscription/components/email_input.dart';
import 'package:share_file_iai/screen/inscription/components/psd_input.dart';
import 'package:share_file_iai/widget/bouton_continuer_2.dart';
import 'package:share_file_iai/widget/toast_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../constante.dart';
import '../../inscription/components/body.dart';

class Body extends StatefulWidget {
  const Body({super.key});

  @override
  State<Body> createState() => _BodyState();
}

class _BodyState extends State<Body> {
  final TextEditingController emailController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController psdController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    Future<void> _signIn() async {
      setState(() {
        _isLoading = true;
      });

      try {
        await _auth.signInWithEmailAndPassword(
          email: emailController.text,
          password: psdController.text,
        );
        // Connexion réussie
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isConnect', true);
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Connexion reussite')));

        // La redirection est maintenant gérée par le StreamBuilder dans main.dart
      } on FirebaseAuthException catch (e) {
        if (!mounted) return;
        String errorMessage = 'Une erreur est survenue.';
        if (e.code == 'user-not-found') {
          errorMessage = 'Aucun utilisateur trouvé pour cet email.';
        } else if (e.code == 'wrong-password') {
          errorMessage = 'Mot de passe incorrect.';
        } else if (e.code == 'invalid-email') {
          errorMessage = 'L\'adresse email n\'est pas valide.';
        }
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(errorMessage)));
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }

    return SafeArea(
      child: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(left: 28, right: 28),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Image.asset("assets/images/icon_logo.jpg"),
                const SizedBox(height: 90),
                const Text(
                  "Welcome Back",
                  textScaleFactor: 2.3,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  "Utilise ton email et ton mot de passe",
                  style: TextStyle(
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 60),
                Form(
                  key: formKey,
                  child: Column(
                    children: [
                      EmailInput(
                        label: "Entrer votre email",
                        controller: emailController,
                      ),
                      const SizedBox(height: 20),
                      PassWordInput(
                          label: "Entrer votre mot de passe",
                          controller: psdController),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          const Spacer(),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(context, "/forget");
                            },
                            child: const Text(
                              "Mot de passe oublié ?",
                              style: TextStyle(
                                fontSize: 17,
                                color: kprimaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 50),
                      _isLoading
                          ? const CircularProgressIndicator()
                          : BottonContinuer2(
                              size: size,
                              press: () {
                                if (formKey.currentState!.validate()) {
                                  _signIn();
                                }
                              },
                              name: 'Connectez-vous',
                            ),
                      const SizedBox(height: 24),
                      RowAction(
                        label: "Pas encore de compte ?",
                        label2: "Creez-en-un",
                        press: () {
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const InscriptionScreen()));
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
