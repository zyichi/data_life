import 'package:flutter/material.dart';


String formFieldEmptyValidator(String text) {
  if (text.isEmpty) {
    return 'Can not be empty';
  } else {
    return null;
  }
}


class LabelFormField extends StatelessWidget {
  final String label;
  final EdgeInsets padding;

  const LabelFormField(
      {Key key,
      this.label,
      this.padding = EdgeInsets.zero})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.caption;
    return Padding(
      padding: padding,
      child: Text(
        label,
        style: labelStyle,
      ),
    );
  }
}

class LabeledTextFormField extends StatelessWidget {
  final String labelText;
  final String hintText;
  final TextEditingController controller;
  final FormFieldValidator<String> validator;
  final TextInputType inputType;
  final int maxLines;
  final bool enabled;

  LabeledTextFormField({
    Key key,
    this.labelText,
    this.hintText,
    this.controller,
    this.validator,
    this.inputType = TextInputType.text,
    this.maxLines = 1,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        LabelFormField(
          label: labelText,
          padding: EdgeInsets.zero,
        ),
        TextFormField(
          keyboardType: inputType,
          decoration: InputDecoration(
            hintText: hintText,
            border: InputBorder.none,
            isDense: true,
          ),
          maxLines: maxLines,
          controller: controller,
          validator: validator,
          enabled: enabled,
        )
      ],
    );
  }
}