import 'package:flutter/material.dart';
//loading Screen
class SplashScreen extends StatelessWidget{
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('alex chat'),),
      body: const Center(
        child: Text('loading....'),
      ),

    );

  }

}