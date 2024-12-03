import 'package:flutter/material.dart';
import 'package:personality_scale/data/teacher.dart';



class AboutUsScreen extends StatelessWidget {
    AboutUsScreen({super.key});

  // قائمة الأساتذة
  final List<Teacher> teachers = [
    Teacher(name: 'د.شريف السعودي', position: 'أستاذ مشارك قياس وتقويم', imageUrl: 'assets/dr/alsoudi.jpg'),
    Teacher(name: 'د. محمد التوبي', position: 'أستاذ مساعد تقنيات التعليم', imageUrl: 'assets/dr/altobi.jpg'),
    Teacher(name: 'د. أمينة بن قويدر', position: 'أستاذ مشارك علم نفس اكلينيكي', imageUrl: 'assets/dr/goider.jpg'),
    Teacher(name: 'د. أمجد جمعة', position: 'أستاذ مشارك علم نفس تربوي', imageUrl: 'assets/dr/amjad.jpg'),
    Teacher(name: 'د. عامر الحبسي', position: 'أستاذ مساعد إرشاد نفسي', imageUrl: 'assets/dr/alhbsy.jpg'),
  ];


    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('من نحن؟'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end, // محاذاة العناصر إلى اليمين
              children: [
                // نص عن التطبيق
                const Text(
                  ':عن التطبيق',
                  textAlign: TextAlign.right, // محاذاة النص إلى اليمين
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  'هذا التطبيق يهدف إلى الحصول على استبيان للاغراض العلمية',
                  textAlign: TextAlign.right, // محاذاة النص إلى اليمين
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 20),

                // قسم الأساتذة
                const Text(
                  ':فريق العمل',
                  textAlign: TextAlign.right, // محاذاة النص إلى اليمين
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                // عرض الأساتذة باستخدام ListView
                ...teachers.map((teacher) {
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: AssetImage(teacher.imageUrl),
                        radius: 30,
                      ),
                      title: Text(
                        teacher.name,
                        textAlign: TextAlign.right, // محاذاة النص إلى اليمين
                      ),
                      subtitle: Text(
                        teacher.position,
                        textAlign: TextAlign.right, // محاذاة النص إلى اليمين
                      ),
                    ),
                  );
                })
              ],
            ),
          ),
        ),
      );
    }
}


