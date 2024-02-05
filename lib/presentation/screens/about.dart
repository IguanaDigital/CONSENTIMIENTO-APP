import 'package:flutter/material.dart';

class About extends StatefulWidget {
  const About({super.key});

  @override
  State<About> createState() => _AboutState();
}

class _AboutState extends State<About> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
          child: Column(
        children: [
          Image.asset(
            'assets/image/logo-reybanpac 1.png',
            scale: 1,
          ),
          Text('Todos los derechos reservados a REYBANPAC 2023 ©.')
        ],
      )),
    );
  }
}
