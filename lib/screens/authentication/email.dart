import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:finalfashiontimefrontend/animations/bottom_animation.dart';
import 'package:finalfashiontimefrontend/screens/authentication/forget_password_otp_screen.dart';
import 'package:finalfashiontimefrontend/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as https;
import 'package:shared_preferences/shared_preferences.dart';

import '../../customize_pacages/capcha/client_verify/slider_captcha.dart';

class EmailScreen extends StatefulWidget {
  const EmailScreen({super.key});

  @override
  State<EmailScreen> createState() => _EmailScreenState();
}

bool loading = false;

TextEditingController email = TextEditingController();

class _EmailScreenState extends State<EmailScreen> {
  String? emailError;
  bool loading = false;
  bool isSendMail = true;
  bool checked = false;
  bool isCaptcha = false;
  String textError = "";
  int _captchaRetryCount = 0;
  // timer
  int attempts = 0;
  int resendAttempts = 0;
  Duration _remainingTime = Duration.zero;
  Timer? _timer;
  String? _timerEmail;
  String? _timerUsername;
  int totalAttempts = 0;

  // getCashedData() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final savedEmail = prefs.getString('otp_timer_email');
  //   final endTime = prefs.getInt('otp_timer_end');
  //   print("email => ${savedEmail}");
  //   print("time => ${endTime}");
  //   if(savedEmail != null){
  //     isSendMail = false;
  //   }
  //   print("data cashed ${savedEmail} ${isSendMail}");
  // }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
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

    if (otpAttempts != null) {
      print("code " + otpAttempts);
      resendAttempts = int.parse(otpAttempts);
    }
    print("Attempts " + resendAttempts.toString());

    if (savedEmail != null && savedUsername != null && endTime != null) {
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
        _startCountdown(
            savedEmail, savedUsername, false); // Continue existing timer
      } else {
        // Timer expired - clear saved state
        _clearTimerState();
      }
    }
  }

  void _startCountdown(email, username, [bool saveState = true]) async {
    // Cancel any existing timer
    _timer?.cancel();

    if (saveState) {
      // Only set new end time if we're starting fresh
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('otp_timer_email', email);
      await prefs.setString('otp_timer_username', username);
      final endTime =
          DateTime.now().add(Duration(minutes: 15)).millisecondsSinceEpoch;
      await prefs.setInt('otp_timer_end', endTime);

      setState(() {
        _remainingTime = Duration(minutes: 15);
      });
    }

    setState(() {
      _timerEmail = email;
      _timerUsername = username;
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

  resetPassword() async {
    setState(() {
      loading = true;
    });
    String url = '$serverUrl/password/reset/';
    try {
      if (email.text == "") {
        setState(() {
          loading = false;
        });
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: primary,
            title: const Text(
              "FashionTime",
              style: TextStyle(
                  color: ascent,
                  fontFamily: Poppins,
                  fontWeight: FontWeight.bold),
            ),
            content: const Text(
              "Please fill all the fields.",
              style: TextStyle(color: ascent, fontFamily: Poppins),
            ),
            actions: [
              TextButton(
                child: const Text("Okay",
                    style: TextStyle(color: ascent, fontFamily: Poppins)),
                onPressed: () {
                  setState(() {
                    Navigator.pop(context);
                  });
                },
              ),
            ],
          ),
        );
      }
      // else if(email.text.contains("@") == false){
      //   setState(() {
      //     loading = false;
      //   });
      //   showDialog(
      //     context: context,
      //     builder: (context) => AlertDialog(
      //       backgroundColor: primary,
      //       title: const Text("FashionTime",style: TextStyle(color: ascent,fontFamily: Poppins,fontWeight: FontWeight.bold),),
      //       content: const Text("Email is not correct.Please add @",style: TextStyle(color: ascent,fontFamily: Poppins),),
      //       actions: [
      //         TextButton(
      //           child: const Text("Okay",style: TextStyle(color: ascent,fontFamily: Poppins)),
      //           onPressed:  () {
      //             setState(() {
      //               Navigator.pop(context);
      //             });
      //           },
      //         ),
      //       ],
      //     ),
      //   );
      // }
      // else if(email.text.contains(".com") == false){
      //   setState(() {
      //     loading = false;
      //   });
      //   showDialog(
      //     context: context,
      //     builder: (context) => AlertDialog(
      //       backgroundColor: primary,
      //       title: const Text("FashionTime",style: TextStyle(color: ascent,fontFamily: Poppins,fontWeight: FontWeight.bold),),
      //       content: const Text("Email is not correct.Please add .com",style: TextStyle(color: ascent,fontFamily: Poppins),),
      //       actions: [
      //         TextButton(
      //           child: const Text("Okay",style: TextStyle(color: ascent,fontFamily: Poppins)),
      //           onPressed:  () {
      //             setState(() {
      //               Navigator.pop(context);
      //             });
      //           },
      //         ),
      //       ],
      //     ),
      //   );
      // }
      else {
        final response = await https.post(Uri.parse(url), body: {
          'email': email.text.toLowerCase(),
          'send_email': isSendMail.toString()
        });
        if (response.statusCode == 200) {
          resendAttempts = resendAttempts + 1;
          print("response ${response.body}");
          print(
              "username => ${jsonDecode(response.body)["code"].split(" ")[0]}");
          print(
              "email => ${jsonDecode(response.body)["code"].split("with")[1]}");
          String myUsername = jsonDecode(response.body)["code"].split(" ")[0];
          String myEmail = jsonDecode(response.body)["code"].split(" ")[6];
          String code = jsonDecode(response.body)["code"].split(":")[1];
          print("username after => ${myUsername}");
          print("email after => ${myEmail}");
          print("code after => ${code}");
          if (resendAttempts >= 4) {
            setState(() {
              loading = false;
            });
            _startCountdown(myEmail, myUsername);
            return;
          }
          sendResetPasswordEmail(myUsername, myEmail, code);
          // Navigator.push(context, MaterialPageRoute(builder: (context) => ForgotPasswordOtpScreen(
          //   email: myEmail,
          //   username: myUsername,
          // ),)).then((val){
          //   getCashedData();
          // });
        } else {
          _clearTimerState();
          setState(() {
            loading = false;
            emailError =
                "We couldn't find an account with that username\nor email address.";
          });
          debugPrint(
              "error received in api============> ${response.statusCode}");
        }
      }
    } catch (e) {
      setState(() {
        loading = false;
      });
      debugPrint("exception occurred========>${e.toString()}");
    }
  }

  void validateEmail() {
    setState(() {
      if (email.text == '') {
        emailError = "Oops! You forgot your username or email.";
      }
      // else{
      //   emailError = isEmailValid(email.text) ? null : "Invalid email or username format.";
      // }
    });
  }

  bool isEmailValid(String value) {
    // Use regex for simple email validation
    final RegExp emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(value);
    //
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
            image: AssetImage("assets/background.jpg"), fit: BoxFit.fill),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: WidgetAnimator(
          SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.1,
                ),
                const SizedBox(
                  height: 30,
                ),
                WidgetAnimator(
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        "assets/logo.png",
                        height: 150,
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 50,
                ),
                WidgetAnimator(Text(
                  'Forgot your password?',
                  style: TextStyle(
                      color: Colors.black54,
                      fontFamily: Poppins,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                )),
                SizedBox(
                  height: 20,
                ),
                if (resendAttempts >= 4)
                  WidgetAnimator(Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "You’ve tried too many times. Please wait.",
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.red,
                            fontFamily: Poppins),
                      )
                    ],
                  )),
                if (resendAttempts >= 4)
                  SizedBox(
                    height: 20,
                  ),
                if (resendAttempts >= 4)
                  WidgetAnimator(Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Resend verification link in ",
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                            fontFamily: Poppins),
                      ),
                      Text(
                        '${_remainingTime.inMinutes.toString().padLeft(2, '0')}:'
                        '${(_remainingTime.inSeconds % 60).toString().padLeft(2, '0')}',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                            fontFamily: Poppins),
                      )
                    ],
                  )),
                if (resendAttempts >= 4)
                  SizedBox(
                    height: 20,
                  ),
                WidgetAnimator(Text(
                  'Enter your username or email address.',
                  style: TextStyle(
                      color: Colors.black54,
                      fontFamily: Poppins,
                      fontSize: 14.3),
                )),
                const SizedBox(height: 10),
                WidgetAnimator(
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.7,
                    child: TextField(
                      inputFormatters: [
                        FilteringTextInputFormatter.deny(RegExp(r'\s')),
                      ],
                      controller: email,
                      style: const TextStyle(
                          color: Colors.pink, fontFamily: Poppins),
                      onChanged: (_) {
                        setState(() {
                          emailError = null;
                        });
                      },
                      decoration: InputDecoration(
                        hintStyle: TextStyle(
                            color: Colors.black54,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            fontFamily: Poppins),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.black54),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.pink),
                        ),
                        //enabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        //disabledBorder: InputBorder.none,
                        alignLabelWithHint: true,
                        hintText: "Username or Email",
                        errorText: emailError,
                        errorStyle: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontFamily: Poppins,
                            fontSize: 10),
                      ),
                      cursorColor: Colors.pink,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                if (isCaptcha == false)
                  Container(
                    width: MediaQuery.of(context).size.width * 0.82,
                    child: CheckboxListTile(
                      side: BorderSide(color: Colors.black54),
                      checkColor: ascent,
                      activeColor: primary,
                      title: Text(
                        'I am human',
                        style: TextStyle(
                            color: Colors.black54, fontFamily: Poppins),
                      ),
                      value: checked,
                      onChanged: (bool? value) async {
                        setState(() {
                          checked = value!;
                        });
                        await Future.delayed(const Duration(seconds: 1));
                        setState(() {
                          isCaptcha = value!;
                        });
                      },
                      controlAffinity: ListTileControlAffinity
                          .leading, // Position of checkbox
                    ),
                  ),
                const SizedBox(
                  height: 10,
                ),
                if (textError.isEmpty == false)
                  Container(
                    width: MediaQuery.of(context).size.width * 0.7,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          textError,
                          style: TextStyle(
                              color: Colors.red,
                              fontFamily: Poppins,
                              fontWeight: FontWeight.bold,
                              fontSize: 10),
                        )
                      ],
                    ),
                  ),
                if (textError.isEmpty == false)
                  const SizedBox(
                    height: 10,
                  ),
                if (isCaptcha == true)
                  Container(
                    width: 300,
                    height: 500,
                    child: SliderCaptcha(
                      key: ValueKey(_captchaRetryCount),
                      colorBar: Colors.black54,
                      titleStyle: TextStyle(fontFamily: Poppins),
                      title: "Slide to complete the puzzle",
                      captchaSize: 30,
                      slideContainerDecoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                          color: primary),
                      onConfirm: (value) async {
                        print("Value ==> ${value}");
                        if (value) {
                          print("Captcha success");
                          setState(() {
                            textError = "";
                            isCaptcha = false;
                            _captchaRetryCount = 0;
                          });
                        } else {
                          setState(() {
                            _captchaRetryCount++;
                            textError =
                                "Please complete the puzzle to verify you're\nhuman.";
                          });
                          print("Captcha failed");
                        }
                      },
                    ),
                  ),
                if (isCaptcha == false)
                  WidgetAnimator(Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      loading == true
                          ? const SpinKitCircle(
                              color: ascent,
                              size: 70,
                            )
                          : Container(
                              height: 40,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15.0),
                                  gradient: (resendAttempts >= 4)
                                      ? LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.topRight,
                                          stops: const [0.0, 0.99],
                                          tileMode: TileMode.clamp,
                                          colors: <Color>[
                                            Colors.grey,
                                            Colors.grey
                                          ])
                                      : LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.topRight,
                                          stops: const [0.0, 0.99],
                                          tileMode: TileMode.clamp,
                                          colors: <Color>[primary, secondary])),
                              child: ElevatedButton(
                                  style: ButtonStyle(
                                      shape: MaterialStateProperty.all<
                                              RoundedRectangleBorder>(
                                          RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12.0),
                                      )),
                                      backgroundColor: MaterialStateProperty.all(
                                          Colors.transparent),
                                      shadowColor: MaterialStateProperty.all(
                                          Colors.transparent),
                                      padding: MaterialStateProperty.all(EdgeInsets.only(
                                          top: 8,
                                          bottom: 8,
                                          left: MediaQuery.of(context).size.width *
                                              0.1,
                                          right:
                                              MediaQuery.of(context).size.width *
                                                  0.1)),
                                      textStyle: MaterialStateProperty.all(
                                          const TextStyle(
                                              fontSize: 12,
                                              color: Colors.white,
                                              fontFamily: Poppins))),
                                  onPressed: (resendAttempts >= 4)
                                      ? null
                                      : () {
                                          validateEmail();
                                          if (checked == true) {
                                            if (emailError == null) {
                                              resetPassword();
                                            }
                                          } else {
                                            setState(() {
                                              textError =
                                                  "Please complete the puzzle to verify you're\nhuman.";
                                            });
                                          }
                                        },
                                  child: const Text(
                                    'Send Verification Link',
                                    style: TextStyle(
                                        fontSize: 16,
                                        color: ascent,
                                        fontWeight: FontWeight.w700,
                                        fontFamily: Poppins),
                                  )),
                            ),
                    ],
                  )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> sendResetPasswordEmail(userUsername, userEmail, code) async {
    print("My Username ==> ${userUsername}");
    print("My Email ==> ${userEmail}");
    print("My Code ==> ${code}");
    final url =
        Uri.parse('https://api.mailgun.net/v3/fashiontime.app/messages');

    // Basic Authentication credentials
    final username = 'api';
    final password = 'Your_Api_key_here';
    final credentials = base64Encode(utf8.encode('$username:$password'));

    String resetLink =
        "https://fashiontime.app/reset-password/${userUsername}/${userEmail}/${code}/${DateTime.now()}";

    // HTML content with replaced placeholders
    // HTML content with styled clickable link
    final htmlContent = '''
    <html>
      <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
        <p>Hi <b>$userUsername</b> 👋,</p>
        
        <p>No worries, forgetting your password happens to the best of us.<br>
        Just click the link below to reset your password. Easy peasy.</p>
        
        <p>🔐 This link is valid for <b>15 minutes</b>, so don't wander off for too long!</p>
        
        <p>If it expires, simply request a new one, we'll be right here.</p>
        
        <div style="margin: 20px 0;">
          <a href="$resetLink" 
             style="display: inline-block;
                    padding: 5px 20px;
                    background-color: #FEAEC9;
                    color: white;
                    font-weight: bold;
                    text-decoration: none;
                    border-radius: 4px;
                    cursor: pointer;
                    text-align: center;">
             👉 Reset my password
          </a>
        </div>
        
        <p>Didn't request this?Then you can safely ignore this email.<br>
        No changes will be made unless you click the link.</p>
        
        <p>Take care,<br>
        <b>The FashionTime Team</b></p>
      </body>
    </html>
  ''';

    try {
      final response = await https.post(
        url,
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'from': 'noreply@fashiontime.app',
          'to': '${userEmail}',
          'subject': 'Oops! Forgot your FashionTime password? 🔐',
          'html': htmlContent,
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          loading = false;
        });
        print('Email sent successfully');
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: primary,
            title: const Text(
              "Check your inbox!",
              style: TextStyle(
                  color: ascent,
                  fontFamily: Poppins,
                  fontWeight: FontWeight.bold),
            ),
            content: const Text(
              "We’ve sent a verification link to the email address associated with your account for resetting your password.",
              style: TextStyle(color: ascent, fontFamily: Poppins),
            ),
            actions: [
              TextButton(
                child: const Text("Okay",
                    style: TextStyle(color: ascent, fontFamily: Poppins)),
                onPressed: () {
                  setState(() {
                    Navigator.pop(context);
                  });
                },
              ),
            ],
          ),
        );
      } else {
        setState(() {
          loading = false;
        });
        print('Failed to send email. Status code: ${response.statusCode}');
        print('Response: ${response.body}');
      }
    } catch (e) {
      setState(() {
        loading = false;
      });
      print('Error sending email: $e');
    }
  }
}
