import 'dart:convert';
import 'dart:developer';

import 'package:client/index.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';

class Login extends StatelessWidget {
  const Login({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final formKey = GlobalKey<FormState>();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColor.white,
      body: Row(
        children: [
          Expanded(
            flex: 1,
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/sdr_logo.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'LOGIN WITH ADMIN ACCOUNT',
                      style: TextStyles.tittleLogin,
                    ),
                    const SizedBox(height: 75),
                    Row(
                      children: [
                        const SizedBox(width: 275),
                        Text('Username', style: TextStyles.titleTable),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: 350,
                      child: TextFormField(
                        controller: usernameController,
                        decoration: InputDecoration(
                          hintText: 'Enter your username',
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 15.0, horizontal: 20.0),
                          hintStyle: TextStyles.textTable,
                          border: const UnderlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your username';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 50),
                    Row(
                      children: [
                        const SizedBox(width: 275),
                        Text('Password', style: TextStyles.titleTable),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: 350,
                      child: TextFormField(
                        controller: passwordController,
                        decoration: InputDecoration(
                          hintText: 'Enter your password',
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 15.0, horizontal: 20.0),
                          hintStyle: TextStyles.textTable,
                          border: const UnderlineInputBorder(),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 50),
                    MaterialButton(
                      onPressed: () {
                        login(usernameController.text, passwordController.text);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          color: CustomColor.purple,
                        ),
                        width: 350,
                        height: 40,
                        child: const Center(
                          child: Text(
                            "LOGIN",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> login(String username, String password) async {
    if (formKey.currentState!.validate()) {
      username = usernameController.text;
      password = passwordController.text;
      final String hashedPassword =
          sha1.convert(utf8.encode(password)).toString();
      try {
        DocumentSnapshot adminDoc = await FirebaseFirestore.instance
            .collection('User')
            .doc('admin')
            .get();

        if (adminDoc.exists) {
          String storedUsername = adminDoc.get('username');
          String storedPassword = adminDoc.get('Password');
          log(storedPassword);
          if (username == storedUsername && hashedPassword == storedPassword) {
            // ignore: use_build_context_synchronously
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MainWeb()),
            );
          } else {
            // ignore: use_build_context_synchronously
            showErrorDialog(context, 'Incorrect username or password');
          }
        } else {
          // ignore: use_build_context_synchronously
          showErrorDialog(context, 'Admin account not found');
        }
      } catch (e) {
        // ignore: use_build_context_synchronously
        showErrorDialog(context, 'Error logging in: $e');
      }
    }
  }

  void showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Login Error'),
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.red),
              const SizedBox(width: 10),
              Flexible(child: Text(message)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
