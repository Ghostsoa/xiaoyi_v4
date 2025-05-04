import 'package:flutter/material.dart';

abstract class BaseFormatter {
  Widget format(BuildContext context, String text, TextStyle baseStyle);
  TextStyle getStyle(TextStyle baseStyle);
}
