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
              icon: Icon(
                Icons.arrow_back,
                color: Theme.of(context).colorScheme.primary,
              ),
              onPressed: onBackPress,
            )
          : null,
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge!.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      actions: actions,
      elevation: 0,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}