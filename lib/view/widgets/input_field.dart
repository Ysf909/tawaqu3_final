import 'package:flutter/material.dart';

class InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscure;
  const InputField({super.key, required this.controller, required this.label, this.obscure=false});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(labelText: label, suffixIcon: obscure ? const Icon(Icons.visibility) : null),
    );
  }
}

