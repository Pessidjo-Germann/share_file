import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:share_file_iai/widget/toast_service.dart';

class AuthControler {
  Future<void> signIn(
      String email, String password, BuildContext context) async {
    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Gérer la connexion réussie
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        ToastService.errorMessage(
            'Aucun utilisateur trouvé pour cet email.', context);
      } else if (e.code == 'wrong-password') {
        ToastService.errorMessage('Mot de passe incorrect.', context);
      }
    }
  }

  Future<void> createAccount(
      String email, String password, BuildContext context) async {
    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Gérer la création réussie
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        ToastService.errorMessage('Le mot de passe est trop faible.', context);
      } else if (e.code == 'email-already-in-use') {
        ToastService.errorMessage(
            'Un compte existe déjà pour cet email.', context);
      }
    } catch (e) {
      ToastService.errorMessage(e.toString(), context);
    }
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }
}
