import 'package:flutter/material.dart';
import 'package:personality_scale/screens/auth.dart';
class ImagePage extends StatelessWidget {
  const ImagePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Image Page')),
      body: Center(
        child: Image.asset('assets/icons/logo1.png', width: 100),
      ),
    );
  }
}
