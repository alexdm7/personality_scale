import 'package:flutter/material.dart';
import 'dart:async';

import 'package:personality_scale/screens/start.dart';

class BeganScreen extends StatefulWidget {
  @override
  _BeganScreenState createState() => _BeganScreenState();
}

class _BeganScreenState extends State<BeganScreen> {
  double _opacity = 0.0;  // الشفافية الأولية

  @override
  void initState() {
    super.initState();

    // إضافة رسالة لعرضها في الـ logs عند تهيئة الصفحة
    debugPrint("BeganScreen initialized");

    // تأخير قليل لبدء تأثير التلاشي
    Future.delayed(Duration(milliseconds: 500), () {
      setState(() {
        _opacity = 1.0; // زيادة الشفافية تدريجياً
      });
    });

    // الانتقال إلى الصفحة التالية بعد 3 ثوانٍ
    Timer(Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => StartPage()), // تغيير هنا مع StartPage
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,  // جعل الخلفية شفافة تمامًا
      body: Center(
        child: AnimatedOpacity(
          opacity: _opacity,  // تعيين الشفافية بناءً على التأثير
          duration: Duration(seconds: 2),  // مدة التلاشي
          child: Container(
            alignment: Alignment.center,
            child: Text(
              'شعار التطبيق',
              style: TextStyle(fontSize: 24, color: Colors.black),
            ),
          ),
        ),
      ),
    );
  }
}
