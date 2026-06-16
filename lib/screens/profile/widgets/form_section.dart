import 'package:flutter/material.dart';

class FormFieldData {
  final String label;
  final TextEditingController controller;
  final int maxLines;
  final int? maxLength;
  final TextInputType keyboardType;

  const FormFieldData({
    required this.label,
    required this.controller,
    this.maxLines = 1,
    this.maxLength,
    this.keyboardType = TextInputType.text,
  });
}

class FormSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<FormFieldData> fields;
  final Widget? trailing;

  const FormSection({
    super.key,
    required this.icon,
    required this.title,
    required this.fields,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitle(),
          const SizedBox(height: 14),
          ...fields.map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _FormField(data: f),
          )),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF3A7D5A), size: 20),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _FormField extends StatelessWidget {
  final FormFieldData data;
  const _FormField({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(data.label, style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
        const SizedBox(height: 5),
        TextField(
          controller: data.controller,
          maxLines: data.maxLines,
          maxLength: data.maxLength,
          keyboardType: data.keyboardType,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF3A7D5A)),
            ),
            counterText: data.maxLength != null ? null : '',
          ),
        ),
      ],
    );
  }
}
