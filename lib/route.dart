import 'package:flutter/material.dart';
import 'package:share_file_iai/screen/connexion/connexion_screnn.dart';
import 'package:share_file_iai/screen/inscription/InscriptionScreen.dart';
import 'package:share_file_iai/screen/mot_de_passe_oublie/forget.dart';
import 'package:share_file_iai/screen/spalshscreen/spalshScreen.dart';
import 'package:share_file_iai/screen/tags_management/tags_management_page.dart';
import 'package:share_file_iai/screen/search/search_by_tags_page.dart';
import 'package:share_file_iai/screen/tags_statistics/tag_statistics_page.dart';

final Map<String, WidgetBuilder> route = {
  SpalshScreen.routeName: (context) => const SpalshScreen(),
  InscriptionScreen.routeName: (context) => const InscriptionScreen(),
  ConnexionScreen.routeName: (context) => const ConnexionScreen(),
  ForgetScreen.routeName: (context) => const ForgetScreen(),
  '/tags-management': (context) => TagsManagementPage(),
  '/search-by-tags': (context) => SearchByTagsPage(),
  '/tags-statistics': (context) => TagStatisticsPage(),
};
