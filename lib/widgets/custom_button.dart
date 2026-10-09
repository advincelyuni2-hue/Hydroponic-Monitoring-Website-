import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final TextStyle textStyle;
  final VoidCallback? onPressed;
  final double? width;
  final double height;
  final bool outlined;
  final bool isLoading;

  const CustomButton({
    super.key,
    required this.text,
    required this.backgroundColor,
    required this.textStyle,
    required this.onPressed,
    this.isLoading = false,
    this.width,
    this.height = 56,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: outlined ? Colors.transparent : backgroundColor,
          foregroundColor: outlined ? backgroundColor : textStyle.color,
          side: outlined ? BorderSide(color: backgroundColor) : null,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: isLoading
    ? SizedBox(
        height: 22,
        width: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: outlined ? backgroundColor : Colors.white,
        ),
      )
    : Text(text, style: textStyle),
      ),
    );
  }
}
