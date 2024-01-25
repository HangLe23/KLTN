import 'package:client/index.dart';
import 'package:flutter/material.dart';

class TextStyles {
  TextStyles._();
  static TextStyle tittle = TextStyle(
      fontFamily: 'Lato',
      fontWeight: FontWeight.bold,
      fontSize: 30,
      color: CustomColor.white);
  static TextStyle dashboard = TextStyle(
      fontFamily: 'Lato',
      fontWeight: FontWeight.bold,
      fontSize: 50,
      color: CustomColor.white);
  static TextStyle menu = TextStyle(
      fontFamily: 'Lato',
      fontWeight: FontWeight.w200,
      fontSize: 20,
      color: CustomColor.white);
  static TextStyle searchtext = TextStyle(
      fontFamily: 'Lato',
      fontWeight: FontWeight.w200,
      fontSize: 15,
      color: CustomColor.black);
  static TextStyle inter15 = TextStyle(
      fontFamily: 'Inter',
      fontWeight: FontWeight.normal,
      fontSize: 15,
      color: CustomColor.white);
}
