
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:personality_scale/data/pattern_message.dart';
import 'package:personality_scale/data/critical_questions.dart';
import 'package:personality_scale/data/questions.dart';
import 'package:personality_scale/screens/about_us_screen.dart';
import 'package:uuid/uuid.dart';

import 'CriticalQuestionsScreen.dart';

class SurveyScreen extends StatefulWidget {
  const SurveyScreen({super.key});

  @override
  _SurveyScreenState createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String username = '';
  String age = '';
  String patternMessage = '';
  int currentQuestionIndex = 0;
  String getImage = '';
  String uniqueId = '';
  String highestPattern = '';
  String? resultDocId;
  List<Map<String, dynamic>> questions = CriticalQuestions
      .getCriticalQuestionsForPatterns;
  final PageController _pageController = PageController();
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

  List<Map<String, dynamic>> userAnswers = []; // قائمة لحفظ الأسئلة والإجابات

  @override
  void initState() {
    super.initState();
    fetchUsername();
     shuffleQuestions(); // خلط الأسئلة عند التهيئة
  }
  Future<void> _signOut() async {


    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title:const Text('تأكيد الخروج'),
            content:const Text('هل أنت متأكد من رغبتك في تسجيل الخروج؟'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // إغلاق نافذة التأكيد
                },
                child: const Text('إلغاء'),
              ),
              TextButton(
                onPressed: () async {
                  await _auth.signOut();// تسجيل الخروج
                  Navigator.of(context).pop(); // إغلاق نافذة التأكيد
                  Navigator.pushReplacementNamed(context, '/login'); // التوجيه إلى شاشة تسجيل الدخول
                },
                child: const Text('تأكيد'),
              ),
            ],
          ),
    );
  }
  void _showLogoutConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('تأكيد الخروج'),
            content: const Text('هل أنت متأكد من رغبتك في تسجيل الخروج؟'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // إغلاق نافذة التأكيد
                },
                child:const Text('إلغاء'),
              ),
              TextButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut(); // تسجيل الخروج
                  Navigator.of(context).pop(); // إغلاق نافذة التأكيد
                  Navigator.of(context).pushReplacementNamed(
                      '/login'); // التوجيه إلى شاشة تسجيل الدخول
                },
                child: const Text('تأكيد'),
              ),
            ],
          ),
    );
  }

  void shuffleQuestions() {
    QuestionData.questionPatternMap.shuffle(Random()); // خلط الأسئلة عشوائيًا
  }

  void fetchUsername() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        var userData = await FirebaseFirestore.instance.collection('users').doc(
            user.uid).get();
        setState(() {
          username = userData.data()?['username'] ?? 'Unknown User';
          age = userData.data()?['age'] ?? 'Unknown Age';
        });
      } catch (e) {
        print("Error fetching username: $e");
      }
    }
  }

  void answerQuestion(int score) {
    setState(() {
      String questionCode = QuestionData
          .questionPatternMap[currentQuestionIndex]['code']!;
      String pattern = QuestionData
          .questionPatternMap[currentQuestionIndex]['pattern']!;

      // تحديث النقاط للنمط
      patternScores[pattern] = (patternScores[pattern] ?? 0) + score;

      // إضافة السؤال والإجابة للقائمة مع الرمز
      userAnswers.add({
        'code': questionCode,
        'question': QuestionData
            .questionPatternMap[currentQuestionIndex]['question'],
        'pattern': pattern,
        'answer_score': score,
      });

      currentQuestionIndex++;

      if (currentQuestionIndex >= QuestionData.questionPatternMap.length) {
        checkPatternsForTie();
      }
    });
  }

  List<String> getTopPatterns() {
    int highestScore = patternScores.values.reduce((a, b) => a > b ? a : b);
    return patternScores.entries
        .where((entry) => entry.value == highestScore)
        .map((entry) => entry.key)
        .toList();
  }

  void displayResult(String resultPattern) {
    setState(() {
      highestPattern = resultPattern;
      patternMessage = PatternMessage.getMessage(highestPattern);
      getImage = PatternMessage.getImage(highestPattern);
    });

    saveResultToFirebase();
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text(' نتيجة',textAlign: TextAlign.right),
            content: SingleChildScrollView( // استخدم SingleChildScrollView لتمكين التمرير
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(username,style: const TextStyle(fontWeight: FontWeight.bold,fontSize: 20),textAlign: TextAlign.center),
                  const Text('النمط الأقرب لك هو  ',textAlign: TextAlign.center),
                  const SizedBox(height: 10),

                  Image.asset(
                      getImage
                  ),
                  const SizedBox(height: 10),
                  Text(highestPattern,style: const TextStyle(fontWeight: FontWeight.bold,fontSize: 20),textAlign: TextAlign.center),
                 // عرض الرسالة المخصصة
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('ممتاز'),
              ),
            ],
          ),
    );
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
          String image = PatternMessage.getImage(closestPattern)  ;
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
                      const Text('النمط الأقرب لك'),
                      Text('$closestPattern',style: const TextStyle(fontSize:20,fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Image.asset(image), // عرض صورة النمط
                      const SizedBox(height: 10),
                      Directionality(
                        textDirection: TextDirection.rtl, // تحديد الاتجاه من اليمين لليسار
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
                    child: const Text('ممتاز'),
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
                title: const Text('خطأ'),
                content: const Text('لا توجد نتيجة مخزنة لهذا المستخدم'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('موافق'),
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
            title: const Text('خطأ'),
            content: const Text('لا توجد نتيجة مخزنة لهذا المستخدم.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('موافق'),
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
          title: const Text('خطأ'),
          content: const Text('لم تقم بتسجيل الدخول بعد.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('موافق'),
            ),
          ],
        ),
      );
    }
  }





  void navigateToCriticalQuestionsScreen(List<String> topPatterns) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CriticalQuestionsScreen(
          questions: questions, // الأسئلة الحاسمة
          resultDocId: uniqueId, // تمرير المعرف الفريد
          topPatterns: topPatterns, // الأنماط المتساوية
        ),
      ),
    );
  }




  Future<void> checkPatternsForTie() async {
    List<String> topPatterns = getTopPatterns();

    if (topPatterns.length > 1) {
      // إذا كان هناك تساوٍ، احفظ النتيجة وأظهر رسالة تنبيه قبل الانتقال
      saveResultToCriticalFirebase();

      // عرض رسالة تأكيد للمستخدم قبل الذهاب إلى الأسئلة الحاسمة
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('تنبيه'),
          content: Text(
            'بسبب تساويك في نمط ${topPatterns.join(" و ")}، سيتم نقلك إلى الأسئلة الحاسمة.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // إغلاق نافذة التنبيه
                navigateToCriticalQuestionsScreen(topPatterns); // الذهاب إلى صفحة الأسئلة الحاسمة
              },
              child: const Text('متابعة'),
            ),
          ],
        ),
      );
    } else {
      displayResult(topPatterns.first); // عرض النمط الأقرب إذا لم يوجد تساوٍ
    }
  }



  Future<String?> saveResultToCriticalFirebase() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        List<String> topPatterns = getTopPatterns();
        bool needsCriticalQuestions = topPatterns.length > 1;


        var uuid = const Uuid();
        uniqueId = uuid.v4();
        FirebaseFirestore.instance.collection('survey_results').doc(uniqueId).set({
          'user_id': user.uid,
          'username': username,
          'age': age,
          'closest_pattern': 'متساوي',
          'scores': patternScores,
          'timestamp': FieldValue.serverTimestamp(),
          'responses': userAnswers,
          'critical_question_scores': questions.map((q) => {
            'code': q['code'],
            'pattern': q['pattern'],
            'question': q['question'],
            'answer_score': 0,
          }).toList(),
          'critical_questions_needed': needsCriticalQuestions,
        });


        print("Document created with ID: $uniqueId");

        return uniqueId; // إعادة المعرف هنا

      } catch (e) {
        print("Error saving result to Firebase: $e");
        return null;
      }
    } else {
      print("No user is currently signed in.");
      return null;
    }
  }


  void saveResultToFirebase() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        List<String> topPatterns = getTopPatterns();
        bool needsCriticalQuestions = topPatterns.length > 1;


        FirebaseFirestore.instance.collection('survey_results').add({
          'user_id': user.uid,
          'username': username,
          'age': age,
          'closest_pattern': highestPattern,
          'scores': patternScores,
          'timestamp': FieldValue.serverTimestamp(),
          'responses': userAnswers,
          'critical_question_scores': questions.map((q) => {
            'code': q['code'],
            'pattern': q['pattern'],
            'question': q['question'],
            'answer_score': 0, // الإجابة تكون دائمًا 0 في هذه المرحلة
          }).toList(),
          'critical_questions_needed': needsCriticalQuestions,
        });
      } catch (e) {
        print("Error saving result to Firebase: $e");
      }
    } else {
      print("No user is currently signed in.");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الاستبيان'),
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
            const DrawerHeader(
              child: Row(

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
              leading: const Icon(Icons.assignment_turned_in),
              title: const Text('عرض النتيجة'),
              onTap: () async {
                await displayResultFromFirebase(context); // استدعاء الدالة لعرض النتيجة
                Navigator.pop(context); // إغلاق الـ Drawer بعد الضغط على الزر
              },
            ),

            // الزر الثاني في الـ Drawer مع أيقونة
            ListTile(
              leading: const Icon(Icons.question_mark), // أيقونة للصفحة 2
              title: const Text('من نحن'),
              onTap: () {
                Navigator.pop(context); // إغلاق الـ Drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AboutUsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: const Text('خروج'),
              onTap: () {
                    _signOut();

              },
            ),
          ],
        ),
      ),

      body: currentQuestionIndex < QuestionData.questionPatternMap.length
          ? PageView.builder(
        controller: _pageController,
        itemCount: QuestionData.questionPatternMap.length,
        itemBuilder: (context, index) {
          return SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                username.isEmpty
                    ? const CircularProgressIndicator()
                    : Column(
                  children: [
                    Text(
                      'السؤال ${index + 1} من ${QuestionData.questionPatternMap.length}',
                      style: const TextStyle(fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      ' ${QuestionData.questionPatternMap[index]['question']}',
                      style: const TextStyle(fontSize: 24),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    answerQuestion(5);
                    _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeIn);
                  },
                  child: const Text('دائمًا'),
                ),
                ElevatedButton(
                  onPressed: () {
                    answerQuestion(4);
                    _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeIn);
                  },
                  child: const Text('غالبًا'),
                ),
                ElevatedButton(
                  onPressed: () {
                    answerQuestion(3);
                    _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeIn);
                  },
                  child: const Text('أحيانًا'),
                ),
                ElevatedButton(
                  onPressed: () {
                    answerQuestion(2);
                    _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeIn);
                  },
                  child: const Text('نادرًا'),
                ),
                ElevatedButton(
                  onPressed: () {
                    answerQuestion(1);
                    _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeIn);
                  },
                  child: const Text('أبدًا'),
                ),
              ],
            ),
          );
        },
      )
          : getTopPatterns().length > 1
          ? Container() // لا يظهر شيء في حالة التساوي في الأنماط
      : SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              Image.asset(
                getImage, // صورة النمط
                height: 150,
              ),
              const SizedBox(height: 20),


              const Text(
                'تمت الإجابة على جميع الأسئلة',
                style: TextStyle(
                  fontSize: 24, // حجم الخط
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),


              const Text(
                'النمط الأقرب لك هو',
                style:   TextStyle(
                  fontSize: 20, // حجم الخط
                  fontWeight: FontWeight.bold, // جعل النص عريض
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),

              Text(
                highestPattern,
                style: const TextStyle(
                  fontSize: 28,
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // الرسالة الخاصة بالنمط
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Directionality(
                  textDirection: TextDirection.rtl, // تحديد الاتجاه من اليمين لليسار
                  child: Html(
                    data: patternMessage,
                  ),
                ),
              ),


              const SizedBox(height: 20),
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
                    userAnswers.clear(); // إعادة تعيين الإجابات
                  });
                },
                child: const Text('إعادة البدء'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}