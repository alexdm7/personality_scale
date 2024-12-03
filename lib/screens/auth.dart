import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:personality_scale/screens/Agreement.dart';
import 'package:personality_scale/screens/survey.dart';

import '../data/country.dart';
import 'about_us_screen.dart';


// Firebase authentication
final _fireBase = FirebaseAuth.instance;

class AuthScreen extends StatefulWidget {
  final bool showImageAnimation;
  const AuthScreen({super.key,this.showImageAnimation = false});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>with TickerProviderStateMixin {
  final _form = GlobalKey<FormState>();
  var userCredentials;
  var _isLogin = true;
  var _enteredEmail = '';
  var _username = '';
  var _name = '';

  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _positionAnimation;

  var _selectedDegree = '';
  var _gender = '';
  var _nationality = '';
  var _enteredPassword = '';
  var _isAuthenticate = false;
  DateTime? _birthDate; // لتخزين تاريخ الميلاد


  // قائمة الدول باللغة العربية


  // قائمة الشهادات
  final List<String> _degrees = [
    'غير متعلم',
    'ابتدائي',
    'متوسط',
    'ثانوي',
    'دبلوم',
    'بكالوريوس',
    'ماجيستير',
    'دكتوراه'
  ];
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // إعداد الأنيميشن لتغيير الحجم


    if (widget.showImageAnimation) {
      // إذا تم تفعيل الأنيميشن عند الانتقال من الصفحة السابقة
      _controller.forward();
    }

    // إعداد الأنيميشن لتغيير الحجم
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  void _pickBirthDate() async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (selectedDate != null) {
      setState(() {
        _birthDate = selectedDate; // تحديث تاريخ الميلاد
      });
    }
  }

  int _calculateAge(DateTime birthDate) {
    final currentDate = DateTime.now();
    int age = currentDate.year - birthDate.year;
    if (currentDate.month < birthDate.month ||
        (currentDate.month == birthDate.month &&
            currentDate.day < birthDate.day)) {
      age--; // إذا لم يمر عيد ميلاده هذا العام بعد، يتم خصم سنة من العمر
    }
    return age;
  }

  void _submit() async {
    final isValid = _form.currentState!.validate();
    if (!isValid) {
      setState(() {
        _isAuthenticate =
        false; // إيقاف حالة التحميل إذا كانت المدخلات غير صحيحة
      });
      return; // إذا كانت البيانات غير صحيحة، لا نقوم بإتمام العملية
    }

    _form.currentState!.save();

    try {
      setState(() {
        _isAuthenticate = true; // تعيين حالة التحميل عند بدء العملية
      });

      if (_isLogin) {
        // تسجيل الدخول
        userCredentials = await _fireBase.signInWithEmailAndPassword(
          email: _enteredEmail,
          password: _enteredPassword,
        );


        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => SurveyScreen()),
        );
      } else {
        // تحقق من اختيار الجنس فقط عند التسجيل
        if (_gender == null || _gender!.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('يرجى اختيار الجنس')),
          );
          setState(() {
            _isAuthenticate =
            false; // إيقاف حالة التحميل إذا لم يتم اختيار الجنس
          });
          return; // إيقاف عملية التسجيل إذا لم يتم اختيار الجنس
        }

        if (_birthDate == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('يرجى اختيار تاريخ الميلاد')),
          );
          setState(() {
            _isAuthenticate =
            false; // إيقاف حالة التحميل إذا لم يتم اختيار تاريخ الميلاد
          });
          return;
        }

        final age = _calculateAge(_birthDate!);
        final ageString = age.toString();

        // تحقق من وجود اسم المستخدم في Firestore
        final userCollection = FirebaseFirestore.instance.collection('users');
        final userSnapshot = await userCollection.where(
            'username', isEqualTo: _username).get();

        if (userSnapshot.docs.isNotEmpty) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('اسم المستخدم موجود بالفعل!')),
          );
          setState(() {
            _isAuthenticate =
            false; // إيقاف حالة التحميل إذا كان اسم المستخدم موجودًا بالفعل
          });
          return;
        }

        // إنشاء الحساب الجديد
        userCredentials = await _fireBase.createUserWithEmailAndPassword(
          email: _enteredEmail,
          password: _enteredPassword,
        );

        await FirebaseFirestore.instance.collection('users').doc(
            userCredentials.user!.uid).set({
          'username': _username,
          'name': _name,
          'age': ageString,
          'nationality': _nationality,
          'email': _enteredEmail,
          'gender': _gender, // إضافة الجنس
          'degree': _selectedDegree,
        });

        // الانتقال إلى صفحة "اتفاقية"
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AgreementScreen()),
        );
      }
    } on FirebaseAuthException catch (error) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message ?? 'حدث خطأ')),
      );
      setState(() {
        _isAuthenticate = false; // إيقاف حالة التحميل في حالة حدوث خطأ
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

                 Card(


                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _form,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [

                          AnimatedBuilder(
                            animation: _scaleAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _scaleAnimation.value, // تطبيق الأنيميشن
                                child: Image.asset(
                                  'assets/icons/logo1.png', // نفس الصورة من صفحة البداية
                                  width: 100,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            textAlign: TextAlign.right,
                            decoration: const InputDecoration(
                                label: Text('الايميل'),labelStyle: TextStyle(color: Colors.black),),
                            keyboardType: TextInputType.emailAddress,

                            autocorrect: false,
                            // style: const TextStyle(color: Colors.white),
                            textCapitalization: TextCapitalization.none,
                            validator: (value) {
                              if (value == null || value
                                  .trim()
                                  .isEmpty || !value.contains('@')) {
                                return 'يرجى إدخال البريد الإلكتروني بشكل صحيح';
                              }
                              return null;
                            },
                            onSaved: (value) {
                              _enteredEmail = value!;
                            },
                          ),
                          if (!_isLogin)
                            TextFormField(
                              textAlign: TextAlign.right,
                              decoration: const InputDecoration(
                                  label: Text('اسم المستخدم') ,labelStyle: TextStyle(color: Colors.black),),

                              enableSuggestions: false,
                              validator: (value) {
                                if (value == null || value.isEmpty || value
                                    .trim()
                                    .length < 4) {
                                  return 'username has to be 4 ';
                                }
                                return null;
                              },
                              onSaved: (value) {
                                _username = value!;
                              },
                            ),
                          if (!_isLogin)
                            TextFormField(
                              textAlign: TextAlign.right,
                              decoration: const InputDecoration(
                                  label: Text('الاسم'),labelStyle: TextStyle(color: Colors.black),),
                              enableSuggestions: false,
                              validator: (value) {
                                if (value == null || value.isEmpty || value
                                    .trim()
                                    .length < 3) {
                                  return 'name has to be 3 ';
                                }
                                return null;
                              },
                              onSaved: (value) {
                                _name = value!;
                              },
                            ),
                          if (!_isLogin)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('تاريخ الميلاد:',
                                    style: TextStyle(color: Colors.black,fontSize: 16)),
                                Row(
                                  children: [
                                    ElevatedButton(
                                      onPressed: _pickBirthDate,
                                      child: Text(_birthDate == null
                                          ? 'اختار تاريخ الميلاد'
                                          : DateFormat('yyyy-MM-dd').format(
                                          _birthDate!)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          if (!_isLogin)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                    'الجنس:', style: TextStyle(color: Colors.black,fontSize: 16)),
                                Row(
                                  children: [
                                    Expanded(
                                      child: RadioListTile<String>(
                                        title: const Text('ذكر',style: TextStyle(color: Colors.black),),
                                        value: 'ذكر',
                                        groupValue: _gender,
                                        onChanged: (value) {
                                          setState(() {
                                            _gender = value!;
                                          });
                                        },
                                      ),
                                    ),
                                    Expanded(
                                      child: RadioListTile<String>(
                                        title: const Text('أنثى',style: TextStyle(color: Colors.black),),
                                        value: 'أنثى',
                                        groupValue: _gender,
                                        onChanged: (value) {
                                          setState(() {
                                            _gender = value!;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          if (!_isLogin)
                            DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                  label: Text('الجنسية'),labelStyle: TextStyle(color: Colors.black),),
                              items: Countrydata.countries
                                  .map((country) =>
                                  DropdownMenuItem(
                                    value: country['name'],
                                    child: Row(
                                      children: [
                                        Image.asset(
                                          country['flag']!,
                                          width: 20,
                                          height: 20,
                                        ),
                                        const SizedBox(width: 10),
                                        Text(country['name']!),
                                      ],
                                    ),
                                  ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _nationality = value!;
                                });
                              },
                              validator: (value) {
                                if (value == null) {
                                  return 'الرجاء اختيار الجنسية';
                                }
                                return null;
                              },
                            ),
                          if (!_isLogin)
                            DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                  label: Text('المستوى الدراسي'),labelStyle: TextStyle(color: Colors.black)),
                              items: _degrees
                                  .map((degree) =>
                                  DropdownMenuItem(
                                    value: degree,
                                    child: Text(degree),
                                  ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedDegree = value!;
                                });
                              },
                              validator: (value) {
                                if (value == null) {
                                  return 'الرجاء اختيار الشهادة الجامعية';
                                }
                                return null;
                              },
                            ),
                          TextFormField(
                            textAlign: TextAlign.right,
                            decoration: const InputDecoration(
                                label: Text('كلمة السر'),labelStyle: TextStyle(color: Colors.black),),
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value
                                  .trim()
                                  .length < 6) {
                                return 'password has to be 6 ';
                              }
                              return null;
                            },
                            onSaved: (value) {
                              _enteredPassword = value!;
                            },
                          ),
                          const SizedBox(height: 12),
                          if (_isAuthenticate) const CircularProgressIndicator(),
                          if (!_isAuthenticate)
                            ElevatedButton(
                              onPressed: _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme
                                    .of(context)
                                    .colorScheme
                                    .primaryContainer,
                              ),
                              child: Text(_isLogin ? 'دخول' : 'تسجيل'),
                            ),
                          if (!_isAuthenticate)
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _isLogin = !_isLogin;
                                });
                              },
                              child: Text(_isLogin
                                  ? 'تسجيل جديد'
                                  : '!!لدي حساب بالفعل',style: TextStyle(color: Colors.black),),
                            ),
                          if (!_isAuthenticate)
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AboutUsScreen(),
                                  ),
                                );
                              },
                              child: const Text('من نحن؟',style: TextStyle(color: Colors.black),),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

            ],
          ),
        ),
      ),
    );
  }
}
