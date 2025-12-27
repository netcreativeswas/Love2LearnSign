import 'package:flutter/material.dart';
import '../theme.dart';

class CustomSearchBar extends StatelessWidget {
  final String hintText;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final FocusNode? focusNode;

  const CustomSearchBar({
    super.key,
    required this.hintText,
    required this.controller,
    required this.onChanged,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        focusNode: focusNode,
        decoration: InputDecoration(
          labelStyle: TextStyle(
            color: Theme.of(context).hintColor.withValues(alpha: 0.5),
          ),
          labelText: hintText,
          // Remove labelStyle to prevent conflicts with floatingLabelStyle
          floatingLabelStyle: TextStyle(color: Theme.of(context).colorScheme.surface),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface3,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
            borderRadius: BorderRadius.circular(20),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
            borderRadius: BorderRadius.circular(20),
          ),
          prefixIcon: Icon(Icons.search, color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.5)),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                   icon: Icon(Icons.clear, color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.5)),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                )
              : null,
        ),
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}