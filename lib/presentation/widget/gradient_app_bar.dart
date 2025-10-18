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
        backgroundColor: const Color.fromARGB(0, 235, 238, 36),
        elevation: 0,
        title: Text(
          title,
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: fs ?? 30,
            fontVariations: const [FontVariation('wght', 800)],
            color: const Color.fromARGB(255, 231, 231, 34),
          ),
        ),
        centerTitle: true,
      ),
    );
  }
}
