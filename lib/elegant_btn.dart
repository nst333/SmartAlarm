import 'package:flutter/material.dart';
import 'dart:ui';

class GlassmorphismBtn extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const GlassmorphismBtn({
    Key? key,
    required this.text,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: const Color(0xFFF9DDA4).withOpacity(0.6),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.alarm, color: Colors.white, size: 20,),
                  const SizedBox(width: 8,),
                  Text(
                    text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  )
                ],
              ),
            ),
          ),
        )
      ),
    );
  }
}

class MinimalGoldBtn extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const MinimalGoldBtn({
    Key? key,
    required this.text,
    required this.onPressed
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFFF9DDA4),
        side: const BorderSide(color: Color(0xFFF9DDA4), width: 1.2),
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          letterSpacing: 2.0,
        ),
      ),
    );
  }
}

class SoftPastelGlowBtn extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const SoftPastelGlowBtn({
    Key? key,
    required this.text,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC0A2DE).withOpacity(0.5),
            blurRadius: 20,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFEBA6C6).withOpacity(0.8),
            const Color(0xFFC0A2DE).withOpacity(0.8),
          ],
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(25),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
