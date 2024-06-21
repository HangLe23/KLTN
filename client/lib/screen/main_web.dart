import 'dart:async';

import 'package:client/apis/index.dart';
import 'package:client/index.dart';
import 'package:client/screen/notification_list.dart';
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
  @override
  void initState() {
    super.initState();
    // Set giá trị mặc định cho selectedIndex là 0 (Home)
    selectedIndex = 0;
    initSocket();

    Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      updateDateTime(); // Hàm cập nhật ngày giờ
    });
  }

  void initSocket() {
    socket = IO.io(BaseURLs.development.url, <String, dynamic>{
      'transports': ['websocket'],
    });

    // socket?.on('connect', (_) {
    //   print('Connected to Socket.IO server');
    // });

    // Lắng nghe các sự kiện

    socket?.on('fileUploaded', (data) {
      setState(() {
        notificationCount++;
      });
    });

    // socket?.on('infoMessage', (data) {
    //   // Xử lý sự kiện infoMessage
    //   setState(() {
    //     notificationCount++; // Tăng biến đếm thông báo
    //   });
    // });

    socket?.on('downloadProgress', (data) {
      // Xử lý sự kiện downloadProgress
      setState(() {
        notificationCount++; // Tăng biến đếm thông báo
      });
    });

    // socket.on('disconnect', (_) {
    //   print('Disconnected from Socket.IO server');
    // });
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
        toolbarHeight: MediaQuery.of(context).size.height * 0.11,
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
              //IconButton(onPressed: () {}, icon: CustomIcons.notifiaction),
              Stack(
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        // Đảo ngược trạng thái của biến cờ khi nhấn vào biểu tượng thông báo
                        showNotifications = !showNotifications;
                        // Đặt lại biến đếm thông báo khi mở danh sách
                        if (showNotifications) {
                          notificationCount = 0;
                        }
                      });
                    },
                    icon: CustomIcons.notifiaction,
                  ),
                  if (notificationCount > 0)
                    Positioned(
                      right: 11,
                      top: 11,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          '$notificationCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 50)
            ],
          ),
        ),
      ),
      backgroundColor: CustomColor.white,
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
                "Devices",
                style: TextStyles.menu,
              )),
          const SizedBox(height: 50),
          // NavigationDrawerDestination(
          //     icon: CustomIcons.monitoring,
          //     label: Text(
          //       "Monitoring",
          //       style: TextStyles.menu,
          //     )),
          // const SizedBox(height: 50),
          // NavigationDrawerDestination(
          //     icon: CustomIcons.setting,
          //     label: Text(
          //       "Setting",
          //       style: TextStyles.menu,
          //     ))
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: selectedIndex,
              children: const [
                HomeScreen(),
                SourceScreen(),
                NodeScreen(),
                //MonitoringScreen(),
                //SettingScreen(),
              ],
            ),
          ),
          if (showNotifications && notifications.isNotEmpty)
            Expanded(
              child: NotificationList(notifications: notifications),
            ),
        ],
      ),
    );
  }
}
