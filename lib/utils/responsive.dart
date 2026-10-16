import 'package:flutter/material.dart';

class Responsive {
  Responsive._();

  static const double mobileMaxWidth = 600;
  static const double tabletMaxWidth = 900;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobileMaxWidth;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tabletMaxWidth;
}