import 'dart:convert';
import 'package:http/http.dart' as https;
import 'package:finalfashiontimefrontend/animations/bottom_animation.dart';
import 'package:finalfashiontimefrontend/screens/authentication/login_screen.dart';
import 'package:finalfashiontimefrontend/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChangePassword extends StatefulWidget {
  final String code;
  const ChangePassword({Key? key, required this.code}) : super(key: key);

  @override
  State<ChangePassword> createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<ChangePassword> {
  bool loading = false;
  TextEditingController password1 = TextEditingController();
  TextEditingController password2 = TextEditingController();
  TextEditingController password3 = TextEditingController();
  bool eye1 = true;
  bool eye2 = true;
  bool eye3 = true;
  String id = "";
  String token = "";
  String? passwordError;
  String? passwordError1;
  String? passwordError2;
  String? myPassword;
  String? username;
  String? email;

  getCashedData() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    id = preferences.getString("id")!;
    token = preferences.getString("token")!;
    myPassword = preferences.getString("password")!;
    username = preferences.getString("username")!;
    email = preferences.getString("email")!;
    print("date => ${DateTime.now()}");
    debugPrint(myPassword);
  }

  forgetPassword() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    setState(() {
      loading = true;
    });
    try {
      if(password3.text == "") {
        setState(() {
          loading = false;
        });
        passwordError = "Oops! You forgot your password.";
      }
      else if(password1.text == "") {
        setState(() {
          loading = false;
        });
        passwordError1 = "Oops! You forgot your password.";
      }
      else if(password2.text == "") {
        setState(() {
          loading = false;
        });
        passwordError2 = "Oops! You forgot your password.";
      }
      else if(password3.text.length < 7 && password1.text.length < 7 && password2.text.length < 7){
        setState(() {
          loading = false;
        });
        passwordError = "The password must contain at least 7 characters, one upper case character, and at least one symbol or number.";
        passwordError1 = "The password must contain at least 7 characters, one upper case character, and at least one symbol or number.";
        passwordError2 = "The password must contain at least 7 characters, one upper case character, and at least one symbol or number.";
      }
      // else if(password3.text.length < 7 && password1.text.length < 7){
      //   setState(() {
      //     loading = false;
      //   });
      //   passwordError = "The password must contain at least 7 characters, one upper case character, and at least one symbol or number.";
      //   passwordError1 = "The password must contain at least 7 characters, one upper case character, and at least one symbol or number.";
      // }
      // else if(password3.text.length < 7 && password2.text.length < 7){
      //   setState(() {
      //     loading = false;
      //   });
      //   passwordError = "The password must contain at least 7 characters, one upper case character, and at least one symbol or number.";
      //   passwordError2 = "The password must contain at least 7 characters, one upper case character, and at least one symbol or number.";
      // }
      // else if(password1.text.length < 7 && password2.text.length < 7){
      //   setState(() {
      //     loading = false;
      //   });
      //   passwordError1 = "The password must contain at least 7 characters, one upper case character, and at least one symbol or number.";
      //   passwordError2 = "The password must contain at least 7 characters, one upper case character, and at least one symbol or number.";
      // }
      else if(password1.text.length < 7){
        setState(() {
          loading = false;
        });
        passwordError1 = "The password must contain at least 7 characters, one upper case character, and at least one symbol or number.";
      }
      else if(password3.text.length < 7){
        setState(() {
          loading = false;
        });
        passwordError2 = "The password must contain at least 7 characters, one upper case character, and at least one symbol or number.";
      }
      else if(password3.text.length < 7){
        setState(() {
          loading = false;
        });
        passwordError = "The password must contain at least 7 characters, one upper case character, and at least one symbol or number.";
      }
      else if(password3.text != myPassword) {
        setState(() {
          loading = false;
        });
        passwordError = "Oops! Your current password is incorrect.";
      }
      else if(password1.text !=  password2.text){
        setState(() {
          loading = false;
        });
        passwordError2 = "Oops! Those passwords aren’t twins.";
      }
      else if(password1.text == myPassword){
        setState(() {
          loading = false;
        });
        passwordError1 = "Let’s try a new password.";
      }
      else {
        setState(() {
          loading = true;
        });
        Map<String, String> body = {
          "old_password": password3.text,
          "new_password": password1.text,
          "confirm_password": password2.text
        };
        post(
          Uri.parse("$serverUrl/change-password/"),
          headers: {
            "Authorization": "Bearer $token"},
          body: body,
        ).then((value) {
          if(value.statusCode==200){
            debugPrint("Response ==> ${value.body}");
            // setState(() {
            //   loading = false;
            // });
            myPassword = password1.text;
            preferences.setString("password", password1.text);
            sendEmail(username,email,widget.code);
          }
          else{
            debugPrint("error in changing password==========>${value.body}");
            setState(() {
              loading=false;
            });
          }

        }).catchError((error){
          setState(() {
            loading = false;
          });
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: primary,
              title: const Text("FashionTime",style: TextStyle(color: ascent,fontFamily: Poppins,fontWeight: FontWeight.bold),),
              content: Text(error.toString(),style: const TextStyle(color: ascent,fontFamily: Poppins),),
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
        });
      }
    } catch(e){
      setState(() {
        loading = false;
      });
      debugPrint(e.toString());
    }
  }

  resetPassword(myEmail) async {
    String url='$serverUrl/password/reset/';
    final response = await https.post(Uri.parse(url),body: {
      'email':myEmail,
      'send_email': "false"
    });
    print("${response.body}");
    password1.clear();
    password2.clear();
    password3.clear();
    setState(() {
      loading = false;
    });
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: primary,
        title: const Text("Password updated!",style: TextStyle(color: ascent,fontFamily: Poppins,fontWeight: FontWeight.bold,fontSize: 20),),
        content: const Text("Your password’s been changed. Fresh, secure, and ready! You’ve been logged out on other devices to keep things safe. Time to keep being stylish 💖.",style: TextStyle(color: ascent,fontFamily: Poppins),),
        actions: [
          GestureDetector(
              onTap:(){
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: Text("Okay",style: TextStyle(color: ascent,fontFamily: Poppins))
          ),
        ],
      ),
    );
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

      <p>Just a quick heads-up: <b>your FashionTime password was successfully changed</b>.<br>
      If this was you, you’re all set and no further action is needed.</p>

      <p><b>If you didn’t make this change, please reset your password immediately to secure your account</b>.</p>

      <p>🔐 This link is valid for <b>15 minutes</b>.</p>

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

      <p>Need a new link? Just head back to the login screen and tap 
      “Forgot your password?” to request a fresh one.</p>

      <p>You can always check your login activity under Settings > Security.</p>

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
          'subject': 'Your FashionTime password has been updated 🛡️',
          'html': htmlContent,
        },
      );

      if (response.statusCode == 200) {
        resetPassword(userEmail);
        print("Email Send");
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

  @override
  void initState() {
    // TODO: implement initState
    getCashedData();
    super.initState();
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
                SizedBox(height: MediaQuery.of(context).size.height * 0.1,),
                const SizedBox(height: 30,),
                WidgetAnimator(
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset("assets/logo.png",height: 150,),
                    ],
                  ),
                ),
                const SizedBox(height: 50,),
                Container(
                  width: MediaQuery.of(context).size.width * 0.85,
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20))
                    ),
                    color: ascent,
                    child: Column(
                      children: [
                        const SizedBox(height: 25,),
                        WidgetAnimator(
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text("Change Password",
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                      fontFamily: Poppins
                                  ),
                                )
                              ],
                            )
                        ),
                        const SizedBox(height: 20,),
                        WidgetAnimator(
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.7,
                            child: TextField(
                              onChanged: (e){
                                setState(() {
                                  passwordError = null;
                                });
                              },
                              inputFormatters: [
                                FilteringTextInputFormatter.deny(
                                    RegExp(r'\s')),
                              ],
                              controller: password3,
                              style: const TextStyle(
                                  color: Colors.pink,
                                  fontFamily: Poppins
                              ),
                              decoration: InputDecoration(
                                suffixIcon: IconButton(
                                  icon: Icon(eye3 == true ?Icons.visibility:Icons.visibility_off,color: Colors.black54,),
                                  onPressed: (){
                                    setState(() {
                                      eye3 = !eye3;
                                    });
                                  },
                                ),
                                hintStyle: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 16,
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
                                hintText: "Current Password",
                              ),
                              cursorColor: Colors.pink,
                              obscureText: eye3,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10,),
                        WidgetAnimator(
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.7,
                            child: TextField(
                              onChanged: (e){
                                setState(() {
                                  passwordError1 = null;
                                });
                              },
                              inputFormatters: [
                                FilteringTextInputFormatter.deny(
                                    RegExp(r'\s')),
                              ],
                              controller: password1,
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
                                    fontSize: 16,
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
                                errorMaxLines: 3,
                                errorStyle: TextStyle(color: Colors.red,fontWeight: FontWeight.bold,fontFamily: Poppins,fontSize: 10),
                                //disabledBorder: InputBorder.none,
                                alignLabelWithHint: true,
                                hintText: "New Password",
                              ),
                              cursorColor: Colors.pink,
                              obscureText: eye1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10,),
                        WidgetAnimator(
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.7,
                            child: TextField(
                              onChanged: (e){
                                setState(() {
                                  passwordError2 = null;
                                });
                              },
                              inputFormatters: [
                                FilteringTextInputFormatter.deny(
                                    RegExp(r'\s')),
                              ],
                              controller: password2,
                              style: const TextStyle(
                                  color: Colors.pink,
                                  fontFamily: Poppins
                              ),
                              decoration: InputDecoration(
                                  suffixIcon: IconButton(
                                    icon: Icon(eye2 == true ?Icons.visibility:Icons.visibility_off,color: Colors.black54,),
                                    onPressed: (){
                                      setState(() {
                                        eye2 = !eye2;
                                      });
                                    },
                                  ),
                                  hintStyle: const TextStyle(
                                      color: Colors.black54,
                                      fontSize: 16,
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
                                  errorText: passwordError2,
                                  errorMaxLines: 3,
                                  errorStyle: TextStyle(color: Colors.red,fontWeight: FontWeight.bold,fontFamily: Poppins,fontSize: 10),
                                  //disabledBorder: InputBorder.none,
                                  alignLabelWithHint: true,
                                  hintText: "Confirm New Password"
                              ),
                              cursorColor: Colors.pink,
                              obscureText: eye2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10,),
                        WidgetAnimator(
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.72,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  loading == true ? SpinKitCircle(color: primary,size: 70,) : Container(
                                    height: 40,
                                    width: MediaQuery.of(context).size.width * 0.708,
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(7.0),
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
                                                top: 8,bottom: 8,
                                                left:MediaQuery.of(context).size.width * 0.1,right: MediaQuery.of(context).size.width * 0.1)),
                                            textStyle: MaterialStateProperty.all(
                                                const TextStyle(fontSize: 14, color: Colors.white,fontFamily: Poppins))),
                                        onPressed: () {
                                          forgetPassword();
                                        },
                                        child: const Text('Change my password',style: TextStyle(
                                            fontSize: 14,
                                            color: ascent,
                                            fontWeight: FontWeight.w700,
                                            fontFamily: Poppins
                                        ),)),
                                  ),
                                ],
                              ),
                            )
                        ),
                        const SizedBox(height: 20,),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
