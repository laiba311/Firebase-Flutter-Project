import 'dart:async';
import 'dart:convert';
import 'package:finalfashiontimefrontend/animations/bottom_animation.dart';
import 'package:finalfashiontimefrontend/screens/authentication/forget_password_profile.dart';
import 'package:finalfashiontimefrontend/screens/chats-screens/message_screen.dart';
import 'package:finalfashiontimefrontend/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as https;
import 'package:shared_preferences/shared_preferences.dart';

import '../../customize_pacages/otp_text_field/otp_text_field.dart';
class ForgotPasswordOtpScreen extends StatefulWidget {
  final String email;
  final String username;
  const ForgotPasswordOtpScreen({super.key, required this.email, required this.username});

  @override
  State<ForgotPasswordOtpScreen> createState() => _ForgotPasswordOtpScreenState();
}

class _ForgotPasswordOtpScreenState extends State<ForgotPasswordOtpScreen> {
  bool loading = false;
  TextEditingController code = TextEditingController();
  GlobalKey _otpKey = GlobalKey();
  int attempts = 0;
  int resendAttempts = 0;
  Duration _remainingTime = Duration.zero;
  Timer? _timer;
  String? _timerEmail;
  String? _timerUsername;
  int totalAttempts = 0;

  @override
  void initState() {
    super.initState();
    _loadTimerState();
    // getTotalAttempts(); // Load saved timer state when screen initializes
  }

  getTotalAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    final savedAttempts = prefs.getInt('total_attempts');
    if(savedAttempts != null){
      totalAttempts = prefs.getInt('total_attempts')!;
    }
    _loadTimerState();
  }

  Future<void> _loadTimerState() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('otp_timer_email');
    final endTime = prefs.getInt('otp_timer_end');
    final savedUsername = prefs.getString('otp_timer_username');
    final otpAttempts = prefs.getString('otp_attempts');

    print("email => ${savedEmail}");
    print("time => ${endTime}");

    if(otpAttempts != null){
      print("code "+otpAttempts);
      resendAttempts = int.parse(otpAttempts);
    }
    print("Attempts "+resendAttempts.toString());

    if (savedEmail != null && savedUsername != null && endTime != null && (savedEmail == widget.email || savedUsername == widget.username)) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final remainingMillis = endTime - now;

      if (remainingMillis > 0) {
        setState(() {
          _timerEmail = savedEmail;
          _timerUsername = savedUsername;
          _remainingTime = Duration(milliseconds: remainingMillis);
          resendAttempts = 4;
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
      await prefs.setString('otp_timer_email', widget.email);
      await prefs.setString('otp_timer_username', widget.username);
      final endTime = DateTime.now().add(Duration(minutes: 10)).millisecondsSinceEpoch;
      await prefs.setInt('otp_timer_end', endTime);

      setState(() {
        _remainingTime = Duration(minutes: 10);
      });
    }

    setState(() {
      _timerEmail = widget.email;
      _timerUsername = widget.username;
      resendAttempts = 4;
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

  void _startCountdown30([bool saveState = true]) async {
    // Cancel any existing timer
    _timer?.cancel();

    if (saveState) {
      // Only set new end time if we're starting fresh
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('otp_timer_email', widget.email);
      await prefs.setString('otp_timer_username', widget.username);
      final endTime = DateTime.now().add(Duration(minutes: 30)).millisecondsSinceEpoch;
      await prefs.setInt('otp_timer_end', endTime);

      setState(() {
        _remainingTime = Duration(minutes: 30);
      });
    }

    setState(() {
      _timerEmail = widget.email;
      _timerUsername = widget.username;
      resendAttempts = 4;
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
  void _startCountdown12([bool saveState = true]) async {
    // Cancel any existing timer
    _timer?.cancel();

    if (saveState) {
      // Only set new end time if we're starting fresh
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('otp_timer_email', widget.email);
      await prefs.setString('otp_timer_username', widget.username);
      final endTime = DateTime.now().add(Duration(hours: 12)).millisecondsSinceEpoch;
      await prefs.setInt('otp_timer_end', endTime);

      setState(() {
        _remainingTime = Duration(hours: 12);
      });
    }

    setState(() {
      _timerEmail = widget.email;
      _timerUsername = widget.username;
      resendAttempts = 4;
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
          _clearTimerState12();
        }
      });
    });
  }


  Future<void> _clearTimerState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('otp_timer_email');
    await prefs.remove('otp_timer_end');
    await prefs.remove('otp_timer_username');
    await prefs.remove('otp_attempts');
    setState(() {
      _timerEmail = null;
    });
  }
  Future<void> _clearTimerState12() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('otp_timer_email');
    await prefs.remove('otp_timer_end');
    await prefs.remove('otp_timer_username');
    await prefs.remove('otp_attempts');
    await prefs.remove('total_attempts');
    setState(() {
      _timerEmail = null;
    });
  }

  verifyOtp() async {
    setState(() {
      loading = true;
    });
  //  try {
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
          "token": code.text,
        };
        https.post(
          Uri.parse("$serverUrl/password/reset/verify-token/"),
          body: body,
        ).then((value) {
          print("Response ==> ${value.body}");
          print("Response ==> ${value.statusCode.toString()}");
          if(value.statusCode == 404) {
            attempts = attempts + 1;
            setState(() {
              loading = false;
            });
            clearText();
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: primary,
                title: const Text("FashionTime",style: TextStyle(color: ascent,fontFamily: Poppins,fontWeight: FontWeight.bold),),
                content: const Text("The code is invalid or expired. Please try again, resend the code, or check your spam folder.",style: TextStyle(color: ascent,fontFamily: Poppins),),
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
          else{
            _clearTimerState();
            setState(() {
              loading = false;
            });
            String otpCode = code.text;
            Navigator.pop(context);
            debugPrint("Navigating to next screen with code: $otpCode");
            Navigator.push(
                context, MaterialPageRoute(builder: (context) =>  ForgetPasswordViaProfileScreen(
              code: otpCode,
              email: widget.email,
              username: widget.username,
            )));
            clearText();
          }
        });
      }
  }

  resendCode() async{
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      loading = true;
      attempts = 0;
    });
    resendAttempts = resendAttempts + 1;
    prefs.setString('otp_attempts', resendAttempts.toString());
    if(resendAttempts >= 4){
      setState(() {
        loading = false;
      });
      _startCountdown();
      // if(totalAttempts == 0){
      //   _startCountdown();
      // }
      // else if(totalAttempts == 3){
      //   _startCountdown30();
      // }
      // else if(totalAttempts == 6){
      //   _startCountdown12();
      // }
      return;
    }
    String url='$serverUrl/password/reset/';
    try{
      final response= await https.post(Uri.parse(url),body: {
        'email':widget.email.toLowerCase()
      });
      if(response.statusCode==200){
        setState(() {
          loading = false;
        });
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
      }
      else{
        setState(() {
          loading = false;
        });
        debugPrint("error received in api============> ${response.statusCode}");
      }
    }
    catch(e){
      setState(() {
        loading = false;
      });
      debugPrint("exception occurred========>${e.toString()}");
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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
                      Image.asset("assets/logo.png",height: 150,),
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
                if((resendAttempts >= 4) && _timerEmail == widget.email) SizedBox(height: 20,),
                WidgetAnimator(
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.7,
                    child: OtpTextField(
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')), // Allow A-Z and 0-9
                        UpperCaseTextFormatter(), // Force uppercase
                      ],
                      clearText: true,
                      enabled: !((attempts >= 3 || resendAttempts >= 4) || _timerEmail == widget.email),
                      textStyle: TextStyle(
                        color:Colors.pink.shade500,
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
                        }
                        //handle validation or checks here
                      },
                      onSubmit: (String verificationCode){
                        debugPrint("all otp fields filled");
                          verifyOtp();
                        //Navigator.pushReplacement(context,MaterialPageRoute(builder: (context) => ChangePassword()));
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
                    loading ? const SpinKitCircle(color: ascent,size: 70,) : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          height: 46,
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
                                        borderRadius: BorderRadius.circular(15.0),
                                      )
                                  ),
                                  backgroundColor: MaterialStateProperty.all(Colors.transparent),
                                  shadowColor: MaterialStateProperty.all(Colors.transparent),
                                  padding: MaterialStateProperty.all(EdgeInsets.only(
                                      top: 13,bottom: 13,
                                      left:MediaQuery.of(context).size.width * 0.2,right: MediaQuery.of(context).size.width * 0.2)),
                                  textStyle: MaterialStateProperty.all(
                                      const TextStyle(fontSize: 14, color: Colors.white,fontFamily: Poppins))),
                              onPressed: (resendAttempts >= 4) ? null : () {
                                 resendCode();
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
