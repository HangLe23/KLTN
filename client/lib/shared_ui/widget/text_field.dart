import 'package:client/index.dart';
import 'package:flutter/material.dart';

class TextFieldWidget extends StatelessWidget {
  final TextEditingController textedit;
  const TextFieldWidget({
    Key? key,
    required this.textedit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.height;
    return TextFormField(
      controller: textedit,
      decoration: InputDecoration(
        constraints: BoxConstraints(
          maxHeight: height * 0.065,
          maxWidth: width * 0.3,
        ),
        filled: true,
        fillColor: CustomColor.white,
        border: OutlineInputBorder(
          borderSide: BorderSide(color: CustomColor.black, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: CustomColor.black, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: CustomColor.black, width: 1),
        ),
      ),
    );
  }
}
