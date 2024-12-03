import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'survey.dart';

class AgreementScreen extends StatefulWidget {
  @override
  _AgreementScreenState createState() => _AgreementScreenState();
}

class _AgreementScreenState extends State<AgreementScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _agreedToTerms = false; // حالة الـ Checkbox

  Future<void> agreeToTerms(BuildContext context) async {
    User? user = _auth.currentUser;
    if (user != null) {
      // تحديث Firestore لتحديد أن المستخدم قد وافق على الميثاق
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'termsAgreed': true});

      // الانتقال إلى شاشة الاستبيان
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => SurveyScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("الميثاق والشروط")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end, // محاذاة العمود إلى اليمين
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end, // محاذاة النصوص إلى اليمين
                  children: [
                    const Text(
                      "اتفاقية جمع البيانات والاستخدام العلمي",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.right, // محاذاة النص إلى اليمين
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "هذه الاتفاقية لجمع البيانات والاستخدام العلمي مبرمة بين (باحثين من جامعة الشرقية) ومقرهم الرئيسي في جامعة الشرقية بسلطنة عمان ,إبراء العميل المستخدم للتطبيق ويشار إليهما معاً بـ \الطرفين"
                          "\n\nتحدد هذه الاتفاقية الشروط التي يقوم بموجبها الباحثون بجمع واستخدام وحماية بيانات المستخدم التي يتم جمعها من خلال تطبيق مقياس أنماط الشخصية واستخدامها لأغراض البحث العلمي فقط",
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.right, // محاذاة النص إلى اليمين
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "غرض جمع البيانات",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      "الغرض من جمع البيانات من خلال التطبيق هو تسهيل البحث العلمي بهدف التعرف على الأنماط المختلفة للشخصية عند الأفراد بمختلف شرائحهم"
                          "\n\nسيتم استخدام البيانات التي يتم جمعها بموجب هذه الاتفاقية حصريًا لأغراض علمية وبحثية ولن تُستخدم لأغراض تجارية أو تسويقية أو إعلانية",
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "أنواع البيانات التي يتم جمعها",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      "قد يقوم التطبيق بجمع الأنواع التالية من البيانات من المستخدم\n"
                          "المعلومات الشخصية (مثل العمر، الجنس، المؤهل)\n"
                          " بيانات الاستخدام (مثل تفاعلات التطبيق، الميزات المستخدمة)\n"
                          " البيانات التقنية (مثل نوع الجهاز، نظام التشغيل)\n\n"
                          "لن يتم جمع أي معلومات شخصية حساسة، مثل أرقام الضمان الاجتماعي، المعلومات المصرفية، أو المعلومات الصحية الشخصية، دون موافقة منفصلة وصريحة",
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "موافقة المستخدم",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      "بقبول هذه الاتفاقية، يوافق المستخدم على جمع ومعالجة واستخدام بياناته كما هو موضح في هذا المستند"
                          "\n\nللمستخدم الحق في سحب موافقته في أي وقت، مما سيوقف جمع البيانات في المستقبل، مع استمرار استخدام البيانات التي تم جمعها بالفعل لأغراض علمية في شكل مجهول",
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "إخفاء الهوية وأمان البيانات",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      "سيقوم التطبيق بإخفاء هوية البيانات قدر الإمكان لضمان عدم إمكانية التعرف على الأفراد في أي تحليل علمي أو نتائج بحثية"
                          "\n\nسيطبق التطبيق معايير أمان عالية لحماية جميع البيانات التي يتم جمعها من الوصول غير المصرح به أو الفقدان أو سوء الاستخدام",
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "استخدام البيانات والقيود",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      "سيتم استخدام البيانات فقط لأغراض البحث العلمي، التطوير والتحليل، ولن يتم بيعها أو مشاركتها أو نقلها إلى أي طرف ثالث إلا للضرورة العلمية وبشكل مجهول."
                          "\n\nقد تُستخدم البيانات التي يتم جمعها في دراسات بحثية أو علمية منشورة؛ ومع ذلك، لن يتم تقديم البيانات بطريقة تسمح بتحديد هوية المستخدم",
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "حقوق المستخدم",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      " الوصول: يحق للمستخدم طلب الوصول إلى البيانات التي جمعها التطبيق عنه\n"
                          " التصحيح: يمكن للمستخدم طلب تصحيح أي بيانات غير دقيقة\n"
                          " الحذف: يحق للمستخدم طلب حذف بياناته، وفقًا للحاجة القانونية أو العلمية",
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "مدة الاتفاقية وإنهاؤها",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      "تصبح هذه الاتفاقية سارية عند قبول المستخدم لها وستظل سارية ما لم يتم إنهاؤها من قبل أي من الطرفين"
                          "\n\nيمكن للمستخدم إنهاء هذه الاتفاقية في أي وقت عن طريق تقديم إشعار خطي للباحثين، مما سيوقف جمع البيانات في المستقبل",
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "توقيع الطرفين",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      "أوافق على شروط هذه الاتفاقية لجمع البيانات والاستخدام العلمي",
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.right,
                    ),
                  ],
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Checkbox(
                  value: _agreedToTerms,
                  onChanged: (value) {
                    setState(() {
                      _agreedToTerms = value!;
                    });
                  },
                ),
                const Text("أوافق على الشروط والأحكام"),
              ],
            ),
            ElevatedButton(
              onPressed: _agreedToTerms ? () => agreeToTerms(context) : null,
              child: const Text("اوافق" ),
            ),
          ],
        ),
      ),
    );
  }
}
