import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:share_file_iai/constante.dart';
import 'package:share_file_iai/controller/auth_controler.dart';
import 'package:share_file_iai/screen/connexion/connexion_screnn.dart';
import 'package:share_file_iai/screen/inscription/components/confirm_password.dart';
import 'package:share_file_iai/screen/inscription/components/psd_input.dart';

import 'package:share_file_iai/widget/primary_button.dart';
import 'package:share_file_iai/widget/toast_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

#import 'package:share_file_iai/widget/bouton_continuer_2.dart';


import 'email_input.dart';

class Body extends StatefulWidget {
  const Body({super.key});

  @override
  State<Body> createState() => _BodyState();
}

class _BodyState extends State<Body> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController psdController = TextEditingController();
  final TextEditingController newPsdController = TextEditingController();

  final globalKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    Future<void> _createAccount() async {
      setState(() {
        _isLoading = true;
      });

      await AuthControler().createAccount(
        emailController.text,
        psdController.text,
        newPsdController.text, // this is the name
        context,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
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
                  const SizedBox(height: 50),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : PrimaryButton(
                          press: () {
                            if (globalKey.currentState!.validate()) {
                              _createAccount();
                            }
                          },
                          name: 'S\'inscrire',
                        ),
                  const SizedBox(height: 24),
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
