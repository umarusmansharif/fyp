import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final VoidCallback? onBackPress;

  const CustomAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.onBackPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: onBackPress != null
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: onBackPress,
            )
          : null,
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      actions: actions,
      elevation: 0,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}