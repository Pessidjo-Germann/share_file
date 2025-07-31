import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'package:share_file_iai/main.dart';
import 'package:share_file_iai/screen/AccountSettings/accout_setting_page.dart';
import 'package:share_file_iai/screen/category_folders/category_folders_page.dart';
import 'package:share_file_iai/screen/share_page/share_page.dart';
import 'package:share_file_iai/widget/root_app_json.dart';
import 'package:svg_flutter/svg.dart';
import 'components/body.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.user});
  final User user;
  static String routeName = "/home";

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();

    // Appel de la fonction pour demander la permission de notification
    requestNotificationPermission();

    // Configurer les notifications reçues en premier plan
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Message reçu en premier plan: ${message.notification?.title}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message.notification?.body ?? 'Notification reçue'),
          ),
        );
      }
    });
  }

  int pageIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: getBody(widget.user.uid, "HU"),
      bottomNavigationBar: getTabs(),
    );
  }

  Widget getBody(String userId, String name) {
    return IndexedStack(
      index: pageIndex,
      children: [
        Body(
          name: name,
        ),
        CategoryFoldersPage(),
        // FolderListPage(),
        SharedFoldersPage(),
        AccountSettingsPage()
      ],
    );
  }

  Widget getTabs() {
    return SalomonBottomBar(
        currentIndex: pageIndex,
        onTap: (index) {
          setState(() {
            pageIndex = index;
          });
        },
        items: List.generate(rootAppJson.length, (index) {
          return SalomonBottomBarItem(
              selectedColor: rootAppJson[index]['color'],
              icon: SvgPicture.asset(
                rootAppJson[index]['icon'],
                color: rootAppJson[index]['color'],
              ),
              title: Text(rootAppJson[index]['text']));
        }));
  }
}
