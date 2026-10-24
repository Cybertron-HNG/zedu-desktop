import 'package:flutter/material.dart';

Widget buildTestMaterialApp(Widget child, {ThemeData? theme}) {
  return MaterialApp(
    theme: theme,
    home: child,
  );
}
