import 'dart:developer';

import 'package:client/screen/login.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import 'apis/index.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: const FirebaseOptions(
          apiKey: "AIzaSyAOZiMqKcTblfLqCX7BkHXoPuuEbWbokYk",
          authDomain: "kltn-32255.firebaseapp.com",
          projectId: "kltn-32255",
          storageBucket: "kltn-32255.appspot.com",
          messagingSenderId: "504635277327",
          appId: "1:504635277327:web:b0058287881e03d1b0e37a",
          measurementId: "G-ZLP2KMG8SE"));
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late IO.Socket socket;

  @override
  void initState() {
    log('listen...');
    connectAndListen();
    super.initState();
  }

  void connectAndListen() {
    IO.Socket socket = IO.io(BaseURLs.development.url,
        IO.OptionBuilder().setTransports(['websocket']).build());

    socket.onConnect((_) {
      print('connect');
      socket.emit('msg', 'test');
    });

    //When an event recieved from server, data is added to the stream
    //socket.on('event', (data) => streamSocket.addResponse);
    socket.onDisconnect((_) => print('disconnect'));
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Login(),
    );
  }
}
