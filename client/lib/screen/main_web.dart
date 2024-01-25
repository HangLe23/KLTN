import 'dart:async';

import 'package:client/index.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MainWeb extends StatefulWidget {
  const MainWeb({Key? key}) : super(key: key);

  @override
  State<MainWeb> createState() => _MainWebState();
}

class _MainWebState extends State<MainWeb> {
  List<String> fileList = [];
  int selectedIndex = 0;
  String? formattedDate;

  @override
  void initState() {
    super.initState();
    // Set giá trị mặc định cho selectedIndex là 0 (Home)
    selectedIndex = 0;

    Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      updateDateTime(); // Hàm cập nhật ngày giờ
    });
  }

  void updateDateTime() {
    setState(() {
      formattedDate = DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 75,
        backgroundColor: CustomColor.green50,
        flexibleSpace: Center(
          child: Row(
            children: [
              const SizedBox(width: 100),
              SearchWidget(
                  textedit: TextEditingController(),
                  hint: 'Search',
                  color: CustomColor.white,
                  function: (query) {}),
              const Spacer(),
              CustomIcons.timer,
              const SizedBox(width: 5),
              Text(formattedDate ?? '', // Hiển thị ngày giờ
                  style: TextStyles.inter15),
              IconButton(onPressed: () {}, icon: CustomIcons.notifiaction),
              const SizedBox(width: 50)
            ],
          ),
        ),
      ),
      backgroundColor: CustomColor.background,
      drawer: NavigationDrawer(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        backgroundColor: CustomColor.menu,
        indicatorColor: CustomColor.pink50,
        children: [
          const Padding(padding: EdgeInsets.all(75)),
          NavigationDrawerDestination(
              icon: CustomIcons.home,
              label: Text(
                "Home",
                style: TextStyles.menu,
              )),
          const SizedBox(height: 50),
          NavigationDrawerDestination(
              icon: CustomIcons.source,
              label: Text(
                "Sources",
                style: TextStyles.menu,
              )),
          const SizedBox(height: 50),
          NavigationDrawerDestination(
              icon: CustomIcons.node,
              label: Text(
                "Nodes",
                style: TextStyles.menu,
              )),
          const SizedBox(height: 50),
          NavigationDrawerDestination(
              icon: CustomIcons.monitoring,
              label: Text(
                "Monitoring",
                style: TextStyles.menu,
              )),
          const SizedBox(height: 50),
          NavigationDrawerDestination(
              icon: CustomIcons.setting,
              label: Text(
                "Setting",
                style: TextStyles.menu,
              ))
        ],
      ),
      body: IndexedStack(
        index: selectedIndex,
        children: const [
          HomeScreen(),
          SourceScreen(),
          NodeScreen(),
          MonitoringScreen(),
          SettingScreen(),
        ],
      ),
    );
  }
}
