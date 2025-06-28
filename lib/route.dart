import 'package:flutter/material.dart';
import 'package:share_file_iai/screen/connexion/connexion_screnn.dart';
import 'package:share_file_iai/screen/home_screen/home_screen.dart';
import 'package:share_file_iai/screen/inscription/InscriptionScreen.dart';
import 'package:share_file_iai/screen/mot_de_passe_oublie/forget.dart';
import 'package:share_file_iai/screen/spalshscreen/spalshScreen.dart';

final Map<String, WidgetBuilder> route = {
  SpalshScreen.routeName: (context) => const SpalshScreen(),
  InscriptionScreen.routeName: (context) => const InscriptionScreen(),
  ConnexionScreen.routeName: (context) => const ConnexionScreen(),
  ForgetScreen.routeName: (context) => const ForgetScreen(),
  HomeScreen.routeName: (context) => const HomeScreen(),
};
