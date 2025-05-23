import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:finalfashiontimefrontend/animations/bottom_animation.dart';
import 'package:finalfashiontimefrontend/screens/authentication/login_screen.dart';
import 'package:finalfashiontimefrontend/screens/authentication/otp_screen.dart';
import 'package:finalfashiontimefrontend/utils/constants.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import '../../customize_pacages/capcha/client_verify/slider_captcha.dart';

class Register extends StatefulWidget {
  const Register({Key? key}) : super(key: key);

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  bool terms = true;
  int captchaRetryCount = 0;
  TextEditingController name = TextEditingController();
  TextEditingController email = TextEditingController();
  TextEditingController phone = TextEditingController();
  TextEditingController password = TextEditingController();
  TextEditingController password1 = TextEditingController();
  TextEditingController username = TextEditingController();
  String gender = "Male";
  bool loading = false;
  bool eye = true;
  bool eye1 = true;
  bool isUserNameRepeated=false;
  String? emailError;
  String? passwordError;
  String? passwordError1;
  String? nameError;
  String? userNameError;
  bool checked = false;
  bool isCaptcha = false;
  String textError = "";

  // timer
  int attempts = 0;
  int resendAttempts = 0;
  Duration _remainingTime = Duration.zero;
  Timer? _timer;
  String? _timerEmail;
  String? _timerUsername;
  int totalAttempts = 0;

  String ipAddress = "";
  String deviceName = "";
  String deviceAddress = "";

  bool isEmailValid(String value) {
    // Use regex for simple email validation
    final RegExp emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(value);
    //
  }

  void validateEmail() {
    setState(() {
      if(email.text==''){
        emailError="Oops! You forgot your email.";
      }
      else{
      emailError = isEmailValid(email.text) ? null : "Invalid email format.";}
    });
  }
  void checkUsername(){
    setState(() {
      if(isUserNameRepeated==true){
        userNameError="Please select a unique user name.";
      }
      if(username.text.length < 3){
        userNameError="Username must be at least 3 letters long\nand may only contain alphabets,numbers,\ndots (.) and hyphens (-).";
      }
    });
  }
  bool isPasswordValid(String value) {
    // Use regex for simple email validation
    final RegExp passwordRegex = RegExp(r'^(?=.*[A-Z])(?=.*[\d_!@#$%^&*()-+=]).{7,}$');
    return passwordRegex.hasMatch(value);
  }
  void validatePassword() {
    setState(() {
      if(password.text == ''){
        passwordError="Oops! Please set a password.";
      }
      else if(password.text != password1.text){
        passwordError ="Oops! Those passwords aren’t twins.";
        passwordError1 ="Oops! Those passwords aren’t twins.";
      }
      else{
        passwordError = isPasswordValid(password.text) ? null : "The password must contain at least 7 characters, one upper case character, and at least one symbol or number.";
      }
    });
  }
  void validateName() {
    setState(() {
      nameError = isNameValid(name.text) ? null : "Name is required.";
    });
  }
  bool isNameValid(String value) {
    // Use regex for simple email validation
    if(value.isNotEmpty){
      return true;
    }
    else{
      return false;
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getDeviceInfo();
  }

  getDeviceInfo() async {
    ipAddress = await getIpAddress();
    deviceName = await getDeviceName();
    // print('IP Address: $ip');
    // print('Device Name: $name');
    getAddressFromLatLong();
    _loadTimerState();
  }

  Future<String> getIpAddress() async {
    for (var interface in await NetworkInterface.list()) {
      for (var addr in interface.addresses) {
        if (addr.type == InternetAddressType.IPv4) {
          return addr.address;
        }
      }
    }
    return 'No IP address found';
  }

  Future<String> getDeviceName() async {
    final deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.model ?? 'Unknown Android Device';
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.name ?? 'Unknown iOS Device';
    } else {
      return 'Unknown Platform';
    }
  }

  Future<void> getAddressFromLatLong() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check location services
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Location services are disabled.');
      return;
    }

    // Check permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('Location permissions are denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('Location permissions are permanently denied.');
      return;
    }

    // Get current position
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    print('Latitude: ${position.latitude}, Longitude: ${position.longitude}');

    // Get address
    List<Placemark> placemarks =
    await placemarkFromCoordinates(position.latitude, position.longitude);

    if (placemarks.isNotEmpty) {
      Placemark place = placemarks[0];
      //print('Address: ${place.street}, ${place.locality}, ${place.country}');
      deviceAddress = '${place.street}, ${place.locality}, ${place.country}';
    } else {
      print('No address found');
    }
    print('IP Address: $ipAddress');
    print('Device Name: $deviceName');
    print('Device Address: $deviceAddress');
  }

  Future<void> _loadTimerState() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('reg_timer_email');
    final endTime = prefs.getInt('reg_timer_end');
    final savedUsername = prefs.getString('reg_timer_username');
    final otpAttempts = prefs.getString('reg_attempts');

    print("email => ${savedEmail}");
    print("time => ${endTime}");

    if(otpAttempts != null){
      print("code "+otpAttempts);
      resendAttempts = int.parse(otpAttempts);
    }
    print("Attempts "+resendAttempts.toString());

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
        _startCountdown(savedEmail,savedUsername,false); // Continue existing timer
      } else {
        // Timer expired - clear saved state
        _clearTimerState();
      }
    }
  }

  void _startCountdown(email1,username1,[bool saveState = true]) async {
    // Cancel any existing timer
    _timer?.cancel();

    if (saveState) {
      // Only set new end time if we're starting fresh
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('reg_timer_email', email.text);
      await prefs.setString('reg_timer_username', username.text);
      final endTime = DateTime.now().add(Duration(minutes: 15)).millisecondsSinceEpoch;
      await prefs.setInt('reg_timer_end', endTime);

      setState(() {
        _remainingTime = Duration(minutes: 15);
      });
    }

    setState(() {
      _timerEmail = email.text;
      _timerUsername = username.text;
      resendAttempts = 4;
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
    await prefs.remove('reg_timer_email');
    await prefs.remove('reg_timer_end');
    await prefs.remove('reg_timer_username');
    await prefs.remove('reg_attempts');
    setState(() {
      _timerEmail = null;
    });
  }

  signUp() async {
    setState(() {
      loading = true;
    });
    try {
      if(email.text == ""  || name.text == "" || password.text == "" || gender == ""|| username.text=="") {
        setState(() {
          loading = false;
        });
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: primary,
            title: const Text("FashionTime",style: TextStyle(color: ascent,fontFamily: Poppins,fontWeight: FontWeight.bold),),
            content: const Text("Please fill all the fields",style: TextStyle(color: ascent,fontFamily: Poppins),),
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
        if(password.text.length <= 6){
          setState(() {
            loading = false;
          });
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: primary,
              title: const Text("FashionTime",style: TextStyle(color: ascent,fontFamily: Poppins,fontWeight: FontWeight.bold),),
              content: const Text("The password must be at least 7 characters long",style: TextStyle(color: ascent,fontFamily: Poppins),),
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
          FirebaseMessaging.instance.getToken().then((value1) {
            Map<String, String> body = {
              "email": email.text.toLowerCase(),
              "name": name.text,
              "username":username.text.toLowerCase(),
              "password": password.text,
              "gender": gender,
              "phone_number": phone.text,
              "fcmToken": value1!,
              "device": deviceName,
              "location":deviceAddress,
              "ipaddress": ipAddress
            };
            post(
              Uri.parse("$serverUrl/api/signup/"),
              body: body,
            ).then((value) {
              print(" user created with Response ==> ${json.decode(value.body)}");
              if (json.decode(value.body).containsKey("username") && json.decode(value.body)["username"] is List){
                setState(() {
                  loading = false;
                });
                isUserNameRepeated=true;
                //_clearTimerState();
                print("username bool $isUserNameRepeated");
              }
              if (json.decode(value.body).containsKey("user") == true) {
                resendAttempts = resendAttempts + 1;
                print("verification code");
                if(resendAttempts >= 4){
                  setState(() {
                    loading = false;
                  });
                  _startCountdown(email.text,username.text);
                  return;
                }
                print("code ${json.decode(value.body)["message"].split(" ")[7].split(".")[0]}");
                sendEmail(username.text.toLowerCase(),email.text.toLowerCase(),json.decode(value.body)["message"].split(" ")[7].split(".")[0]);
                // sendEmail(json.decode(value.body)["user"]["verification_code"],
                //     json.decode(value.body),password.text);
              }
              else if (json.decode(value.body).containsKey("email") == true) {
                setState(() {
                  loading = false;
                });
                _clearTimerState();
                showDialog(
                  context: context,
                  builder: (context) =>
                      AlertDialog(
                        backgroundColor: primary,
                        title: const Text("FashionTime", style: TextStyle(
                            color: ascent,
                            fontFamily: Poppins,
                            fontWeight: FontWeight.bold),),
                        content: const Text("User with this email already exists.",
                          style: TextStyle(
                              color: ascent, fontFamily: Poppins),),
                        actions: [
                          TextButton(
                            child: const Text("Okay", style: TextStyle(
                                color: ascent, fontFamily: Poppins)),
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
              else {
                setState(() {
                  loading = false;
                });
               // _clearTimerState();
                print("Code not sent");
              }
            }).catchError((error) {
              setState(() {
                loading = false;
              });
              print("$error");
              showDialog(
                context: context,
                builder: (context) =>
                    AlertDialog(
                      backgroundColor: primary,
                      title: const Text("FashionTime", style: TextStyle(
                          color: ascent,
                          fontFamily: Poppins,
                          fontWeight: FontWeight.bold),),
                      content: const Text("Invalid Credentials", style: TextStyle(
                          color: ascent, fontFamily: Poppins),),
                      actions: [
                        TextButton(
                          child: const Text("Okay", style: TextStyle(
                              color: ascent, fontFamily: Poppins)),
                          onPressed: () {
                            setState(() {
                              Navigator.pop(context);
                            });
                          },
                        ),
                      ],
                    ),
              );
            });
          });
        }
      }
    } catch(e){
      setState(() {
        loading = false;
      });
      print(e);
    }
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel timer if it's running
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
                const SizedBox(height: 60,),
                WidgetAnimator(
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                          child: Image.asset("assets/logo.png",height: MediaQuery.of(context).size.height * 0.20,)
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20,),
                if(resendAttempts >= 4) WidgetAnimator(
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("You’ve tried too many times. Please wait.",
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
                if(resendAttempts >= 4) SizedBox(height: 20,),
                if(resendAttempts >= 4) WidgetAnimator(
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
                if(resendAttempts >= 4) SizedBox(height: 20,),
                WidgetAnimator(
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.7,
                    child: TextField(
                      controller: name,
                      style: const TextStyle(
                          color: Colors.pink,
                          fontFamily: Poppins
                      ),
                      decoration: InputDecoration(
                          hintStyle: const TextStyle(
                              color: Colors.black54,
                              fontSize: 17,
                              fontWeight: FontWeight.w400,
                              fontFamily: Poppins
                          ),
                          enabledBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.black54),
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.pink),
                          ),
                          //enabledBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          //disabledBorder: InputBorder.none,
                          alignLabelWithHint: true,
                          hintText: "Enter Your Name",
                        //errorText: nameError,
                        errorStyle: TextStyle(color: Colors.red,fontWeight: FontWeight.bold,fontFamily: Poppins,fontSize: 10),
                      ),
                      cursorColor: Colors.pink,
                    ),
                  ),
                ),
                const SizedBox(height: 10,),
                WidgetAnimator(
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.7,
                    child: TextField(
                      onChanged: (value){
                        setState(() {
                          emailError = null;
                        });
                      },
                      inputFormatters: [
                        FilteringTextInputFormatter.deny(
                            RegExp(r'\s')),
                      ],
                      controller: email,
                      style: const TextStyle(
                          color: Colors.pink,
                          fontFamily: Poppins
                      ),
                      decoration: InputDecoration(
                          hintStyle: const TextStyle(
                              color: Colors.black54,
                              fontSize: 17,
                              fontWeight: FontWeight.w400,
                              fontFamily: Poppins
                          ),
                          enabledBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.black54),
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.pink),
                          ),
                          //enabledBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          //disabledBorder: InputBorder.none,
                          alignLabelWithHint: true,
                          hintText: "Enter Your Email",
                        errorText: emailError,
                        errorStyle: TextStyle(color: Colors.red,fontWeight: FontWeight.bold,fontFamily: Poppins,fontSize: 10),
                      ),
                      cursorColor: Colors.pink,
                    ),
                  ),
                ),
                const SizedBox(height: 10,),
                WidgetAnimator(
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.7,
                    child: TextField(
                      onChanged: (value){
                        setState(() {
                          userNameError = null;
                        });
                      },
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9a-zA-Z\.\-]')),
                        // FilteringTextInputFormatter.allow(RegExp("[0-9a-zA-Z.-_]")),
                      ],
                      controller: username,
                      style: const TextStyle(
                          color: Colors.pink,
                          fontFamily: Poppins
                      ),
                      decoration: InputDecoration(
                          hintStyle: const TextStyle(
                              color: Colors.black54,
                              fontSize: 17,
                              fontWeight: FontWeight.w400,
                              fontFamily: Poppins
                          ),
                          enabledBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.black54),
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.pink),
                          ),
                          //enabledBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          //disabledBorder: InputBorder.none,
                          alignLabelWithHint: true,
                          hintText: "Enter Your Username",
                          errorText: userNameError,
                        errorStyle: TextStyle(color: Colors.red,fontWeight: FontWeight.bold,fontFamily: Poppins,fontSize: 10),
                      ),
                      cursorColor: Colors.pink,
                    ),
                  ),
                ),
                const SizedBox(height: 10,),
                WidgetAnimator(
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.7,
                    child: TextField(
                      onChanged: (value){
                        setState(() {
                          passwordError = null;
                          passwordError1 = null;
                        });
                      },
                      controller: password,
                      obscureText: eye,
                      style: const TextStyle(
                          color: Colors.pink,
                          fontFamily: Poppins
                      ),
                      decoration: InputDecoration(
                          suffixIcon: IconButton(
                            icon: Icon(eye == true ?Icons.visibility:Icons.visibility_off,color: Colors.black54,),
                            onPressed: (){
                              setState(() {
                                eye = !eye;
                              });
                            },
                          ),
                          hintStyle: const TextStyle(
                              color: Colors.black54,
                              fontSize: 17,
                              fontWeight: FontWeight.w400,
                              fontFamily: Poppins
                          ),
                          enabledBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.black54),
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.pink),
                          ),
                          //enabledBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          errorText: passwordError,
                          errorMaxLines: 3,
                          errorStyle: TextStyle(color: Colors.red,fontWeight: FontWeight.bold,fontFamily: Poppins,fontSize: 10),
                          //disabledBorder: InputBorder.none,
                          alignLabelWithHint: true,
                          hintText: "Password"
                      ),
                      cursorColor: Colors.pink,
                    ),
                  ),
                ),
                const SizedBox(height: 10,),
                WidgetAnimator(
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.7,
                    child: TextField(
                      onChanged: (value){
                        setState(() {
                          passwordError1 = null;
                          passwordError = null;
                        });
                      },
                      controller: password1,
                      obscureText: eye1,
                      style: const TextStyle(
                          color: Colors.pink,
                          fontFamily: Poppins
                      ),
                      decoration: InputDecoration(
                          suffixIcon: IconButton(
                            icon: Icon(eye1 == true ?Icons.visibility:Icons.visibility_off,color: Colors.black54,),
                            onPressed: (){
                              setState(() {
                                eye1 = !eye1;
                              });
                            },
                          ),
                          hintStyle: const TextStyle(
                              color: Colors.black54,
                              fontSize: 17,
                              fontWeight: FontWeight.w400,
                              fontFamily: Poppins
                          ),
                          enabledBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.black54),
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.pink),
                          ),
                          //enabledBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          errorText: passwordError1,
                          errorStyle: TextStyle(color: Colors.red,fontWeight: FontWeight.bold,fontFamily: Poppins,fontSize: 10),
                          errorMaxLines: 3,
                          //disabledBorder: InputBorder.none,
                          alignLabelWithHint: true,
                          hintText: "Confirm Password"
                      ),
                      cursorColor: Colors.pink,
                    ),
                  ),
                ),
                const SizedBox(height: 10,),
                if(isCaptcha == false) Container(
                  width: MediaQuery.of(context).size.width * 0.82,
                  child: CheckboxListTile(
                    side: BorderSide(color: Colors.black54),
                    checkColor: ascent,
                    activeColor: primary,
                    title: Text('I am human',style: TextStyle(color: Colors.black54,fontFamily: Poppins),),
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
                    controlAffinity: ListTileControlAffinity.leading, // Position of checkbox
                  ),
                ),
                const SizedBox(height: 10,),
                if(textError.isEmpty == false) Container(
                  width: MediaQuery.of(context).size.width * 0.7,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(textError,style: TextStyle(color: Colors.red,fontFamily: Poppins,fontWeight: FontWeight.bold,fontSize: 10),)
                    ],
                  ),
                ),
                if(textError.isEmpty == false) const SizedBox(height: 10,),
                if(isCaptcha == true) Container(
                  width: 300,
                  child: SliderCaptcha(
                    key: ValueKey(captchaRetryCount),
                    colorBar: Colors.black54,
                    titleStyle: TextStyle(fontFamily: Poppins),
                    title: "Slide to complete the puzzle",
                    captchaSize: 30,
                    slideContainerDecoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                        color: primary
                    ),
                    onConfirm: (value) async {
                      print("Value ==> ${value}");
                      if (value) {
                        print("Captcha success");
                        setState(() {
                          textError = "";
                          isCaptcha = false;
                          captchaRetryCount = 0;
                        });
                      } else {
                        setState(() {
                          captchaRetryCount++;
                          textError = "Please complete the puzzle to verify you're\nhuman.";
                        });
                        print("Captcha failed");
                      }
                    },
                  ),
                ),
                if(isCaptcha == true) const SizedBox(height: 10,),
                if(isCaptcha == false)GestureDetector(
                  onTap: (){
                    _launchURL();
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        child: AutoSizeText("By signing up, you agree to our ",
                          maxLines: 2,
                          style: TextStyle(
                            color: Colors.black54,
                            fontFamily: Poppins,
                          ),),
                      ),
                    ],
                  ),
                ),
                if(isCaptcha == false)const SizedBox(height: 10,),
                if(isCaptcha == false)GestureDetector(
                  onTap: (){
                    _launchURL();
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Terms",style: TextStyle(
                    color: Colors.black54,
                    fontFamily: Poppins,
                        fontWeight: FontWeight.bold
                  ),),
                      Text(" &",style: TextStyle(
                        color: Colors.black54,
                        fontFamily: Poppins,
                      ),),
                      Text(" Conditions",style: TextStyle(
                        color: Colors.black54,
                        fontFamily: Poppins,
                          fontWeight: FontWeight.bold
                      ),)
                    ],
                  ),
                ),
                if(isCaptcha == false)const SizedBox(height: 10,),
                if(isCaptcha == false)GestureDetector(
                  onTap: (){
                    _launchPolicy();
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(" Privacy Policy",style: TextStyle(
                          color: Colors.black54,
                          fontFamily: Poppins,
                          fontWeight: FontWeight.bold
                      ),)
                    ],
                  ),
                ),
                if(isCaptcha == false)const SizedBox(height: 8,),
                if(isCaptcha == false)GestureDetector(
                  onTap: (){
                    _launchEula();
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(" End User License Agreement",style: TextStyle(
                          color: Colors.black54,
                          fontFamily: Poppins,
                          fontWeight: FontWeight.bold
                      ),)
                    ],
                  ),
                ),
                if(isCaptcha == false) const SizedBox(height: 10,),
                if(isCaptcha == false)GestureDetector(
                  onTap: (){
                    _launchChild();
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(" Child Sexual Abuse And Exploitation Policy",style: TextStyle(
                          color: Colors.black54,
                          fontFamily: Poppins,
                          fontWeight: FontWeight.bold
                      ),)
                    ],
                  ),
                ),
                if(isCaptcha == false) const SizedBox(height: 10,),
                if(isCaptcha == false) WidgetAnimator(
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                       loading == true ?  const SpinKitCircle(color: ascent,size: 70,) : Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
                            height: 45,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12.0),
                                gradient:(resendAttempts >= 4) ? LinearGradient(
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
                                        top: 4,bottom: 4,
                                        left:MediaQuery.of(context).size.width * 0.22,right: MediaQuery.of(context).size.width * 0.22)),
                                    textStyle: MaterialStateProperty.all(
                                        const TextStyle(fontSize: 14, color: Colors.white,fontFamily: Poppins))),
                                onPressed:(resendAttempts >= 4) ? null : () {
                                  validateEmail();
                                  validatePassword();
                                  checkUsername();
                                    if(checked == true) {
                                      if(emailError == null && passwordError == null && passwordError1 == null && userNameError == null) {
                                        signUp();
                                      }
                                    } else {
                                      setState(() {
                                        textError = "Please complete the puzzle to verify you're\nhuman.";
                                      });
                                    }
                                },
                                child: const Text('Sign up',style: TextStyle(
                                    fontSize: 19,
                                    color: ascent,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: Poppins
                                ),)),
                          ),
                        ),
                      ],
                    )
                ),
                if(isCaptcha == false) const SizedBox(height: 5,),
                if(isCaptcha == false) WidgetAnimator(
                    GestureDetector(
                      onTap: (){
                        Navigator.pushReplacement(context,MaterialPageRoute(builder: (context) => const Login()));
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Already have an account?",style: TextStyle(color: Colors.black54,fontFamily: Poppins),),
                          Text(" Log in",style: TextStyle(color: Colors.black54,fontWeight: FontWeight.bold,fontFamily: Poppins),)
                        ],
                      ),
                    )
                ),
                if(isCaptcha == false) const SizedBox(height: 20,),
              ],
            ),
          ),
        ),
      ),
    );
  }
  _launchURL() async {
    final Uri url = Uri.parse('https://fashiontime.app/terms-of-services');
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  _launchPolicy() async {
    final Uri url = Uri.parse('https://fashiontime.app/privacy-policy');
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }
  _launchEula() async {
    final Uri url = Uri.parse('https://fashiontime.app/end-user-license-agreement');
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }
  _launchChild() async {
    final Uri url = Uri.parse('https://fashiontime.app/child-sexual-abuse-and-exploitation-policy');
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }
   Future<void> sendEmail(userUsername,userEmail,code) async {
    print("My Username ==> ${userUsername}");
    print("My Email ==> ${userEmail}");
    final url = Uri.parse('https://api.mailgun.net/v3/fashiontime.app/messages');

    // Basic Authentication credentials
    final username1 = 'api';
    final password2 = '***REMOVED***';
    final credentials = base64Encode(utf8.encode('$username1:$password2'));

    String resetLink = "https://fashiontime.app/account-verified/${userEmail}/${code}/${DateTime.now}";

    // HTML content with replaced placeholders
    // HTML content with styled clickable link
    final htmlContent = '''
<html>
    <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
         <p>Hi <b>${userUsername}</b> 👋,</p>
          
         <p>Welcome to <b>FashionTime</b>. We're excited to have you on board!</p>
          
         <p>To verify your account, simply click the link below:</p>
          
        <div style="margin: 20px 0;">
          <a href="$resetLink" 
               style="display: inline-block;
                      padding: 5px 20px;
                      background-color: #9ad9e9;
                      color: white;
                      font-weight: bold;
                      text-decoration: none;
                      border-radius: 4px;
                      cursor: pointer;
                      text-align: center;">
             👉 Verify my account
          </a>
        </div>
          
        <p>This link is valid for <b>15 minutes</b>, so don't wait too long!</p>
          
        <p>If you didn't request this, no worries, you can safely ignore this email.</p>
          
        <p>Stay stylish,<br>
        <b>The FashionTime Team 👗🧥<b/></p>
    </body>
</html>
      ''';
    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'from': 'noreply@fashiontime.app',
          'to': '${userEmail}',
          'subject': 'Verify your FashionTime account ✨',
          'html': htmlContent,
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          loading = false;
        });
        print('Email sent successfully');
        name.clear();
        email.clear();
        username.clear();
        password.clear();
        password1.clear();
        setState(() {
          checked = false;
          isCaptcha = false;
        });
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: primary,
            title: const Text("Check your inbox!",style: TextStyle(color: ascent,fontFamily: Poppins,fontWeight: FontWeight.bold),),
            content: const Text("We’ve sent you a verification link to finish setting up your account.",style: TextStyle(color: ascent,fontFamily: Poppins),),
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
