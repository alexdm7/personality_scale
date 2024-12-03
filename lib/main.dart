import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'package:personality_scale/screens/agreement.dart';
import 'package:personality_scale/screens/auth.dart';
import 'package:personality_scale/screens/began.dart';
import 'package:personality_scale/screens/survey.dart';
import 'package:personality_scale/screens/splash.dart';
import 'package:personality_scale/screens/start.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  void checkTermsAgreement(BuildContext context) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // جلب بيانات المستخدم من Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>; // تحويل البيانات إلى Map
      bool termsAgreed = userData['termsAgreed'] ?? false;


      if (termsAgreed) {

          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => SurveyScreen()));

      } else {
        // إذا لم يوافق على الميثاق
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => AgreementScreen()));
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Personality_Scale App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 13, 71, 107),
        ),
      ),
      home: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SplashScreen();
          }
          if (snapshot.hasData) {
            // استدعاء الدالة للتحقق من حالة الميثاق
            checkTermsAgreement(ctx);
            return const Center(child: CircularProgressIndicator()); // حتى يتم الانتقال إلى الشاشة المطلوبة
          }
          return  StartPage(); // تأكد من استيراد شاشة التسجيل بشكل صحيح
        },
      ),
      routes: {
        '/login': (ctx) => const AuthScreen(),

      },
    );
  }
}
