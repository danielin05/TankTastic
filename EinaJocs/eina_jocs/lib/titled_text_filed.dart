import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class TitledTextfield extends StatefulWidget {
  final String title;
  final TextEditingController? controller;
  final String? placeholder;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int? maxLines;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final TextStyle? textStyle;
  final TextStyle? placeholderStyle;
  final EdgeInsetsGeometry? padding;
  final BoxDecoration? decoration;
  final bool autofocus;
  final TextAlign textAlign;
  final bool enabled;

  const TitledTextfield({
    super.key,
    required this.title,
    this.controller,
    this.placeholder,
    this.keyboardType,
    this.obscureText = false,
    this.maxLines = 1,
    this.maxLength,
    this.onChanged,
    this.textStyle,
    this.placeholderStyle,
    this.padding,
    this.decoration,
    this.autofocus = false,
    this.textAlign = TextAlign.start,
    this.enabled = true,
  });

  @override
  TitledTextfieldState createState() => TitledTextfieldState();
}

class TitledTextfieldState extends State<TitledTextfield> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4.0),
          child: Text(
            widget.title,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        CupertinoTextField(
          controller: widget.controller,
          placeholder: widget.placeholder,
          keyboardType: widget.keyboardType,
          obscureText: widget.obscureText,
          maxLines: widget.maxLines,
          maxLength: widget.maxLength,
          onChanged: widget.onChanged,
          style: widget.textStyle ?? const TextStyle(fontSize: 14),
          placeholderStyle: widget.placeholderStyle ??
              const TextStyle(fontSize: 12, color: Colors.grey),
          padding: widget.padding ??
              const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
          //decoration: widget.decoration,
          autofocus: widget.autofocus,
          textAlign: widget.textAlign,
          enabled: widget.enabled,
        ),
      ],
    );
  }
}
