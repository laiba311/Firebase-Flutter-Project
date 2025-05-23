import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:finalfashiontimefrontend/animations/bottom_animation.dart';
import 'package:finalfashiontimefrontend/screens/authentication/email.dart';
import 'package:finalfashiontimefrontend/screens/authentication/register_screen.dart';
import 'package:finalfashiontimefrontend/screens/home_screen.dart';
import 'package:finalfashiontimefrontend/utils/constants.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as https;
import 'package:shared_preferences/shared_preferences.dart';

import '../../customize_pacages/capcha/client_verify/slider_captcha.dart';


class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();
  bool loading = false;
  bool eye = true;
  bool isEmailIncorrect=false;
  bool isPasswordIncorrect=false;
  bool checked = false;
  bool isCaptcha = false;
  String? emailError;
  String? passwordError;
  String ipAddress = "";
  String deviceName = "";
  String deviceAddress = "";

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


  Future<void> sendEmail(userUsername,userEmail,code) async {
    print("My Username ==> ${userUsername}");
    print("My Email ==> ${userEmail}");
    print("My Code ==> ${code}");
    final url = Uri.parse('https://api.mailgun.net/v3/fashiontime.app/messages');

    // Basic Authentication credentials
    final username = 'api';
    final password = '***REMOVED***';
    final credentials = base64Encode(utf8.encode('$username:$password'));

    String resetLink = "https://fashiontime.app/reset-password/${userUsername}/${userEmail}/${code}/${DateTime.now()}";

    // HTML content with replaced placeholders
    // HTML content with styled clickable link
    final htmlContent = '''
  <html>
    <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
      <p>Hi <b>$userUsername</b> 👋,</p>

      <p><b>We noticed a new login to your FashionTime</b> account from a device or location we haven’t seen before:</p>

      <ul style="list-style-type: none; padding-left: 0;">
        <li>💻 Device:<b> $deviceName</b></li>
        <li>📍 Location:<b> $deviceAddress</b></li>
        <li>🕒 Date & Time:<b> ${DateTime.now()}</b></li>
        <li>🌐 IP Address:<b> $ipAddress</b></li>
      </ul>

      <p>If this was you, you’re all set and no further action is needed.<br>
      But if you don’t recognize this login, we strongly recommend changing your password immediately to secure your account.</p>

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

      <p>You can always review your login activity in your account settings.</p>

      <p>Stay secure and stylish,<br>
      <b>The FashionTime Team ✨</b></p>
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
          'subject': 'FashionTime spotted a new login 👀, was this you?',
          'html': htmlContent,
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          loading = false;
        });
        print('Email sent successfully');
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


  Login() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    setState(() {
      loading = true;
    });
    try {
      if(email.text == "") {
        setState(() {
          loading = false;
        });
        emailError = "Oops! You forgot your username or email.";
      }
      else if(password.text == ""){
        setState(() {
          loading = false;
        });
        passwordError = "Oops! You forgot your password.";
      }
      else {
        setState(() {
          loading = true;
        });
        FirebaseMessaging.instance.getToken().then((value1) {
          Map<String, String> body = {
            "username_or_email": email.text.toLowerCase(),
            "password": password.text,
          };
          https.post(
            Uri.parse("$serverUrl/api/login/"),
            body: body,
          ).then((value) {
            print("Response ==> ${value.body}");
            if (json.decode(value.body)["detail"] == "No account found with this email or username.") {
              isEmailIncorrect=true;
              emailError = "We couldn't find an account with that\nusername or email address.";
              setState(() {
                loading=false;
                debugPrint("==========>wrong credentials");
              });
            }
            else if(json.decode(value.body)["detail"] == "Incorrect password."){
              isPasswordIncorrect = true;
              passwordError = "Oops! Your password is incorrect.";
              setState(() {
                loading = false;
                print("email of user $isPasswordIncorrect");
              });
            }
            else {
              var postUri = Uri.parse("$serverUrl/user/api/profile/");
              var request = https.MultipartRequest("PATCH", postUri);
              request.fields['fcmToken'] = value1.toString();
              Map<String, String> headers = {
                "Accept": "application/json",
                "Authorization": "Bearer ${json.decode(value.body)["access"]}",
                "Content-Type": "multipart/form-data"
              };
              request.headers.addAll(headers);
              request.send().then((value5){
                print("ip => ${json.decode(value.body)["user"]["ipaddress"]}");
                print("device => ${json.decode(value.body)["user"]["device"]}");
                print("location => ${json.decode(value.body)["user"]["location"]}");
                String tempIp = json.decode(value.body)["user"]["ipaddress"];
                String tempDevice = json.decode(value.body)["user"]["device"];
                String tempLocation = json.decode(value.body)["user"]["location"];
                String tempUsername = json.decode(value.body)["user"]["username"];
                String tempEmail = json.decode(value.body)["user"]["email"];
                if(tempIp != ipAddress && tempDevice != deviceName && tempLocation != deviceAddress){
                  print("email send");
                  String url2 ='$serverUrl/password/reset/';
                  https.post(Uri.parse(url2),body: {
                    'email': tempEmail,
                    'send_email': "false"
                  }).then((myVal){
                    String code = jsonDecode(myVal.body)["code"].split(":")[1];
                    sendEmail(tempUsername, tempEmail, code);
                  });
                }
                print(value5.toString());
                preferences.setString("id", json.decode(value.body)["user"]["id"].toString());
                preferences.setString("name", json.decode(value.body)["user"]["name"].toString());
                preferences.setString("username", json.decode(value.body)["user"]["username"].toString());
                preferences.setString("email", json.decode(value.body)["user"]["email"].toString());
                preferences.setString("pic", json.decode(value.body)["user"]["pic"] == null ? "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/profilepic.png?alt=media&token=a2830e22-3dec-4901-a2cb-ae5089d6966f" :
                json.decode(value.body)["user"]["pic"].toString().replaceAll("https://fashion-time-backend-e7faf6462502.herokuapp.com/https%3A/", "https://")
                );
                preferences.setString("phone", json.decode(value.body)["user"]["phone_number"].toString());
                preferences.setString("gender",json.decode(value.body)["user"]["gender"].toString());
                preferences.setString("token", json.decode(value.body)["access"].toString());
                preferences.setString("password", password.text);
                preferences.setString("fcm_token", value1.toString());
                SchedulerBinding.instance.addPostFrameCallback((_) {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
                });
                setState(() {
                  loading = false;
                });
              }).catchError((error){
                isEmailIncorrect=true;
                print(error);
              });
            }
            setState(() {
              loading = false;
            });
          }).catchError((error) {
            isEmailIncorrect=true;
            setState(() {
              loading = false;
            });
          });
        });
      }
    } catch(e){
      isEmailIncorrect=true;
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        print('The user tries to pop()');
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: primary,
            title: const Text("FashionTime",style: TextStyle(color: ascent,fontFamily: Poppins,fontWeight: FontWeight.bold),),
            content: const Text("Time for a fashion break?",style: TextStyle(color: ascent,fontFamily: Poppins),),
            actions: [
              TextButton(
                child: const Text("Take a break",style: TextStyle(color: ascent,fontFamily: Poppins)),
                onPressed:  () {
                  SystemNavigator.pop();
                },
              ),
              TextButton(
                child: const Text("Keep styling",style: TextStyle(color: ascent,fontFamily: Poppins)),
                onPressed:  () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
        return false;
      },
      child: Container(
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
                  SizedBox(height: MediaQuery.of(context).size.height * 0.1,),
                  const SizedBox(height: 30,),
                  WidgetAnimator(
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                            child: Image.asset("assets/logo.png",
                              height: MediaQuery.of(context).size.height * 0.22,

                            )
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25,),
                  WidgetAnimator(
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.7,
                      child: TextField(
                        inputFormatters: [
                          FilteringTextInputFormatter.deny(
                            RegExp(r'\s'), // Deny whitespace
                          ),
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[a-zA-Z0-9@._-]'), // Allow specified characters
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            isEmailIncorrect=false;
                            emailError = null;
                          });
                        },
                        onTap: () {
                          setState(() {
                            isEmailIncorrect=false;
                            emailError = null;
                          });
                        },
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
                            //errorText: isEmailIncorrect ? "We couldn't find an account with that\nusername or email address.": null,
                            errorText: emailError,
                            errorStyle: TextStyle(color: Colors.red,fontWeight: FontWeight.bold,fontFamily: Poppins,fontSize: 10),
                            //disabledBorder: InputBorder.none,
                            alignLabelWithHint: true,
                            hintText: "Username or Email"
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
                            isPasswordIncorrect=false;
                            passwordError = null;
                          });
                        },
                        inputFormatters: [
                          FilteringTextInputFormatter.deny(
                              RegExp(r'\s')),
                        ],
                        onTap: () {
                          setState(() {
                            isPasswordIncorrect=false;
                            passwordError = null;
                          });
                        },
                        controller: password,
                        obscureText: eye,
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
                            suffixIcon: IconButton(
                              icon: Icon(eye == true ?Icons.visibility:Icons.visibility_off,color: Colors.black54,),
                              onPressed: (){
                                setState(() {
                                  eye = !eye;
                                });
                              },
                            ),
                            enabledBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.black54),
                            ),
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.pink),
                            ),
                            //enabledBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            // errorText: isPasswordIncorrect ? "Invalid Password." : null,
                            errorText: passwordError,
                            errorStyle: TextStyle(color: Colors.red,fontWeight: FontWeight.bold,fontFamily: Poppins,fontSize: 10),
                            //disabledBorder: InputBorder.none,
                            alignLabelWithHint: true,
                            hintText: "Password"
                        ),
                        cursorColor: Colors.pink,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20,),
                  WidgetAnimator(
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          loading == true ? const SpinKitCircle(color: ascent,size: 70,) : Container(
                            height: 45,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15.0),
                                gradient: LinearGradient(
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
                                        left:MediaQuery.of(context).size.width * 0.24,right: MediaQuery.of(context).size.width * 0.24)),
                                    textStyle: MaterialStateProperty.all(
                                        const TextStyle(fontSize: 14, color: Colors.white,fontFamily: Poppins))),
                                onPressed: () {
                                    Login();
                                },
                                child: const Text('Log in',style: TextStyle(
                                    fontSize: 19,
                                    color: ascent,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: Poppins
                                ),)),
                          ),
                        ],
                      )
                  ),
                  const SizedBox(height: 10,),
                  WidgetAnimator(
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Container(
                              height: 45,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15.0),
                                  gradient: LinearGradient(
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
                                  onPressed: () {
                                    Navigator.push(context,MaterialPageRoute(builder: (context) => const Register()));
                                  },
                                  child: const Text('Sign up',style: TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.w700,
                                      color: ascent,
                                      fontFamily: Poppins
                                  ),)),
                            ),
                          ),
                        ],
                      )
                  ),
                  const SizedBox(height: 13,),
                  WidgetAnimator(
                      GestureDetector(
                        onTap: (){
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const EmailScreen()));
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Forgot your password?",style: TextStyle(
                                color: Colors.black54,
                                fontFamily: Poppins
                            ),)
                          ],
                        ),
                      )
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
