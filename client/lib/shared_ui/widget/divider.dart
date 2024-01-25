import 'package:client/index.dart';
import 'package:flutter/material.dart';

class DividerWidget extends StatelessWidget {
  const DividerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      width: 200,
      margin: const EdgeInsets.all(20),
      color: CustomColor.menu,
    );
  }
}
