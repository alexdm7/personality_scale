import 'package:flutter/material.dart';
import 'package:personality_scale/screens/auth.dart'; // تأكد من استيراد صفحة AuthScreen

class StartPage extends StatefulWidget {
  const StartPage({super.key});

  @override
  _StartPageState createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  late double screenHeight;
  bool _isAnimating = false; // لتتبع حالة الأنيميشن

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    screenHeight = MediaQuery.of(context).size.height;

    _animation = Tween<double>(begin: 0, end: -screenHeight / 3).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
  }

  void _startAnimation() async {
    setState(() {
      _isAnimating = true; // بدء الأنيميشن
    });

    // تشغيل الأنيميشن
    await _animationController.forward();

    // الانتظار لمدة ثانيتين بعد الأنيميشن
    await Future.delayed(Duration(seconds: 2));

    // الانتقال إلى صفحة "AuthScreen" بعد التأخير
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => AuthScreen(showImageAnimation: true)), // إرسال متغير لتفعيل الأنيميشن في AuthScreen
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(  // استخدام Stack لاحتواء كل العناصر
        children: [
          // باقي المحتوى
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // الصورة المتحركة
                    AnimatedBuilder(
                      animation: _animation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _animation.value),
                          child: Image.asset(
                            'assets/icons/logo1.png',
                            width: 100,
                          ),
                        );
                      },
                    ),
                    // الصورة الثابتة فوق الصورة المتحركة
                    CircleAvatar(
                      radius: 130, // نصف العرض الذي يحدد حجم الصورة الدائرية
                      backgroundImage: AssetImage('assets/icons/university_logo.jpg'), // مسار الصورة
                    ), // عرض الصورة الثابتة
                  ],
                ),
              ],
            ),
          ),

          // الزر في المنتصف أسفل الشاشة
          Positioned(
            bottom: 20,  // المسافة من أسفل الشاشة
            left: 0,
            right: 0,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: ElevatedButton(
                onPressed: _startAnimation,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  'ابدأ',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), // تنسيق النص
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
