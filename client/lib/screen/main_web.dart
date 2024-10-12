import 'dart:async';

import 'package:client/index.dart';
import 'package:client/screen/login.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class MainWeb extends StatefulWidget {
  const MainWeb({Key? key}) : super(key: key);

  @override
  State<MainWeb> createState() => _MainWebState();
}

class _MainWebState extends State<MainWeb> {
  List<String> fileList = [];
  int selectedIndex = 0;
  String? formattedDate;
  int notificationCount = 0;
  List<String> notifications = [];
  IO.Socket? socket;
  bool showNotifications = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    selectedIndex = 0;
    updateDateTime(); // Call updateDateTime once in initState
    // Start periodic timer to update date time
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      updateDateTime();
    });
  }

  @override
  void dispose() {
    // Cancel the timer when the widget is disposed
    _timer?.cancel();
    super.dispose();
  }

  void updateDateTime() {
    if (mounted) {
      setState(() {
        formattedDate =
            DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now());
      });
    }
  }

  void logout() {
    // Perform logout actions here (if any)
    // Navigate back to the login screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const Login()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: MediaQuery.of(context).size.height * 0.11,
        backgroundColor: CustomColor.green50,
        flexibleSpace: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CustomIcons.timer,
              const SizedBox(width: 5),
              Text(formattedDate ?? '', style: TextStyles.inter15),
              const SizedBox(width: 50),
            ],
          ),
        ),
      ),
      backgroundColor: CustomColor.white,
      drawer: NavigationDrawer(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          if (index == 2) {
            logout(); // Logout when index is 2 (Logout menu item)
          } else {
            setState(() {
              selectedIndex = index;
            });
          }
        },
        backgroundColor: CustomColor.white,
        indicatorColor: CustomColor.pink50,
        children: [
          const Padding(padding: EdgeInsets.all(50)),
          const CircleAvatar(
            backgroundColor: Colors.transparent,
            backgroundImage:
                AssetImage('assets/images/sbcf-default-avatar.png'),
            radius: 125,
          ),
          Center(
            child: Text(
              'ADMIN',
              style: TextStyles.titleTable,
            ),
          ),
          const SizedBox(height: 75),
          NavigationDrawerDestination(
            icon: CustomIcons.source,
            label: Text(
              "Files Services",
              style: TextStyles.menu,
            ),
          ),
          const SizedBox(height: 50),
          NavigationDrawerDestination(
            icon: CustomIcons.node,
            label: Text(
              "Devices",
              style: TextStyles.menu,
            ),
          ),
          const SizedBox(height: 50),
          NavigationDrawerDestination(
            icon: CustomIcons.loguout,
            label: Text(
              "Log out",
              style: TextStyles.menu,
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: selectedIndex,
        children: const [
          SourceScreen(),
          NodeScreen(),
        ],
      ),
    );
  }
}
