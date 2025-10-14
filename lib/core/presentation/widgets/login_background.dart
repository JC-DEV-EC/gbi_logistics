import 'package:flutter/material.dart';

class LoginBackground extends StatelessWidget {
  const LoginBackground({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base gradient background
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF4267B2), // Darker blue
                Color(0xFF7089B7), // Mid blue
              ],
            ),
          ),
        ),
        // Curved overlay
        CustomPaint(
          size: Size.infinite,
          painter: CurvedPainter(),
        ),
        // Large dark circle top-left
        Positioned(
          top: -50,
          left: -50,
          child: Container(
            width: 200,
            height: 200,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF305292),
            ),
          ),
        ),
        // Medium light circle top-right
        Positioned(
          top: 100,
          right: -20,
          child: Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF8DA1C5),
            ),
          ),
        ),
        // Small light circle middle-right
        Positioned(
          top: 250,
          right: 40,
          child: Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF8DA1C5),
            ),
          ),
        ),
        // Medium dark circle bottom-left
        Positioned(
          bottom: 50,
          left: -30,
          child: Container(
            width: 120,
            height: 120,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF305292),
            ),
          ),
        ),
        // Content
        child,
      ],
    );
  }
}

class CurvedPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF5679B6)
      ..style = PaintingStyle.fill;

    final path = Path();
    
    // Empezar desde la esquina superior derecha
    path.moveTo(size.width, 0);
    
    // Línea hacia abajo hasta 1/3 de la altura
    path.lineTo(size.width, size.height * 0.4);
    
    // Curva hacia la izquierda
    path.quadraticBezierTo(
      size.width * 0.7, // punto de control x
      size.height * 0.5, // punto de control y
      size.width * 0.5, // punto final x
      size.height * 0.6, // punto final y
    );
    
    // Segunda curva continuando hacia la izquierda
    path.quadraticBezierTo(
      size.width * 0.2, // punto de control x
      size.height * 0.7, // punto de control y
      0, // punto final x
      size.height * 0.8, // punto final y
    );
    
    // Completar el path
    path.lineTo(0, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
