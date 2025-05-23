import 'dart:async';
import 'dart:convert';
import 'package:finalfashiontimefrontend/animations/bottom_animation.dart';
import 'package:finalfashiontimefrontend/screens/authentication/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../customize_pacages/otp_text_field/otp_text_field.dart';
import '../../utils/constants.dart';
import '../chats-screens/message_screen.dart';

class OtpScreen extends StatefulWidget {
  final String id;
  final String username;
  final String email;
  final String name;
  final String gender;
  final String access_token;
  final String phone_number;
  final String pic;
  final String fcmToken;
  final String password;
  const OtpScreen({Key? key, required this.id, required this.username, required this.email, required this.name, required this.gender, required this.access_token, required this.phone_number, required this.pic, required this.fcmToken, required this.password}) : super(key: key);

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  TextEditingController code = TextEditingController();
  bool loading = false;
  int attempts = 0;
  Duration _remainingTime = Duration.zero;
  Timer? _timer;
  String? _timerEmail;
  int resendAttempts = 0;

  @override
  void initState() {
    super.initState();
    _loadTimerState(); // Load saved timer state when screen initializes
  }

  Future<void> _loadTimerState() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('sign_timer_email');
    final endTime = prefs.getInt('sign_timer_end');
    final otpAttempts = prefs.getString('sign_otp_attempts');

    if(otpAttempts != null){
      print("code "+otpAttempts);
      resendAttempts = int.parse(otpAttempts);
    }
    print("Attempts "+resendAttempts.toString());

    if (savedEmail != null && endTime != null && savedEmail == widget.email) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final remainingMillis = endTime - now;

      if (remainingMillis > 0) {
        setState(() {
          _timerEmail = savedEmail;
          _remainingTime = Duration(milliseconds: remainingMillis);
          resendAttempts = 3;
          //attempts = 3;
        });
        _startCountdown(false); // Continue existing timer
      } else {
        // Timer expired - clear saved state
        _clearTimerState();
      }
    }
  }

  void _startCountdown([bool saveState = true]) async {
    // Cancel any existing timer
    _timer?.cancel();

    if (saveState) {
      // Only set new end time if we're starting fresh
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('sign_timer_email', widget.email);
      final endTime = DateTime.now().add(Duration(minutes: 5)).millisecondsSinceEpoch;
      await prefs.setInt('sign_timer_end', endTime);

      setState(() {
        _remainingTime = Duration(minutes: 5);
      });
    }

    setState(() {
      _timerEmail = widget.email;
      resendAttempts = 3;
      // attempts = 3;
    });

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingTime.inSeconds > 0) {
          _remainingTime -= Duration(seconds: 1);
        } else {
          timer.cancel();
          //attempts = 0;
          resendAttempts = 0;
          _clearTimerState();
        }
      });
    });
  }

  Future<void> _clearTimerState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('sign_timer_email');
    await prefs.remove('sign_timer_end');
    await prefs.remove('sign_otp_attempts');
    setState(() {
      _timerEmail = null;
    });
  }

  verifyOtp() async {
    setState(() {
      loading = true;
    });
    SharedPreferences preferences = await SharedPreferences.getInstance();
    try {
      if(code.text.isEmpty == true) {
        code.text = "";
        setState(() {
          loading = false;
        });
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: primary,
            title: const Text("FashionTime",style: TextStyle(color: ascent,fontFamily: Poppins,fontWeight: FontWeight.bold),),
            content: const Text("Please fill all fields",style: TextStyle(color: ascent,fontFamily: Poppins),),
            actions: [
              TextButton(
                child: const Text("Okay",style: TextStyle(color: ascent,fontFamily: Poppins)),
                onPressed:  () {
                  setState(() {
                    Navigator.pop(context);
                  });
                },
              ),
            ],
          ),
        );
      }
      else {
        setState(() {
          loading = true;
        });
        Map<String, String> body = {
          "email": widget.email,
          "code": code.text,
        };
        post(
          Uri.parse("$serverUrl/api/verify-otp/"),
          body: body,
        ).then((value) {
          print("Response ==> ${value.body}");
          if(json.decode(value.body)["detail"] == "Invalid or expired code.") {
            setState(() {
              loading = false;
            });
            attempts = attempts + 1;
            clearText();
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: primary,
                title: const Text("FashionTime",style: TextStyle(color: ascent,fontFamily: Poppins,fontWeight: FontWeight.bold),),
                content: const Text("Invalid Code.Please Resend new code.",style: TextStyle(color: ascent,fontFamily: Poppins),),
                actions: [
                  TextButton(
                    child: const Text("Okay",style: TextStyle(color: ascent,fontFamily: Poppins)),
                    onPressed:  () {
                      setState(() {
                        Navigator.pop(context);
                      });
                    },
                  ),
                ],
              ),
            );
          }else{
            _clearTimerState();
            setState(() {
              loading = false;
            });
            setState(() {
              preferences.setString("id", widget.id);
              preferences.setString("name", widget.name);
              preferences.setString("username", widget.username);
              preferences.setString("email", widget.email);
              preferences.setString("phone", widget.phone_number);
              preferences.setString("pic", widget.pic ?? "https://www.w3schools.com/w3images/avatar2.png");
              preferences.setString("gender", widget.gender);
              preferences.setString("token", json.decode(value.body)['access']);
              preferences.setString("fcm_token", widget.fcmToken);
              print("token of new user is======>${json.decode(value.body)['access']}");
            });
            //Future.delayed(Duration(milliseconds: 5000)).then((_) {
              Navigator.pop(context);
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const Login()));
           // });
          }
        });
      }
    } catch(e){
      setState(() {
        loading = false;
      });
      print(e);
    }
  }
  reSendOtp() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      loading = true;
      attempts = 0;
    });
    resendAttempts = resendAttempts + 1;
    prefs.setString('sign_otp_attempts', resendAttempts.toString());
    if(resendAttempts >= 4){
      setState(() {
        loading = false;
      });
      _startCountdown();
      return;
    }
    try {
      Map<String, String> body = {
        "email": widget.email,
        "name": widget.name,
        "username":widget.username,
        "password": widget.password,
        "gender": widget.gender,
        "phone_number": widget.phone_number,
        "fcmToken": widget.fcmToken
      };
      post(
        Uri.parse("$serverUrl/api/signup/"),
        body: body,
      ).then((value) {
        print("Response ==> ${value.body}");
        setState(() {
          loading = false;
        });
        code.text = "";
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: primary,
            title: const Text("FashionTime",style: TextStyle(color: ascent,fontFamily: Poppins,fontWeight: FontWeight.bold),),
            content: Text("A new verification code has been sent.",style: const TextStyle(color: ascent,fontFamily: Poppins),),
            actions: [
              TextButton(
                child: const Text("Okay",style: TextStyle(color: ascent,fontFamily: Poppins)),
                onPressed:  () {
                  setState(() {
                    Navigator.pop(context);
                  });
                },
              ),
            ],
          ),
        );
        //sendEmail(json.decode(value.body)["verification_code"]);
      }).catchError((error){
        setState(() {
          loading = false;
        });
        code.text = "";
      });
    } catch(e){
      setState(() {
        loading = false;
      });
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: secondary,
        image: const DecorationImage(
            image: AssetImage(
                "assets/background.jpg"
            ),
            fit: BoxFit.fill
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: WidgetAnimator(
          SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.17,),
                WidgetAnimator(
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                          child: Image.asset("assets/logo.png",height: 150,)
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25,),
                if(attempts >= 3) WidgetAnimator(
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("You’ve tried too many times. Please resend\nthe verification code.",
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.red,
                              fontFamily: Poppins
                          ),
                        )
                      ],
                    )
                ),
                if(attempts >= 3) SizedBox(height: 20,),
                if((resendAttempts >= 4) && _timerEmail == widget.email) WidgetAnimator(
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Resend verification link in ",
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.black54,
                              fontFamily: Poppins
                          ),
                        ),
                        Text('${_remainingTime.inMinutes.toString().padLeft(2, '0')}:'
                            '${(_remainingTime.inSeconds % 60).toString().padLeft(2, '0')}',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: Colors.red,
                              fontFamily: Poppins
                          ),
                        )
                      ],
                    )
                ),
                if((resendAttempts >= 4) && _timerEmail == widget.email) SizedBox(height: 20,), WidgetAnimator(
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.7,
                    child: OtpTextField(
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')), // Allow A-Z and 0-9
                        UpperCaseTextFormatter(), // Force uppercase
                      ],
                      enabled: !((attempts >= 3 || resendAttempts >= 4) || _timerEmail == widget.email),
                      textStyle: TextStyle(
                        color: Colors.pink.shade500,
                          fontSize: 18,
                          fontFamily: Poppins,
                          fontWeight: FontWeight.w900
                      ),
                      numberOfFields: 6,
                      focusedBorderColor: Colors.black54,
                      borderColor: Colors.black54,
                      cursorColor: Colors.pink.shade300,
                      enabledBorderColor: Colors.black54,
                      disabledBorderColor: Colors.grey,
                      showFieldAsBox: true,
                      onCodeChanged: (String co) {
                        if(co != 0) {
                          code.text = code.text + co;
                          print(co);
                          print(code.text);
                        }
                      },
                      onSubmit: (String verificationCode){
                        verifyOtp();
                      }, // end onSubmit
                    ),
                  ),
                ),
                const SizedBox(height: 20,),
                WidgetAnimator(
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("We have send you a code for verification.",
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.black54,
                              fontFamily: Poppins
                          ),
                        )
                      ],
                    )
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.1,),
                WidgetAnimator(
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        loading == true ? const SpinKitCircle(color: ascent,size: 70,) : Container(
                          height: 40,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15.0),
                              gradient: (resendAttempts >= 4) ? LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.topRight,
                                  stops: const [0.0, 0.99],
                                  tileMode: TileMode.clamp,
                                  colors: <Color>[
                                    Colors.grey,
                                    Colors.grey
                                  ]) : LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.topRight,
                                  stops: const [0.0, 0.99],
                                  tileMode: TileMode.clamp,
                                  colors: <Color>[
                                    primary,
                                    secondary
                                  ])
                          ),
                          child: ElevatedButton(
                              style: ButtonStyle(
                                  shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                      RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12.0),
                                      )
                                  ),
                                  backgroundColor: MaterialStateProperty.all(Colors.transparent),
                                  shadowColor: MaterialStateProperty.all(Colors.transparent),
                                  padding: MaterialStateProperty.all(EdgeInsets.only(
                                      top: 8,bottom: 8,
                                      left:MediaQuery.of(context).size.width * 0.2,right: MediaQuery.of(context).size.width * 0.2)),
                                  textStyle: MaterialStateProperty.all(
                                      const TextStyle(fontSize: 14, color: Colors.white,fontFamily: Poppins))),
                              onPressed: (resendAttempts >= 4) ? null : () {
                                reSendOtp();
                              },
                              child: const Text('Resend Verification Link',style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: ascent,
                                  fontFamily: Poppins
                              ),)),
                        ),
                      ],
                    )
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
