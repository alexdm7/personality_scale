import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:personality_scale/data/pattern_message.dart';
import 'package:personality_scale/screens/about_us_screen.dart';
import 'package:personality_scale/screens/survey.dart';



class CriticalQuestionsScreen extends StatefulWidget {
  final List<Map<String, dynamic>> questions;
  final String? resultDocId;
  final List<String> topPatterns; // الأنماط المتساوية

  CriticalQuestionsScreen(
      {required this.questions,
      required this.resultDocId,
      required this.topPatterns});

  @override
  _CriticalQuestionsScreenState createState() =>
      _CriticalQuestionsScreenState();
}

class _CriticalQuestionsScreenState extends State<CriticalQuestionsScreen> {
  int currentQuestionIndex = 0;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> filteredQuestions = [];
  bool isResultDisplayed = false;
  String? selectedOption;
  List<String> topPatterns = [];
  Map<String, int> patternScores = {
    'المنجز': 0,
    'المتحدي': 0,
    'المتحمس': 0,
    'المساعد': 0,
    'المتفرد': 0,
    'المخلص': 0,
    'صانع السلام': 0,
    'المصلح': 0,
    'الباحث': 0,
  };

  @override
  void initState() {
    super.initState();
    filterQuestionsBasedOnPatterns();
  }

  void filterQuestionsBasedOnPatterns() {
    filteredQuestions = widget.questions
        .where((question) => widget.topPatterns.contains(question['pattern']))
        .toList();
  }

  void answerQuestion(String chosenPattern) {
    setState(() {
      // زيادة النقاط للنمط المختار
      patternScores[chosenPattern] = patternScores[chosenPattern]! + 1;
      saveAndDisplayFinalResult();
    });
  }
  Future<void> _signOut() async {


    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: Text('تأكيد الخروج'),
            content: Text('هل أنت متأكد من رغبتك في تسجيل الخروج؟'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // إغلاق نافذة التأكيد
                },
                child: Text('إلغاء'),
              ),
              TextButton(
                onPressed: () async {
                  await _auth.signOut();// تسجيل الخروج
                  Navigator.of(context).pop(); // إغلاق نافذة التأكيد
                  Navigator.pushReplacementNamed(context, '/login'); // التوجيه إلى شاشة تسجيل الدخول
                },
                child: Text('تأكيد'),
              ),
            ],
          ),
    );
  }
  // تحديث النتيجة في قاعدة البيانات مع الأسئلة الحاسمة والنقاط الخاصة بها
  void saveResultToDatabase(List<String> topPatterns) async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null && widget.resultDocId != null) {
      try {
        var surveyResultsRef =
            FirebaseFirestore.instance.collection('survey_results');

        // جلب البيانات الحالية من قاعدة البيانات
        var surveyDoc = await surveyResultsRef.doc(widget.resultDocId).get();

        if (surveyDoc.exists) {
          // جلب قائمة الأسئلة الحاسمة
          List<dynamic> criticalScoresList =
              surveyDoc['critical_question_scores'];

          // تحديث النقاط بناءً على الكود
          for (var question in filteredQuestions) {
            // تحديث الماب الذي يحتوي على نفس الكود
            criticalScoresList = criticalScoresList.map((item) {
              if (item['code'] == question['code']) {
                // تحديث النقاط الخاصة بهذا الكود
                return {
                  ...item, // الاحتفاظ ببقية العناصر
                  'answer_score':
                      patternScores[question['pattern']] ?? 0, // تحديث النقاط
                };
              }
              return item; // الإبقاء على باقي العناصر كما هي
            }).toList();
          }

          // تحديث النمط الأقرب في قاعدة البيانات
          await surveyResultsRef.doc(widget.resultDocId).update({
            'closest_pattern': topPatterns.first, // تحديث النمط الأقرب
            'critical_question_scores':
                criticalScoresList, // كتابة المصفوفة المحدثة
          });

          print('Result updated successfully');
        } else {
          print('Document does not exist.');
        }
      } catch (error) {
        print('Failed to update result: $error');
      }
    } else {
      print('No user is currently logged in or resultDocId is null.');
    }
  }
  Future<void> displayResultFromFirebase(BuildContext context) async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        print('تحقق من وجود النتيجة للمستخدم: ${user.uid}');
        var resultDoc = await FirebaseFirestore.instance
            .collection('survey_results')
            .where('user_id', isEqualTo: user.uid)
            .orderBy('timestamp', descending: true)  // ترتيب النتائج حسب الوقت من الأحدث إلى الأقدم
            .limit(1)
            .get();

        if (resultDoc.docs.isNotEmpty) {
          print('تم العثور على النتيجة');
          var resultData = resultDoc.docs.first.data();
          String closestPattern = resultData['closest_pattern'] ?? 'غير معروف';
          String image = PatternMessage.getImage(closestPattern) ;
          String message = PatternMessage.getMessage(closestPattern) ;

          // بعد التأكد من تحميل الواجهة بالكامل، اعرض Dialog
          WidgetsBinding.instance.addPostFrameCallback((_) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('النتيجة'),
                content: SingleChildScrollView(  // إضافة Scrollable
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text('النمط الأقرب لك'),
                      Text('$closestPattern',style: TextStyle(fontSize:20,fontWeight: FontWeight.bold)),
                      SizedBox(height: 10),
                      Image.asset(image), // عرض صورة النمط
                      SizedBox(height: 10),
                      Directionality(
                        textDirection: TextDirection.rtl,
                        child: Html(
                          data: message,
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('ممتاز'),
                  ),
                ],
              ),
            );
          });
        } else {
          print('لم يتم العثور على النتيجة');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('خطأ'),
                content: Text('لا توجد نتيجة مخزنة لهذا المستخدم'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('موافق'),
                  ),
                ],
              ),
            );
          });
        }
      } catch (e) {
        print("Error fetching result: $e");
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('خطأ'),
            content: Text('لا توجد نتيجة مخزنة لهذا المستخدم.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('موافق'),
              ),
            ],
          ),
        );

      }
    } else {
      print('المستخدم غير مسجل دخول');
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('خطأ'),
          content: Text('لم تقم بتسجيل الدخول بعد.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('موافق'),
            ),
          ],
        ),
      );
    }
  }

  void _showLogoutConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تأكيد الخروج'),
        content: Text('هل أنت متأكد من رغبتك في تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // إغلاق نافذة التأكيد
            },
            child: Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut(); // تسجيل الخروج
              Navigator.of(context).pop(); // إغلاق نافذة التأكيد
              Navigator.of(context).pushReplacementNamed(
                  '/login'); // التوجيه إلى شاشة تسجيل الدخول
            },
            child: Text('تأكيد'),
          ),
        ],
      ),
    );
  }

  // حفظ النتيجة وعرضها
  void saveAndDisplayFinalResult() {
    topPatterns = getTopPatterns();
    saveResultToDatabase(topPatterns);

    setState(() {
      isResultDisplayed = true;
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('النتيجة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(PatternMessage.getImage(topPatterns.first)),
            Text('النمط النهائي هو'),
            Text(topPatterns.first,style: TextStyle(fontWeight: FontWeight.bold,fontSize: 20),),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('ممتاز'),
          ),
        ],
      ),
    );
  }

  // الحصول على الأنماط المتساوية بناءً على النقاط
  List<String> getTopPatterns() {
    int highestScore = patternScores.values.reduce((a, b) => a > b ? a : b);
    return patternScores.entries
        .where((entry) => entry.value == highestScore)
        .map((entry) => entry.key)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (isResultDisplayed) {
      return Scaffold(
        appBar: AppBar(
          title: Text('نتيجة الاستبيان'),
          actions: [
            IconButton(
              onPressed: () {
                _showLogoutConfirmationDialog(); // استدعاء نافذة التأكيد
              },
              icon: const Icon(Icons.exit_to_app),
              color: Theme.of(context).colorScheme.primary,
            )
          ],
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              // رأس الـ Drawer مع أيقونة
              DrawerHeader(
                child: Row(
                  children: [



                  ],
                ),
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/icons/university_logo.jpg'),
                    fit: BoxFit.cover,
                  ),
                  color: Colors.blue,
                ),
              ),
              // الزر الأول في الـ Drawer مع أيقونة
              ListTile(
                leading: Icon(Icons.assignment_turned_in),
                title: Text('عرض النتيجة'),
                onTap: () async {
                  await displayResultFromFirebase(context); // استدعاء الدالة لعرض النتيجة
                  Navigator.pop(context); // إغلاق الـ Drawer بعد الضغط على الزر
                },
              ),

              // الزر الثاني في الـ Drawer مع أيقونة
              ListTile(
                leading: Icon(Icons.question_mark), // أيقونة للصفحة 2
                title: Text('من نحن'),
                onTap: () {
                  Navigator.pop(context); // إغلاق الـ Drawer
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AboutUsScreen()),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.exit_to_app),
                title: Text('خروج'),
                onTap: ()  {
                   _signOut();

                },
              ),
            ],
          ),
        ),
        body: SingleChildScrollView(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  PatternMessage.getImage(topPatterns.first),
                  height: 150,
                ),
                SizedBox(height: 20),
                Text(
                  'تمت الإجابة على جميع الأسئلة',
                  style: TextStyle(fontSize: 24),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10),
                Text(
                  'النمط النهائي هو',
                  style: TextStyle(fontSize: 24),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10),
                Text(
                  '${getTopPatterns().first}',
                  style: TextStyle(
                      fontSize: 28,
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Html(
                      data: PatternMessage.getMessage(topPatterns.first),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    // إعادة تعيين الحالة لتكرار الاستبيان
                    setState(() {
                      currentQuestionIndex = 0;
                      patternScores = {
                        'المنجز': 0,
                        'المتحدي': 0,
                        'المتحمس': 0,
                        'المساعد': 0,
                        'المتفرد': 0,
                        'المخلص': 0,
                        'صانع السلام': 0,
                        'المصلح': 0,
                        'الباحث': 0,
                      };
                      filteredQuestions.clear(); // إعادة تعيين الإجابات
                    });
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SurveyScreen()),
                    );
                  },
                  child: Text('إعادة البدء'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('الأسئلة الحاسمة')),
      body:   SingleChildScrollView(
    child:Center(
        child:Column (
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.topPatterns.length == 2) ...[
              Text('اي العبارات تنطبق عليك؟',style: TextStyle(fontSize: 25),),
              for (int i = 0; i < 2; i++)
                RadioListTile<String>(
                  title: Text(
                      'العبارة ${i + 1}: ${filteredQuestions[i]['question']}'),
                  value: filteredQuestions[i]['pattern'],
                  groupValue: selectedOption,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedOption = value;
                        answerQuestion(value);
                      });
                    }
                  },
                ),
            ] else ...[
              Text('اختر عبارة من الأنماط المتساوية:'),
              for (var question in filteredQuestions)
                RadioListTile<String>(
                  title: Text(question['question']),
                  value: question['pattern'],
                  groupValue: selectedOption,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedOption = value;
                        answerQuestion(value);
                      });
                    }
                  },
                ),
            ],
          ],
        ),
      ),
    ),
    );
  }
}
