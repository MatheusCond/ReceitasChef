import 'package:flutter/material.dart';
import './screens/login_screen.dart';
import './screens/foto_screen.dart';
import './screens/cadastro_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Receitas Chef',
      theme: ThemeData(
        primarySwatch: Colors.red,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => LoginScreen(),
        '/foto_screen': (context) => FotoScreen(),
        '/cadastro_screen': (context) => CadastroScreen(),
      },
    );
  }
}
