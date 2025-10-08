import 'package:flutter/material.dart';

class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final double? fs;

  const GradientAppBar({
    super.key,
    required this.title,
    this.fs,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue, Colors.purple, Colors.red],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.3),
            offset: Offset(0, 4),
            blurRadius: 3,
          ),
        ],
      ),
      child: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          title,
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: fs ?? 30,
            fontWeight: FontWeight.bold,
            color: const Color.fromARGB(252, 246, 243, 174),
          ),
        ),
        centerTitle: true,
      ),
    );
  }
}
