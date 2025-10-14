// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:logiruta/main.dart';
import 'package:logiruta/features/logistics/screens/login_screen.dart';

void main() {
  group('Integration Tests', () {
    testWidgets('App starts with login screen', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Verify that we're on the login screen
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('GBI Logistics'), findsOneWidget);
      expect(find.text('Iniciar Sesión'), findsOneWidget);
    });

    testWidgets('Login screen has required fields', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Verify login form elements
      expect(find.byType(TextFormField), findsNWidgets(2)); // Usuario y contraseña
      expect(find.byType(FilledButton), findsOneWidget); // Botón de login
      expect(find.text('Ingresar'), findsOneWidget);
    });

    testWidgets('Login form validation works', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Intentar login sin datos
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      // Verificar mensajes de validación
      expect(find.text('Por favor ingrese su usuario'), findsOneWidget);
      expect(find.text('Por favor ingrese su contraseña'), findsOneWidget);
    });

    testWidgets('Password visibility toggle works', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Verificar que el botón de visibilidad existe
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      
      // Tocar el botón de visibilidad
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pumpAndSettle();
      
      // Verificar que el icono cambió
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
      expect(find.byIcon(Icons.visibility_outlined), findsNothing);
    });
  });
}
